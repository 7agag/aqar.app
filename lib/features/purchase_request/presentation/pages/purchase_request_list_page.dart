import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:aqar/core/theme/app_colors.dart';
import 'package:aqar/features/purchase_request/presentation/bloc/purchase_request_bloc.dart';
import 'package:aqar/features/purchase_request/presentation/pages/purchase_request_detail_page.dart';

const _months = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December',
];

class PurchaseRequestsPage extends StatefulWidget {
  final int initialTab;
  const PurchaseRequestsPage({super.key, this.initialTab = 0});

  @override
  State<PurchaseRequestsPage> createState() => _PurchaseRequestsPageState();
}

class _PurchaseRequestsPageState extends State<PurchaseRequestsPage>
    with SingleTickerProviderStateMixin {
  static const _kPad = 16.0;
  static const _kGap = 12.0;
  static const _kRadiusCard = 16.0;

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this, initialIndex: widget.initialTab);
    context.read<PurchaseRequestBloc>().add(GetMyRequests());
    context.read<PurchaseRequestBloc>().add(GetReceivedRequests());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime dt) {
    return '${_months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Purchase Requests'),
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
          labelStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          tabs: const [
            Tab(text: 'Sent'),
            Tab(text: 'Received'),
          ],
        ),
      ),
      body: BlocConsumer<PurchaseRequestBloc, PurchaseRequestState>(
        listener: (context, state) {
          if (state is PurchaseRequestError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
          if (state is PurchaseRequestSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
            context.read<PurchaseRequestBloc>().add(GetMyRequests());
            context.read<PurchaseRequestBloc>().add(GetReceivedRequests());
          }
        },
        builder: (context, state) {
          if (state is PurchaseRequestLoading) {
            return _buildShimmer();
          }

          final myRequests = state is MyRequestsLoaded ? state.requests : <dynamic>[];
          final receivedRequests = state is ReceivedRequestsLoaded ? state.requests : <dynamic>[];

          return TabBarView(
            controller: _tabController,
            children: [
              _buildList(myRequests, isSent: true),
              _buildList(receivedRequests, isSent: false),
            ],
          );
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
        height: 90,
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
                width: 120,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildList(List list, {required bool isSent}) {
    if (list.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: Icon(
                  isSent ? Icons.send_outlined : Icons.inbox_outlined,
                  size: 44,
                  color: AppColors.textHint,
                ),
              ),
              SizedBox(height: 20),
              Text(
                isSent ? 'No sent requests' : 'No received requests',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: 10),
              Text(
                isSent ? 'Browse properties and send a purchase request'
                    : 'Purchase requests for your properties will appear here',
                textAlign: TextAlign.center,
                style: TextStyle(
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
    return RefreshIndicator(
      onRefresh: () async {
        context.read<PurchaseRequestBloc>().add(GetMyRequests());
        context.read<PurchaseRequestBloc>().add(GetReceivedRequests());
      },
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(_kPad),
        itemCount: list.length,
        itemBuilder: (context, index) {
          final request = list[index];
          return Padding(
            padding: EdgeInsets.only(bottom: _kGap),
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
                      builder: (_) => BlocProvider.value(
                        value: context.read<PurchaseRequestBloc>(),
                        child: PurchaseRequestDetailPage(
                          requestId: request.requestId,
                          isSent: isSent,
                          contactUnlocked: request.contactUnlocked,
                          buyerName: request.buyerName,
                          buyerEmail: request.buyerEmail,
                        ),
                      ),
                    ),
                  );
                },
                child: Padding(
                  padding: EdgeInsets.all(_kPad),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              request.propertyName ?? 'Property #${request.propertyId}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            SizedBox(height: 6),
                            Text(
                              isSent ? 'To: ${request.ownerName}' : 'From: ${request.buyerName}',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              _formatDate(request.createdAt),
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textHint,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      _buildStatusBadge(request.status),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    final color = _statusColor(status);
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
            status,
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

  Color _statusColor(String status) {
    switch (status) {
      case 'PENDING':
        return Colors.orange;
      case 'ACCEPTED':
        return Colors.green;
      case 'REJECTED':
        return Colors.red;
      case 'CANCELLED':
        return Colors.grey;
      default:
        return AppColors.textSecondary;
    }
  }
}
