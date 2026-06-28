import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:aqar/core/theme/app_colors.dart';
import 'package:aqar/features/rent_request/presentation/bloc/rent_request_bloc.dart';
import 'package:aqar/features/rent_request/presentation/bloc/rent_request_event.dart';
import 'package:aqar/features/rent_request/presentation/bloc/rent_request_state.dart';
import 'package:aqar/features/rent_request/presentation/pages/rent_request_detail_page.dart';

class MyRequestsPage extends StatefulWidget {
  final int initialTab;
  const MyRequestsPage({super.key, this.initialTab = 0});

  @override
  State<MyRequestsPage> createState() => _MyRequestsPageState();
}

class _MyRequestsPageState extends State<MyRequestsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this, initialIndex: widget.initialTab);
    context.read<RentRequestBloc>().add(const LoadRentRequests());
    _pollTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      context.read<RentRequestBloc>().add(const LoadRentRequests());
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Requests'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          isScrollable: true,
          tabs: const [
            Tab(text: 'Rent Sent'),
            Tab(text: 'Rent Received'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildRentSentTab(),
          _buildRentReceivedTab(),
        ],
      ),
    );
  }

  Widget _buildRentSentTab() {
    return BlocConsumer<RentRequestBloc, RentRequestState>(
      listener: _rentListener,
      builder: (context, state) {
        if (state is RentRequestLoading) return _loader();
        if (state is RentRequestsLoaded) {
          return _buildRentList(state.sent, isSent: true);
        }
        return _buildErrorRetry(() {
          context.read<RentRequestBloc>().add(const LoadRentRequests());
        }, state is RentRequestError ? state.message : null);
      },
    );
  }

  Widget _buildRentReceivedTab() {
    return BlocConsumer<RentRequestBloc, RentRequestState>(
      listener: _rentListener,
      builder: (context, state) {
        if (state is RentRequestLoading) return _loader();
        if (state is RentRequestsLoaded) {
          return _buildRentList(state.received, isSent: false);
        }
        return _buildErrorRetry(() {
          context.read<RentRequestBloc>().add(const LoadRentRequests());
        }, state is RentRequestError ? state.message : null);
      },
    );
  }

  void _rentListener(BuildContext context, RentRequestState state) {
    if (state is RentRequestError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(state.message), backgroundColor: AppColors.error),
      );
    }
    if (state is RentRequestActionSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(state.message), backgroundColor: AppColors.success),
      );
    }
  }

  Widget _loader() {
    return const Center(child: CircularProgressIndicator(color: AppColors.primary));
  }

  Widget _buildErrorRetry(VoidCallback onRetry, String? message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.textHint),
            const SizedBox(height: 16),
            Text(
              message ?? 'Something went wrong',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: const Text('Retry', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRentList(List list, {required bool isSent}) {
    if (list.isEmpty) {
      return _emptyState(
        icon: isSent ? Icons.send_outlined : Icons.inbox_outlined,
        title: isSent ? 'No sent requests' : 'No received requests',
        subtitle: isSent ? 'Browse properties and send a rent request' : 'Requests from renters will appear here',
      );
    }
    return RefreshIndicator(
      onRefresh: () async {
        context.read<RentRequestBloc>().add(const LoadRentRequests());
      },
      color: AppColors.primary,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: list.length,
        itemBuilder: (context, index) {
          final r = list[index];
          return _buildRentCard(r, isSent);
        },
      ),
    );
  }

  Widget _buildRentCard(dynamic r, bool isSent) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => BlocProvider.value(
                value: context.read<RentRequestBloc>(),
                child: RentRequestDetailPage(
                  requestId: r.requestId,
                  isSent: isSent,
                ),
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _rentStatusColor(r.state.label).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.home_work_outlined, size: 22, color: _rentStatusColor(r.state.label)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      r.propertyName ?? 'Property #${r.propertyId}',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.calendar_today, size: 11, color: AppColors.textHint),
                        const SizedBox(width: 4),
                        Text(
                          '${r.checkInDate.toString().substring(0, 10)} — ${r.checkOutDate.toString().substring(0, 10)}',
                          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '\$${r.totalPrice.toStringAsFixed(0)} · ${r.rentingType.label}',
                      style: const TextStyle(fontSize: 12, color: AppColors.textPrimary, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _statusChip(r.state.label, _rentStatusColor(r.state.label)),
            ],
          ),
        ),
      ),
    );
  }

  Color _rentStatusColor(String label) {
    switch (label) {
      case 'Pending': return Colors.orange;
      case 'Accepted': return Colors.green;
      case 'Rejected': return Colors.red;
      case 'Cancelled': return Colors.grey;
      case 'Payment Pending': return Colors.amber;
      case 'Paid': return Colors.teal;
      default: return AppColors.textSecondary;
    }
  }

  Widget _statusChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color),
      ),
    );
  }

  Widget _emptyState({required IconData icon, required String title, required String subtitle}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.borderLight),
              ),
              child: Icon(icon, size: 36, color: AppColors.textHint),
            ),
            const SizedBox(height: 20),
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            const SizedBox(height: 8),
            Text(subtitle, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}
