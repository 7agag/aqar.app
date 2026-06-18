import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:aqar/core/theme/app_colors.dart';
import 'package:aqar/features/rent_request/presentation/bloc/rent_request_bloc.dart';
import 'package:aqar/features/rent_request/presentation/bloc/rent_request_event.dart';
import 'package:aqar/features/rent_request/presentation/bloc/rent_request_state.dart';
import 'package:aqar/features/rent_request/presentation/pages/rent_request_detail_page.dart';

class RentRequestsPage extends StatefulWidget {
  final int initialTab;
  const RentRequestsPage({super.key, this.initialTab = 0});

  @override
  State<RentRequestsPage> createState() => _RentRequestsPageState();
}

class _RentRequestsPageState extends State<RentRequestsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this, initialIndex: widget.initialTab);
    context.read<RentRequestBloc>().add(const LoadRentRequests());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Requests'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: 'Sent'),
            Tab(text: 'Received'),
          ],
        ),
      ),
      body: BlocConsumer<RentRequestBloc, RentRequestState>(
        listener: (context, state) {
          if (state is RentRequestError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
          if (state is RentRequestActionSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        builder: (context, state) {
          if (state is RentRequestLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is RentRequestsLoaded) {
            return TabBarView(
              controller: _tabController,
              children: [
                _buildList(state.sent, isSent: true),
                _buildList(state.received, isSent: false),
              ],
            );
          }
          return _buildErrorRetry(state);
        },
      ),
    );
  }

  Widget _buildErrorRetry(RentRequestState state) {
    final message = state is RentRequestError ? state.message : 'Something went wrong';
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: AppColors.textHint),
          const SizedBox(height: 16),
          Text(message, style: const TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => context.read<RentRequestBloc>().add(const LoadRentRequests()),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildList(List list, {required bool isSent}) {
    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSent ? Icons.send_outlined : Icons.inbox_outlined,
              size: 64,
              color: AppColors.textHint,
            ),
            const SizedBox(height: 16),
            Text(
              isSent ? 'No sent requests' : 'No received requests',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),
            Text(
              isSent ? 'Browse properties and send a rent request' : 'Requests from renters will appear here',
              style: const TextStyle(fontSize: 13, color: AppColors.textHint),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: () async {
        context.read<RentRequestBloc>().add(const LoadRentRequests());
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: list.length,
        itemBuilder: (context, index) {
          final request = list[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.all(12),
              title: Text(
                request.propertyName ?? 'Property #${request.propertyId}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text(
                    '${request.checkInDate.toString().substring(0, 10)} — ${request.checkOutDate.toString().substring(0, 10)}',
                    style: const TextStyle(fontSize: 13),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '\$${request.totalPrice.toStringAsFixed(0)} · ${request.rentingType.label}',
                    style: const TextStyle(fontSize: 13),
                  ),
                ],
              ),
              trailing: _buildStatusChip(request.state.label),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BlocProvider.value(
                      value: context.read<RentRequestBloc>(),
                      child: RentRequestDetailPage(
                        requestId: request.requestId,
                        isSent: isSent,
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _statusColor(label).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: _statusColor(label),
        ),
      ),
    );
  }

  Color _statusColor(String label) {
    switch (label) {
      case 'Pending':
        return Colors.orange;
      case 'Accepted':
        return Colors.green;
      case 'Rejected':
        return Colors.red;
      case 'Cancelled':
        return Colors.grey;
      case 'Payment Pending':
        return Colors.amber;
      case 'Paid':
        return Colors.teal;
      default:
        return AppColors.textSecondary;
    }
  }
}
