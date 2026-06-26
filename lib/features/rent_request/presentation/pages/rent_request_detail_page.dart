import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:aqar/core/services/biometric_auth_guard.dart';
import 'package:aqar/core/services/escrow_service.dart';
import 'package:aqar/core/theme/app_colors.dart';
import 'package:aqar/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:aqar/features/auth/presentation/bloc/auth_state.dart';
import 'package:aqar/features/payment/domain/usecases/get_payment_link_usecase.dart';
import 'package:aqar/features/payment/presentation/pages/payment_gateway_page.dart';
import 'package:aqar/features/rent_request/domain/entities/rent_request_entity.dart';
import 'package:aqar/features/rent_request/domain/entities/rent_request_enums.dart' as enums;
import 'package:aqar/features/rent_request/presentation/bloc/rent_request_bloc.dart';
import 'package:aqar/features/rent_request/presentation/bloc/rent_request_event.dart';
import 'package:aqar/features/rent_request/presentation/bloc/rent_request_state.dart';
import 'package:aqar/injection_container.dart' as di;

class RentRequestDetailPage extends StatefulWidget {
  final String requestId;
  final bool isSent;

  const RentRequestDetailPage({
    super.key,
    required this.requestId,
    required this.isSent,
  });

  @override
  State<RentRequestDetailPage> createState() => _RentRequestDetailPageState();
}

class _RentRequestDetailPageState extends State<RentRequestDetailPage> {
  RentRequestEntity? _request;
  bool _isFetching = true;

  @override
  void initState() {
    super.initState();
    _loadRequest();
  }

  void _loadRequest() {
    context.read<RentRequestBloc>().add(GetRentRequestById(requestId: widget.requestId));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Request Details'),
      ),
      body: BlocListener<RentRequestBloc, RentRequestState>(
        listener: (context, state) {
          if (state is RentRequestActionSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
            Navigator.pop(context);
          }
          if (state is RentRequestDetailLoaded && mounted) {
            setState(() {
              _request = state.request;
              _isFetching = false;
            });
          }
          if (state is RentRequestError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isFetching) {
      return const Center(child: CircularProgressIndicator());
    }

    final request = _request;
    if (request == null) {
      return const Center(child: Text('Request not found'));
    }

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoRow('Property', request.propertyName ?? 'Property #${request.propertyId}'),
          _buildInfoRow('Type', request.rentingType.label),
          _buildInfoRow('Check In', request.checkInDate.toString().substring(0, 10)),
          _buildInfoRow('Check Out', request.checkOutDate.toString().substring(0, 10)),
          _buildInfoRow('Total Price', '\$${request.totalPrice.toStringAsFixed(0)}'),
          _buildInfoRow('Status', request.state.label),
          _buildInfoRow('Requested', request.createdAt.toString().substring(0, 10)),
          const SizedBox(height: 8),
          _buildTimeline(request.state, di.sl<EscrowService>().getLease(request.requestId)),
          const Spacer(),
          ..._buildActionButtons(context, request),
        ],
      ),
    );
  }

  Widget _buildTimeline(enums.RentRequestState state, LocalLease? lease) {
    if (state == enums.RentRequestState.rejected || state == enums.RentRequestState.cancelled) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cancel_rounded, size: 18, color: AppColors.error),
            const SizedBox(width: 6),
            Text(
              'Request ${state.label}',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.error),
            ),
          ],
        ),
      );
    }

    final steps = [
      _TimelineStep(label: 'Sent', icon: Icons.send_rounded,
        completed: true),
      _TimelineStep(label: 'Accepted', icon: Icons.check_circle_outline,
        completed: state.index >= enums.RentRequestState.accepted.index),
      _TimelineStep(label: 'Paid', icon: Icons.payment_rounded,
        completed: state == enums.RentRequestState.paid ||
                   (lease != null && (lease.status == LeaseStatus.escrowActive || lease.status == LeaseStatus.completed))),
      _TimelineStep(label: 'Done', icon: Icons.home_rounded,
        completed: lease != null && (lease.status == LeaseStatus.tenantConfirmed || lease.status == LeaseStatus.completed)),
    ];

    final activeIdx = steps.lastIndexWhere((s) => s.completed);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: List.generate(steps.length * 2 - 1, (i) {
          if (i.isOdd) {
            final stepIdx = i ~/ 2;
            final isDone = stepIdx < activeIdx;
            return Expanded(
              child: Container(
                height: 2,
                color: isDone ? AppColors.success : AppColors.borderLight,
              ),
            );
          }
          final stepIdx = i ~/ 2;
          final step = steps[stepIdx];
          final isActive = stepIdx == activeIdx;
          final isDone = step.completed;
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 32, height: 32,
                decoration: BoxDecoration(
                  color: isDone ? AppColors.success : isActive ? AppColors.primary : Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isDone ? AppColors.success : isActive ? AppColors.primary : AppColors.borderLight,
                    width: 2,
                  ),
                ),
                child: Icon(
                  step.icon,
                  size: 16,
                  color: isDone || isActive ? Colors.white : AppColors.textHint,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                step.label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                  color: isDone ? AppColors.success : isActive ? AppColors.primary : AppColors.textHint,
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildActionButtons(BuildContext context, RentRequestEntity request) {
    if (widget.isSent) {
      switch (request.state) {
        case enums.RentRequestState.pending:
          return [_buildCancelButton(context, request.requestId)];
        case enums.RentRequestState.accepted:
          return [_buildProceedToPayment(context, request)];
        case enums.RentRequestState.paymentPending:
          return [_buildPaymentPendingInfo()];
        case enums.RentRequestState.paid:
          final lease = di.sl<EscrowService>().getLease(request.requestId);
          if (lease != null && !lease.renterConfirmed && lease.status == LeaseStatus.escrowActive) {
            return [_buildConfirmReceipt(context, request.requestId)];
          }
          return [];
        default:
          return [];
      }
    } else {
      switch (request.state) {
        case enums.RentRequestState.pending:
          return [_buildOwnerActions(context, request.requestId)];
        case enums.RentRequestState.accepted:
        case enums.RentRequestState.paymentPending:
          final lease = di.sl<EscrowService>().getLease(request.requestId);
          if (lease == null || lease.status == LeaseStatus.awaitingPayment) {
            return [_buildOwnerCancelButton(context, request.requestId)];
          }
          if (lease.status == LeaseStatus.escrowActive) {
            return [_buildOwnerCancelWithRefundButton(context, request.requestId)];
          }
          return [];
        case enums.RentRequestState.paid:
          final lease = di.sl<EscrowService>().getLease(request.requestId);
          if (lease != null && lease.status == LeaseStatus.escrowActive) {
            return [_buildOwnerCancelWithRefundButton(context, request.requestId)];
          }
          return [];
        default:
          return [];
      }
    }
  }

  Future<void> _proceedToPayment(RentRequestEntity request) async {
    final guardOk = await BiometricAuthGuard.guard(
      context,
      reason: 'Authenticate to confirm your rental payment',
    );
    if (!guardOk) return;
    if (!mounted) return;
    final getPaymentLink = di.sl<GetPaymentLinkUseCase>();
    final linkResult = await getPaymentLink(
      GetPaymentLinkParams(requestId: request.requestId),
    );

    if (!mounted) return;

    await linkResult.fold(
      (failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(failure.message)),
        );
      },
      (link) async {
        final ok = await PaymentGatewayPage.open(
          context,
          itemName: request.propertyName ?? 'Property #${request.propertyId}',
          amount: request.totalPrice,
          generatePaymentUrl: () async => link.url,
        );

        if (ok == true && mounted) {
          final authState = di.sl<AuthBloc>().state;
          if (authState is AuthProfileLoaded) {
            await di.sl<EscrowService>().createLease(
              requestId: request.requestId,
              propertyId: request.propertyId,
              renterId: authState.user.id,
              ownerId: request.ownerId ?? '',
            );
            if (mounted) {
              context.read<RentRequestBloc>().add(const LoadRentRequests());
            }
          }
        }
      },
    );
  }

  Widget _buildProceedToPayment(BuildContext context, RentRequestEntity request) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: () => _proceedToPayment(request),
        child: const Text('Proceed to Payment'),
      ),
    );
  }

  Widget _buildPaymentPendingInfo() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.hourglass_bottom, size: 18, color: Colors.amber),
          SizedBox(width: 8),
          Text(
            'Payment in progress',
            style: TextStyle(
              color: Colors.amber,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmReceipt(BuildContext context, String requestId) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.success,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: () async {
          final confirmed = await _confirmAction(
            'Confirm Receipt',
            'Have you received the property as agreed? This will release the payment.',
          );
          if (confirmed) {
            await di.sl<EscrowService>().confirmReceipt(requestId);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Receipt confirmed. Payment released.')),
              );
              setState(() {});
            }
          }
        },
        child: const Text('Confirm Receipt'),
      ),
    );
  }

  Widget _buildOwnerCancelButton(BuildContext context, String id) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: () async {
          final bloc = context.read<RentRequestBloc>();
          final confirmed = await _confirmAction(
            'Cancel Request',
            'Are you sure you want to cancel this rent request? This will void the payment.',
          );
          if (confirmed) {
            final lease = di.sl<EscrowService>().getLease(id);
            if (lease != null) {
              await di.sl<EscrowService>().cancelLease(id);
            }
            bloc.add(CancelRentRequest(requestId: id));
          }
        },
        child: const Text('Cancel Request'),
      ),
    );
  }

  Widget _buildOwnerCancelWithRefundButton(BuildContext context, String id) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: () async {
          final bloc = context.read<RentRequestBloc>();
          final confirmed = await _confirmAction(
            'Cancel & Refund',
            'This will cancel the lease and mark the payment for refund. Continue?',
          );
          if (confirmed) {
            await di.sl<EscrowService>().cancelLease(id);
            bloc.add(CancelRentRequest(requestId: id));
          }
        },
        child: const Text('Cancel & Refund'),
      ),
    );
  }

  Future<bool> _confirmAction(String title, String message) async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Confirm', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        ) ??
        false;
  }

  Widget _buildCancelButton(BuildContext context, String id) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: () async {
          final bloc = context.read<RentRequestBloc>();
          final confirmed = await _confirmAction(
            'Cancel Request',
            'Are you sure you want to cancel this rent request?',
          );
          if (confirmed) {
            bloc.add(CancelRentRequest(requestId: id));
          }
        },
        child: const Text('Cancel Request'),
      ),
    );
  }

  Widget _buildOwnerActions(BuildContext context, String id) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () async {
              final bloc = context.read<RentRequestBloc>();
              final confirmed = await _confirmAction(
                'Accept Request',
                'Accept this rent request?',
              );
              if (confirmed) {
                bloc.add(AcceptRentRequest(requestId: id));
              }
            },
            child: const Text('Accept'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () async {
              final bloc = context.read<RentRequestBloc>();
              final confirmed = await _confirmAction(
                'Reject Request',
                'Reject this rent request?',
              );
              if (confirmed) {
                bloc.add(RejectRentRequest(requestId: id));
              }
            },
            child: const Text('Reject'),
          ),
        ),
      ],
    );
  }
}

class _TimelineStep {
  final String label;
  final IconData icon;
  final bool completed;
  const _TimelineStep({
    required this.label,
    required this.icon,
    required this.completed,
  });
}
