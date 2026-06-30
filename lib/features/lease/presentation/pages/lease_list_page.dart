import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/extensions/num_formatting.dart';
import '../../../../core/theme/app_colors.dart';
import 'package:aqar/injection_container.dart' as di;
import '../bloc/lease_bloc.dart';
import '../bloc/lease_event.dart';
import '../bloc/lease_state.dart';
import '../../domain/entities/lease_entity.dart';
import 'lease_detail_page.dart';

const _months = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December',
];

class LeaseListPage extends StatefulWidget {
  const LeaseListPage({super.key});

  @override
  State<LeaseListPage> createState() => _LeaseListPageState();
}

class _LeaseListPageState extends State<LeaseListPage>
    with SingleTickerProviderStateMixin {
  static const _kPad = 16.0;
  static const _kGap = 12.0;
  static const _kRadiusCard = 16.0;

  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    context.read<LeaseBloc>().add(const GetRenterLeasesRequested());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'My Leases',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          onTap: (i) {
            if (i == 0) {
              context.read<LeaseBloc>().add(const GetRenterLeasesRequested());
            } else {
              context.read<LeaseBloc>().add(const GetOwnerLeasesRequested());
            }
          },
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textHint,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: 'As Renter'),
            Tab(text: 'As Owner'),
          ],
        ),
      ),
      body: BlocBuilder<LeaseBloc, LeaseState>(
        builder: (context, state) {
          if (state is LeaseLoading) {
            return _buildShimmer();
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
                        final i = _tabController.index;
                        context.read<LeaseBloc>().add(i == 0
                            ? const GetRenterLeasesRequested()
                            : const GetOwnerLeasesRequested());
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }
          if (state is RenterLeasesLoaded || state is OwnerLeasesLoaded) {
            final isRenter = state is RenterLeasesLoaded;
            final leases = isRenter
                ? state.leases
                : (state is OwnerLeasesLoaded ? state.leases : <LeaseEntity>[]);
            return RefreshIndicator(
              onRefresh: () async {
                final i = _tabController.index;
                context.read<LeaseBloc>().add(i == 0
                    ? const GetRenterLeasesRequested()
                    : const GetOwnerLeasesRequested());
              },
              child: leases.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.25,
                        ),
                        _buildEmptyState(isRenter: isRenter),
                      ],
                    )
                  : ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(_kPad),
                      itemCount: leases.length,
                      itemBuilder: (_, i) => _buildLeaseCard(leases[i]),
                    ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildShimmer() {
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(_kPad),
      itemCount: 4,
      itemBuilder: (_, __) => Container(
        margin: const EdgeInsets.only(bottom: _kGap),
        height: 140,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(_kRadiusCard),
        ),
        child: Padding(
          padding: const EdgeInsets.all(_kPad),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 14,
                width: 160,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                height: 10,
                width: 200,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                height: 10,
                width: 140,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              const Spacer(),
              Row(
                children: [
                  Container(
                    height: 20,
                    width: 60,
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    height: 16,
                    width: 80,
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState({required bool isRenter}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.borderLight),
              ),
              child: const Icon(
                Icons.description_outlined,
                size: 44,
                color: AppColors.textHint,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'No leases yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              isRenter
                  ? "You don't have any active leases.\nBrowse properties and start renting."
                  : "No one is renting your properties yet.\nList your property to generate leases.",
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${_months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  Widget _buildLeaseCard(LeaseEntity lease) {
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

    return Padding(
      padding: const EdgeInsets.only(bottom: _kGap),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(_kRadiusCard),
          border: Border.all(color: AppColors.borderLight),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(_kRadiusCard),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => BlocProvider(
                  create: (_) => di.sl<LeaseBloc>(),
                  child: LeaseDetailPage(leaseId: lease.leaseId),
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(_kPad),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (lease.propertyName != null)
                      Expanded(
                        child: Text(lease.propertyName!,
                            style: const TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w700)),
                      ),
                    const SizedBox(width: 8),
                    _buildStatusBadge(statusColor, statusLabel),
                  ],
                ),
                const SizedBox(height: 8),
                if (lease.renterName != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text('Renter: ${lease.renterName}',
                        style: const TextStyle(
                            fontSize: 13, color: AppColors.textSecondary)),
                  ),
                Text(
                  '${_formatDate(lease.checkInDate)} — ${_formatDate(lease.checkOutDate)}',
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(lease.rentingType,
                          style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary)),
                    ),
                    if (lease.priceValue != null) ...[
                      const SizedBox(width: 8),
                      Text('${lease.priceValue!.formatWithCommas()} EGP',
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary)),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
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
}
