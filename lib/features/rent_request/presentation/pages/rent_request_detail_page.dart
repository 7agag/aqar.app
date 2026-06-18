import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:aqar/core/theme/app_colors.dart';
import 'package:aqar/features/rent_request/domain/entities/rent_request_entity.dart';
import 'package:aqar/features/rent_request/domain/entities/rent_request_enums.dart' as enums;
import 'package:aqar/features/rent_request/presentation/bloc/rent_request_bloc.dart';
import 'package:aqar/features/rent_request/presentation/bloc/rent_request_event.dart';
import 'package:aqar/features/rent_request/presentation/bloc/rent_request_state.dart';

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
    setState(() => _isFetching = true);

    final state = context.read<RentRequestBloc>().state;
    if (state is RentRequestsLoaded) {
      final requests = widget.isSent ? state.sent : state.received;
      final found = requests.cast<RentRequestEntity?>().firstWhere(
        (r) => r!.requestId == widget.requestId,
        orElse: () => null,
      );
      if (found != null) {
        _request = found;
        _isFetching = false;
        return;
      }
    }

    context.read<RentRequestBloc>().add(const LoadRentRequests());
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
          if (state is RentRequestError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
          if (state is RentRequestsLoaded) {
            final requests = widget.isSent ? state.sent : state.received;
            final found = requests.cast<RentRequestEntity?>().firstWhere(
              (r) => r!.requestId == widget.requestId,
              orElse: () => null,
            );
            if (found != null && mounted) {
              setState(() {
                _request = found;
                _isFetching = false;
              });
            } else if (mounted) {
              setState(() {
                _request = null;
                _isFetching = false;
              });
            }
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
          const Spacer(),
          if (widget.isSent && request.state == enums.RentRequestState.pending)
            _buildCancelButton(context, request.requestId),
          if (!widget.isSent && request.state == enums.RentRequestState.pending)
            _buildOwnerActions(context, request.requestId),
        ],
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
