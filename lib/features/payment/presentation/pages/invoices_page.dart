import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:aqar/features/property/presentation/pages/all_properties_page.dart';
import 'package:aqar/core/config/app_config.dart';
import 'package:aqar/core/network/api_client.dart';
import 'package:aqar/core/theme/app_colors.dart';
import 'package:aqar/features/invoice/presentation/bloc/invoice_bloc.dart';
import 'package:aqar/features/invoice/presentation/bloc/invoice_event.dart';
import 'package:aqar/features/invoice/presentation/bloc/invoice_state.dart';
import 'package:aqar/features/invoice/domain/entities/invoice_entity.dart';
import 'package:aqar/features/payment/presentation/pages/invoice_payment_status_page.dart';
import 'package:aqar/features/payment/presentation/pages/kashier_web_view_page.dart';
import 'package:aqar/features/payment/presentation/widgets/invoice_summary_cards.dart';
import 'package:aqar/features/subscription/data/services/pending_payment_service.dart';
import 'package:aqar/injection_container.dart' as di;

const _months = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December',
];

Color _statusColor(String status) {
  switch (status) {
    case 'PAID':
      return AppColors.success;
    case 'OVERDUE':
      return AppColors.error;
    case 'UNPAID':
      return Colors.orange;
    default:
      return AppColors.textHint;
  }
}

String _statusLabel(String status) {
  switch (status) {
    case 'PAID':
      return 'Paid';
    case 'OVERDUE':
      return 'Late';
    case 'UNPAID':
      return 'Pending';
    case 'VOID':
      return 'Void';
    default:
      return status;
  }
}

class InvoicesPage extends StatefulWidget {
  const InvoicesPage({super.key});

  @override
  State<InvoicesPage> createState() => _InvoicesPageState();
}

class _InvoicesPageState extends State<InvoicesPage>
    with SingleTickerProviderStateMixin {
  static const _kPad = 16.0;
  static const _kGap = 12.0;
  static const _kRadiusCard = 16.0;

  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    context.read<InvoiceBloc>().add(const GetRenterInvoicesRequested());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime dt) {
    return '${_months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  String _formatAmount(double amount) {
    final abs = amount.abs().round();
    final str = abs.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) buffer.write(',');
      buffer.write(str[i]);
    }
    return '$buffer ج.م';
  }

  Future<void> _payInvoice(InvoiceEntity invoice) async {
    final pendingService = PendingPaymentService();
    await pendingService.savePendingInvoicePayment(invoice.invoiceId);
    if (!mounted) return;

    try {
      final dio = di.sl<ApiClient>().dio;
      final res = await dio.post('/api/payment/', data: {
        'invoice_id': invoice.invoiceId,
        'redirect': AppConfig.invoiceCallbackUrl(invoice.invoiceId),
      });
      final url = res.data['url'] as String?;
      if (url == null || url.isEmpty) {
        throw Exception('Missing payment URL');
      }
      if (!mounted) return;
      await KashierWebViewPage.open(context, url: url);
      if (!mounted) return;
      await pendingService.clearPendingInvoicePayment();
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => InvoicePaymentStatusPage(
            invoiceId: invoice.invoiceId,
          ),
        ),
      );
    } catch (e) {
      await pendingService.clearPendingInvoicePayment();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Payment failed: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _onInvoiceTap(InvoiceEntity invoice) {
    if (invoice.isUnpaid || invoice.isOverdue) {
      _payInvoice(invoice);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${invoice.invoiceId} — ${_statusLabel(invoice.status)}'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Invoices'),
        bottom: TabBar(
          controller: _tabController,
          onTap: (i) {
            context.read<InvoiceBloc>().add(i == 0
                ? const GetRenterInvoicesRequested()
                : const GetOwnerInvoicesRequested());
          },
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          labelStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          tabs: const [
            Tab(text: 'As Renter'),
            Tab(text: 'As Owner'),
          ],
        ),
      ),
      body: BlocBuilder<InvoiceBloc, InvoiceState>(
        builder: (context, state) {
          if (state is InvoiceLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is InvoiceError) {
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
                        context.read<InvoiceBloc>().add(i == 0
                            ? const GetRenterInvoicesRequested()
                            : const GetOwnerInvoicesRequested());
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }
          if (state is RenterInvoicesLoaded || state is OwnerInvoicesLoaded) {
            final invoices = state is RenterInvoicesLoaded
                ? state.invoices
                : (state is OwnerInvoicesLoaded ? state.invoices : <InvoiceEntity>[]);
            final isRenter = state is RenterInvoicesLoaded;
            final stats = state is RenterInvoicesLoaded
                ? (state).stats
                : (state is OwnerInvoicesLoaded ? (state).stats : null);
            final renterStats = stats?.asRenter;
            final ownerStats = stats?.asOwner;
            return RefreshIndicator(
              onRefresh: () async {
                context.read<InvoiceBloc>().add(isRenter
                    ? const GetRenterInvoicesRequested()
                    : const GetOwnerInvoicesRequested());
              },
              child: invoices.isEmpty
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
                      padding: const EdgeInsets.only(top: 12, bottom: 24),
                      itemCount: invoices.length + 1,
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: InvoiceSummaryCards(
                              renterStats: isRenter ? renterStats : null,
                              ownerStats: !isRenter ? ownerStats : null,
                              isRenter: isRenter,
                            ),
                          );
                        }
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: _kPad),
                          child: _buildInvoiceCard(invoices[index - 1]),
                        );
                      },
                    ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildInvoiceCard(InvoiceEntity invoice) {
    final color = _statusColor(invoice.status);
    final label = _statusLabel(invoice.status);
    final canPay = invoice.isUnpaid || invoice.isOverdue;
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
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(_kRadiusCard),
          onTap: canPay ? null : () => _onInvoiceTap(invoice),
          child: Padding(
            padding: EdgeInsets.all(_kPad),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          invoice.propertyName ?? 'Property #${invoice.propertyId ?? ''}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          invoice.invoiceId,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textHint,
                            fontFamily: 'monospace',
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildStatusBadge(color, label),
                ],
              ),
              Divider(height: 20),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Due Date',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textHint,
                            letterSpacing: 0.5,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          _formatDate(invoice.dueDate),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Total',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textHint,
                          letterSpacing: 0.5,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        _formatAmount(invoice.amount),
                        textDirection: TextDirection.rtl,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (canPay) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _payInvoice(invoice),
                    icon: const Icon(Icons.payment_rounded, size: 16),
                    label: const Text('Pay Now'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    ),
    );
  }

  Widget _buildStatusBadge(Color color, String label) {
    return Semantics(
      label: 'Status: $label',
      child: Container(
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
      ),
    );
  }

  Widget _buildEmptyState({required bool isRenter}) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 40),
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
              child: Icon(
                Icons.description_outlined,
                size: 44,
                color: AppColors.textHint,
              ),
            ),
            SizedBox(height: 20),
            Text(
              'No invoices yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 10),
            Text(
              isRenter
                  ? "You don't have any rental invoices.\nBrowse properties and start renting."
                  : "You don't have any owner invoices.\nList your property to generate invoices.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            TextButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => AllPropertiesPage(pageType: PageType.rent)),
              ),
              icon: const Icon(
                Icons.search_rounded,
                size: 18,
                color: AppColors.primary,
              ),
              label: const Text(
                'Browse Properties',
                style: TextStyle(color: AppColors.primary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
