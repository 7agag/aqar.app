import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/extensions/num_formatting.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../property/presentation/widgets/property_image.dart';
import '../bloc/lease_bloc.dart';
import '../bloc/lease_event.dart';
import '../bloc/lease_state.dart';

const _months = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December',
];

class LeaseDetailPage extends StatefulWidget {
  final String leaseId;
  const LeaseDetailPage({super.key, required this.leaseId});

  @override
  State<LeaseDetailPage> createState() => _LeaseDetailPageState();
}

class _LeaseDetailPageState extends State<LeaseDetailPage> {
  @override
  void initState() {
    super.initState();
    context
        .read<LeaseBloc>()
        .add(GetLeaseDetailRequested(leaseId: widget.leaseId));
  }

  String _formatDate(DateTime dt) {
    return '${_months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Lease Details',
            style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 18)),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: true,
      ),
      body: BlocBuilder<LeaseBloc, LeaseState>(
        builder: (context, state) {
          if (state is LeaseLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is LeaseError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline_rounded,
                        size: 48, color: AppColors.error),
                    const SizedBox(height: 16),
                    Text(state.message, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    TextButton.icon(
                      onPressed: () {
                        context.read<LeaseBloc>().add(
                            GetLeaseDetailRequested(
                                leaseId: widget.leaseId));
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }
          if (state is LeaseDetailLoaded) {
            final lease = state.lease;
            final statusColor = switch (lease.status) {
              'UPCOMING' => const Color(0xFF3B82F6),
              'IN_PROGRESS' => AppColors.success,
              'COMPLETED' => AppColors.textHint,
              'CANCELLED' => AppColors.error,
              'OVERDUE' => AppColors.error,
              _ => AppColors.textHint,
            };
            final statusLabel = switch (lease.status) {
              'UPCOMING' => 'Upcoming',
              'IN_PROGRESS' => 'In Progress',
              'COMPLETED' => 'Completed',
              'CANCELLED' => 'Cancelled',
              'OVERDUE' => 'Overdue',
              _ => lease.status,
            };
            return RefreshIndicator(
              onRefresh: () async {
                context.read<LeaseBloc>().add(GetLeaseDetailRequested(leaseId: widget.leaseId));
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (lease.propertyName != null)
                          Expanded(
                            child: Text(lease.propertyName!,
                                style: const TextStyle(
                                    fontSize: 22, fontWeight: FontWeight.bold)),
                          ),
                        const SizedBox(width: 8),
                        _buildStatusBadge(statusColor, statusLabel),
                      ],
                    ),
                    if (lease.images != null && lease.images!.trim().isNotEmpty) ...[
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 200,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: lease.images!.split(',').length,
                          separatorBuilder: (_, __) => const SizedBox(width: 12),
                          itemBuilder: (_, i) => ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: PropertyImage(
                              imageUrl: lease.images!.split(',')[i].trim(),
                              width: MediaQuery.of(context).size.width * 0.75,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
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
                          _buildInfoRow('Renting Type', lease.rentingType),
                          if (lease.renterName != null)
                            _buildInfoRow('Renter', lease.renterName!),
                          _buildInfoRow('Check-in', _formatDate(lease.checkInDate)),
                          _buildInfoRow('Check-out', _formatDate(lease.checkOutDate)),
                          if (lease.nextBillingDate != null)
                            _buildInfoRow('Next Billing', _formatDate(lease.nextBillingDate!)),
                          if (lease.priceValue != null)
                            _buildInfoRow('Price',
                                '${lease.priceValue!.formatWithCommas()} EGP'),

                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildStatusBadge(Color color, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label,
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textHint)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    fontSize: 14, color: AppColors.textPrimary)),
          ),
        ],
      ),
    );
  }
}
