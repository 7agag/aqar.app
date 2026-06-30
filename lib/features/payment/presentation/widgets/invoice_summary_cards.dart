import 'package:flutter/material.dart';
import 'package:aqar/core/theme/app_colors.dart';
import 'package:aqar/features/invoice/domain/entities/invoice_entity.dart' show RenterStats, OwnerStats;

class InvoiceSummaryCards extends StatelessWidget {
  final RenterStats? renterStats;
  final OwnerStats? ownerStats;
  final bool isRenter;

  const InvoiceSummaryCards({
    super.key,
    this.renterStats,
    this.ownerStats,
    required this.isRenter,
  });

  @override
  Widget build(BuildContext context) {
    final stats = isRenter ? renterStats : ownerStats;
    if (stats == null) return const SizedBox.shrink();

    final cards = _buildCards(stats);
    if (cards.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 88,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: cards.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) => cards[i],
      ),
    );
  }

  List<Widget> _buildCards(dynamic stats) {
    if (stats is RenterStats) {
      return [
        _buildCard('Total Due', stats.totalDue, AppColors.primary,
            Icons.account_balance_wallet_rounded),
        if (stats.unpaidCount > 0)
          _buildCard('Unpaid (${stats.unpaidCount})', null, Colors.orange,
              Icons.pending_actions_rounded),
        if (stats.overdueCount > 0)
          _buildCard('Overdue (${stats.overdueCount})', null, AppColors.error,
              Icons.warning_rounded),
        if (stats.paidCount > 0)
          _buildCard('Paid (${stats.paidCount})', null, AppColors.success,
              Icons.check_circle_rounded),
      ];
    }
    if (stats is OwnerStats) {
      return [
        _buildCard('Expected Income', stats.expectedIncome, AppColors.primary,
            Icons.trending_up_rounded),
        if (stats.pendingCount > 0)
          _buildCard('Pending (${stats.pendingCount})', null, Colors.orange,
              Icons.pending_actions_rounded),
        if (stats.paidCount > 0)
          _buildCard('Paid (${stats.paidCount})', null, AppColors.success,
              Icons.check_circle_rounded),
        if (stats.delinquentTenants > 0)
          _buildCard('Delinquent (${stats.delinquentTenants})', null,
              AppColors.error, Icons.person_off_rounded),
      ];
    }
    return [];
  }

  Widget _buildCard(String label, double? amount, Color color, IconData icon) {
    return Container(
      width: 160,
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textHint,
                  ),
                ),
                const SizedBox(height: 2),
                if (amount != null)
                  Text(
                    '${amount.round().toString()} ج.م',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: color,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
