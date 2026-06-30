import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:aqar/core/services/biometric_auth_guard.dart';
import 'package:aqar/core/theme/app_colors.dart';
import 'package:aqar/features/purchase_request/presentation/bloc/purchase_request_bloc.dart';

class PurchaseRequestDetailPage extends StatefulWidget {
  final String requestId;
  final bool isSent;
  final bool contactUnlocked;
  final String? buyerName;
  final String? buyerEmail;

  const PurchaseRequestDetailPage({
    super.key,
    required this.requestId,
    required this.isSent,
    this.contactUnlocked = false,
    this.buyerName,
    this.buyerEmail,
  });

  @override
  State<PurchaseRequestDetailPage> createState() =>
      _PurchaseRequestDetailPageState();
}

class _PurchaseRequestDetailPageState extends State<PurchaseRequestDetailPage> {
  String? _status;
  String? _message;
  String? _propertyName;
  bool? _contactUnlocked;
  DateTime? _createdAt;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRequest();
  }

  void _loadRequest() {
    final state = context.read<PurchaseRequestBloc>().state;
    PurchaseRequestState? foundState;

    if (state is MyRequestsLoaded) {
      final found = state.requests.cast<dynamic>().firstWhere(
        (r) => r.requestId == widget.requestId,
        orElse: () => null,
      );
      if (found != null) {
        _populateFromEntity(found);
        return;
      }
      foundState = state;
    }

    if (state is ReceivedRequestsLoaded) {
      final found = state.requests.cast<dynamic>().firstWhere(
        (r) => r.requestId == widget.requestId,
        orElse: () => null,
      );
      if (found != null) {
        _populateFromEntity(found);
        return;
      }
      foundState = state;
    }

    if (foundState != null && mounted) {
      setState(() => _isLoading = false);
    }
  }

  void _populateFromEntity(dynamic entity) {
    setState(() {
      _status = entity.status;
      _message = entity.message;
      _propertyName = entity.propertyName;
      _contactUnlocked = entity.contactUnlocked;
      _createdAt = entity.createdAt;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Purchase Request'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: true,
      ),
      body: BlocListener<PurchaseRequestBloc, PurchaseRequestState>(
        listener: (context, state) {
          if (state is PurchaseRequestSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
            Navigator.pop(context);
          }
          if (state is PurchaseRequestError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
          if (state is MyRequestsLoaded || state is ReceivedRequestsLoaded) {
            final requests = state is MyRequestsLoaded
                ? state.requests
                : (state as ReceivedRequestsLoaded).requests;
            final found = requests.cast<dynamic>().firstWhere(
              (r) => r.requestId == widget.requestId,
              orElse: () => null,
            );
            if (found != null && mounted) {
              setState(() {
                _populateFromEntity(found);
              });
            }
          }
        },
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_status == null) {
      return const Center(child: Text('Request not found'));
    }

    return RefreshIndicator(
      onRefresh: () async {
        context.read<PurchaseRequestBloc>().add(
          widget.isSent ? GetMyRequests() : GetReceivedRequests(),
        );
        await context.read<PurchaseRequestBloc>().stream.firstWhere(
          (state) => state is MyRequestsLoaded || state is ReceivedRequestsLoaded || state is PurchaseRequestError,
        );
      },
      child: SingleChildScrollView(
        physics: AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderLight),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildInfoRow('Property', _propertyName ?? 'Property'),
                  _buildInfoRow('Status', _status ?? '-'),
                  if (_message != null) _buildInfoRow('Message', _message!),
                  if (_createdAt != null)
                    _buildInfoRow('Created', _createdAt.toString().substring(0, 10)),
                  if (!widget.isSent && _contactUnlocked == true) ...[
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Divider(height: 1),
                    ),
                    _buildInfoRow('Buyer', widget.buyerName ?? '-'),
                    if (widget.buyerEmail != null)
                      _buildInfoRow('Email', widget.buyerEmail!),
                  ],
                ],
              ),
            ),
            if (widget.isSent && _contactUnlocked == true) ...[
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.lock_open_rounded, color: Colors.green, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Contact Unlocked!',
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (_status == 'PENDING') ...[
              if (widget.isSent)
                _buildActionButton(
                  'Cancel Request',
                  Colors.red,
                      () async {
                    final bloc = context.read<PurchaseRequestBloc>();
                    final guardOk = await BiometricAuthGuard.guard(
                      context,
                      reason: 'Authenticate to cancel this purchase request',
                    );
                    if (!guardOk) return;
                    bloc.add(
                      CancelRequest(requestId: widget.requestId),
                    );
                  },
                ),
              if (!widget.isSent)
                Row(
                  children: [
                    Expanded(
                      child: _buildActionButton(
                        'Accept',
                        Colors.green,
                            () => context.read<PurchaseRequestBloc>().add(
                          UpdateRequestStatus(
                            requestId: widget.requestId,
                            status: 'ACCEPTED',
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildActionButton(
                        'Reject',
                        Colors.red,
                            () => context.read<PurchaseRequestBloc>().add(
                          UpdateRequestStatus(
                            requestId: widget.requestId,
                            status: 'REJECTED',
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(String label, Color color, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: () async {
          final confirmed = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: Text(label),
              content: Text('Are you sure you want to $label this request?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Confirm',
                      style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
          );
          if (confirmed == true) {
            onPressed();
          }
        },
        child: Text(label),
      ),
    );
  }
}
