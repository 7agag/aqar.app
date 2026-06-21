import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:aqar/features/property/presentation/pages/all_properties_page.dart';
import 'package:aqar/core/theme/app_colors.dart';
import 'package:aqar/features/invoice/presentation/bloc/invoice_bloc.dart';
import 'package:aqar/features/invoice/presentation/bloc/invoice_event.dart';
import 'package:aqar/features/invoice/presentation/bloc/invoice_state.dart';
import 'package:aqar/features/invoice/domain/entities/invoice_entity.dart';

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

  void _onInvoiceTap(InvoiceEntity invoice) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${invoice.invoiceId} — ${_statusLabel(invoice.status)}'),
        duration: const Duration(seconds: 2),
      ),
    );
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
                      padding: const EdgeInsets.all(_kPad),
                      itemCount: invoices.length,
                      itemBuilder: (context, index) {
                        return _buildInvoiceCard(invoices[index]);
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
          onTap: () => _onInvoiceTap(invoice),
          child: Padding(
            padding: const EdgeInsets.all(_kPad),
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
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            invoice.invoiceId,
                            style: const TextStyle(
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
                const Divider(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Due Date',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textHint,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formatDate(invoice.dueDate),
                            style: const TextStyle(
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
                        const Text(
                          'Total',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textHint,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatAmount(invoice.amount),
                          textDirection: TextDirection.rtl,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
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
              'No invoices yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              isRenter
                  ? "You don't have any rental invoices.\nBrowse properties and start renting."
                  : "You don't have any owner invoices.\nList your property to generate invoices.",
              textAlign: TextAlign.center,
              style: const TextStyle(
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
