import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:aqar/core/theme/app_colors.dart';
import 'package:aqar/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:aqar/features/auth/presentation/bloc/auth_state.dart';
import 'package:aqar/core/widgets/aqar_button.dart';
import 'package:aqar/features/notifications/presentation/pages/notifications_page.dart';
import 'package:aqar/features/payment/presentation/bloc/wallet_bloc.dart';
import 'package:aqar/features/payment/presentation/bloc/wallet_event.dart';
import 'package:aqar/features/payment/presentation/bloc/wallet_state.dart';
import 'package:aqar/features/payment/domain/entities/balance_entity.dart';
import 'package:aqar/features/payment/domain/entities/payment_entity.dart';

enum _TransactionFilter { all, deposits, withdrawals }

class _WithdrawMethod {
  final IconData icon;
  final String title;
  final String subtitle;
  const _WithdrawMethod(this.icon, this.title, this.subtitle);
}

String _txTypeLabel(String? type) {
  switch (type) {
    case 'deposit':
    case 'rent':
    case 'rent_monthly':
      return 'Deposit';
    case 'withdrawal':
      return 'Withdrawal';
    case 'commission':
      return 'Commission';
    case 'refund':
      return 'Refund';
    default:
      return type ?? 'Transaction';
  }
}

Color _txColor(String? type, double value) {
  if (type == 'withdrawal' || type == 'commission' || value < 0) {
    return AppColors.error;
  }
  return AppColors.success;
}

IconData _txIcon(String? type) {
  switch (type) {
    case 'deposit':
    case 'rent':
    case 'rent_monthly':
      return Icons.arrow_downward_rounded;
    case 'withdrawal':
      return Icons.arrow_upward_rounded;
    case 'commission':
      return Icons.trending_down_rounded;
    case 'refund':
      return Icons.replay_rounded;
    default:
      return Icons.swap_horiz_rounded;
  }
}

bool _isDeposit(TransactionEntity t) {
  return t.value >= 0 &&
      t.paymentType != 'withdrawal' &&
      t.paymentType != 'commission';
}

class WalletPage extends StatefulWidget {
  const WalletPage({super.key});

  @override
  State<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends State<WalletPage>
    with SingleTickerProviderStateMixin {
  static const _kPad = 20.0;
  static const _kGap = 16.0;
  static const _kRadiusCard = 16.0;
  static const _kRadiusSheet = 24.0;

  late final AnimationController _skeletonController;

  bool _showBalance = true;
  _TransactionFilter _filter = _TransactionFilter.all;
  int _displayCount = 5;

  static const _withdrawMethods = [
    _WithdrawMethod(
      Icons.account_balance_outlined,
      'Bank Transfer',
      '1-3 business days',
    ),
    _WithdrawMethod(
      Icons.credit_card_outlined,
      'Card',
      'Instant',
    ),
    _WithdrawMethod(
      Icons.phone_android_outlined,
      'Mobile Wallet',
      'Instant',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _skeletonController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    context.read<WalletBloc>().add(const GetWalletDataRequested());
  }

  @override
  void dispose() {
    _skeletonController.dispose();
    super.dispose();
  }

  List<TransactionEntity> _filtered(List<TransactionEntity> txs) {
    return txs.where((t) {
      switch (_filter) {
        case _TransactionFilter.deposits:
          return _isDeposit(t);
        case _TransactionFilter.withdrawals:
          return !_isDeposit(t);
        case _TransactionFilter.all:
          return true;
      }
    }).toList();
  }

  Map<String, List<TransactionEntity>> _sectioned(List<TransactionEntity> txs) {
    final now = DateTime.now();
    final sections = <String, List<TransactionEntity>>{};
    for (final t in txs) {
      final diff = now.difference(t.createdAt);
      String key;
      if (diff.inDays == 0) {
        key = 'Today';
      } else if (diff.inDays == 1) {
        key = 'Yesterday';
      } else if (diff.inDays < 7) {
        key = 'This Week';
      } else if (t.createdAt.month == now.month &&
          t.createdAt.year == now.year) {
        key = 'This Month';
      } else {
        key = 'Earlier';
      }
      sections.putIfAbsent(key, () => []).add(t);
    }
    return sections;
  }

  static const _sectionOrder = [
    'Today',
    'Yesterday',
    'This Week',
    'This Month',
    'Earlier',
  ];

  void _showWithdrawSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(_kRadiusSheet)),
      ),
      builder: (_) => _buildWithdrawSheet(),
    );
  }

  void _showWithdrawFormSheet(String method) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(_kRadiusSheet)),
      ),
      builder: (_) => _WithdrawFormSheet(method: method),
    );
  }

  void _handleHistory() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Full transaction history coming soon'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Wallet',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              final authState = context.read<AuthBloc>().state;
              if (authState is! AuthProfileLoaded) {
                Navigator.pushNamed(context, '/auth');
                return;
              }
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const NotificationsPage()));
            },
            color: AppColors.textSecondary,
          ),
        ],
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: BlocBuilder<WalletBloc, WalletState>(
        builder: (context, state) {
          if (state is WalletLoading && state is! WalletLoaded) {
            return _buildSkeleton();
          }
          if (state is WalletError) {
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
                      onPressed: () => context
                          .read<WalletBloc>()
                          .add(const GetWalletDataRequested()),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }
          if (state is WalletLoaded) {
            return _buildBody(state);
          }
          return _buildSkeleton();
        },
      ),
    );
  }

  Widget _buildSkeleton() {
    return ListView.builder(
      padding: const EdgeInsets.all(_kPad),
      itemCount: 6,
      itemBuilder: (_, i) => AnimatedBuilder(
        animation: _skeletonController,
        builder: (_, __) {
          final o = _skeletonController.value * 0.4 + 0.15;
          return Container(
            height: i == 0 ? 180 : 88,
            margin: const EdgeInsets.only(bottom: _kGap),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(_kRadiusCard),
            ),
            child: i == 0
                ? Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 14,
                          width: 100,
                          decoration: BoxDecoration(
                            color: Colors.grey.withValues(alpha: o),
                            borderRadius: BorderRadius.circular(7),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          height: 36,
                          width: 160,
                          decoration: BoxDecoration(
                            color: Colors.grey.withValues(alpha: o * 0.8),
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        const Spacer(),
                        Container(
                          height: 48,
                          width: 140,
                          decoration: BoxDecoration(
                            color: Colors.grey.withValues(alpha: o * 0.6),
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ),
                      ],
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: Colors.grey.withValues(alpha: o),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                height: 14,
                                width: i.isEven ? 140.0 : 100.0,
                                decoration: BoxDecoration(
                                  color: Colors.grey.withValues(alpha: o),
                                  borderRadius: BorderRadius.circular(7),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                height: 12,
                                width: 80,
                                decoration: BoxDecoration(
                                  color: Colors.grey.withValues(
                                      alpha: o * 0.7),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
          );
        },
      ),
    );
  }

  Widget _buildBody(WalletLoaded state) {
    final allTxs = state.transactions;
    final filteredTxs = _filtered(allTxs);
    final sections = _sectioned(filteredTxs);
    final hasMore = filteredTxs.length > _displayCount;

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () async {
        context.read<WalletBloc>().add(const GetWalletDataRequested());
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBalanceCard(state.balance),
            const SizedBox(height: _kGap),
            _buildQuickActions(),
            const SizedBox(height: 28),
            _buildFilterChips(),
            const SizedBox(height: 16),
            if (filteredTxs.isEmpty)
              _buildEmptyFilterState()
            else
              ..._buildTransactionSections(sections, hasMore),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceCard(BalanceEntity balance) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(_kPad, _kPad, _kPad, 0),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Current Balance',
            style: TextStyle(
              fontSize: 13,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: _showBalance
                    ? TweenAnimationBuilder<double>(
                        key: const ValueKey('visible'),
                        tween: Tween(
                            begin: 0, end: balance.availableBalance),
                        duration: const Duration(milliseconds: 800),
                        curve: Curves.easeOutCubic,
                        builder: (_, value, __) {
                          final formatted = value.round().toString();
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                formatted,
                                style: const TextStyle(
                                  fontSize: 36,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  height: 1.1,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(width: 6),
                              const Padding(
                                padding: EdgeInsets.only(bottom: 4),
                                child: Text(
                                  'ج.م',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      )
                    : Row(
                        key: const ValueKey('hidden'),
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '••••••',
                            style: const TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              height: 1.1,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Padding(
                            padding: EdgeInsets.only(bottom: 4),
                            child: Text(
                              'ج.م',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
              const Spacer(),
              IconButton(
                icon: Icon(
                  _showBalance
                      ? Icons.visibility_rounded
                      : Icons.visibility_off_rounded,
                  color: Colors.white,
                  size: 24,
                ),
                onPressed: () =>
                    setState(() => _showBalance = !_showBalance),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: 180,
            child: AqarButton(
              text: 'Withdraw Funds',
              onPressed: _showWithdrawSheet,
              suffix: const Icon(
                Icons.arrow_upward_rounded,
                size: 18,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: _kPad),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildActionChip(
              Icons.arrow_upward_rounded, 'Withdraw', _showWithdrawSheet),
          const SizedBox(width: 16),
          _buildActionChip(Icons.history_rounded, 'History', _handleHistory),
        ],
      ),
    );
  }

  Widget _buildActionChip(IconData icon, String label, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
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
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 22, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: _kPad),
      child: Row(
        children: _TransactionFilter.values.map((f) {
          final isSelected = _filter == f;
          final label = switch (f) {
            _TransactionFilter.all => 'All',
            _TransactionFilter.deposits => 'Deposits',
            _TransactionFilter.withdrawals => 'Withdrawals',
          };
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => setState(() => _filter = f),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary
                      : Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.borderLight,
                  ),
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEmptyFilterState() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: _kPad, vertical: 48),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.search_off_rounded,
                size: 48, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            const Text(
              'No transactions match this filter',
              style: TextStyle(fontSize: 14, color: AppColors.textHint),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildTransactionSections(
    Map<String, List<TransactionEntity>> sections,
    bool hasMore,
  ) {
    final widgets = <Widget>[];
    for (final key in _sectionOrder) {
      if (!sections.containsKey(key)) continue;
      final txs = sections[key]!;
      widgets.add(Padding(
        padding: EdgeInsets.only(
          left: _kPad,
          right: _kPad,
          top: key == _sectionOrder.first ? 0 : 8,
          bottom: 8,
        ),
        child: Text(
          key,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.textHint,
          ),
        ),
      ));
      for (var i = 0; i < txs.length && (_displayCount == 0 || i < _displayCount); i++) {
        widgets.add(_buildTransactionTile(txs[i]));
      }
      if (hasMore && key == _sectionOrder.last) {
        widgets.add(Padding(
          padding: const EdgeInsets.symmetric(horizontal: _kPad, vertical: 12),
          child: GestureDetector(
            onTap: () => setState(() => _displayCount = _displayCount == 0 ? 5 : 0),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.primary),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'See All',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(Icons.expand_more, size: 18, color: AppColors.primary),
                ],
              ),
            ),
          ),
        ));
      }
    }
    return widgets;
  }

  Widget _buildTransactionTile(TransactionEntity tx) {
    final color = _txColor(tx.paymentType, tx.value);
    final icon = _txIcon(tx.paymentType);
    final label = _txTypeLabel(tx.paymentType);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: _kPad, vertical: 4),
      child: Container(
        padding: const EdgeInsets.all(14),
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
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 22, color: color),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tx.paymentType ?? 'Transaction',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textHint,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '${tx.value.abs().round().toString()} ج.م',
              textDirection: TextDirection.rtl,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWithdrawSheet() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Withdraw Funds',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Choose a withdrawal method',
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          ..._withdrawMethods.map((m) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    _showWithdrawFormSheet(m.title);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.borderLight),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child:
                              Icon(m.icon, color: AppColors.primary, size: 24),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                m.title,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                m.subtitle,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textHint,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded,
                            color: AppColors.textHint),
                      ],
                    ),
                  ),
                ),
              )),
        ],
      ),
    );
  }
}

class _WithdrawFormSheet extends StatefulWidget {
  final String method;
  const _WithdrawFormSheet({required this.method});

  @override
  State<_WithdrawFormSheet> createState() => _WithdrawFormSheetState();
}

class _WithdrawFormSheetState extends State<_WithdrawFormSheet> {
  final _amountCtl = TextEditingController();
  final _detailsCtl = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _amountCtl.dispose();
    _detailsCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Withdraw via ${widget.method}',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _amountCtl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Amount (EGP)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _detailsCtl,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Account Details',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: AqarButton(
              text: _isSubmitting ? 'Processing...' : 'Submit',
              onPressed: _isSubmitting
                  ? null
                  : () async {
                      setState(() => _isSubmitting = true);
                      final navigator = Navigator.of(context);
                      final amount = double.tryParse(_amountCtl.text) ?? 0;
                      context.read<WalletBloc>().add(
                            RequestWithdrawalTriggered(
                              amount: amount,
                              method: widget.method,
                              receiverData: _detailsCtl.text,
                            ),
                          );
                      await Future.delayed(const Duration(milliseconds: 500));
                      if (!mounted) return;
                      navigator.pop();
                    },
            ),
          ),
        ],
      ),
    );
  }
}
