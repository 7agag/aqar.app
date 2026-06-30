import 'package:flutter/material.dart';
import '../../../../core/extensions/num_formatting.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../auth/presentation/widgets/auth_guard.dart';
import '../../../rent_request/presentation/widgets/create_rent_request_sheet.dart';
import '../../domain/entities/property_entity.dart';

class DailyRentCalculator extends StatefulWidget {
  final PropertyEntity property;

  const DailyRentCalculator({super.key, required this.property});

  @override
  State<DailyRentCalculator> createState() => _DailyRentCalculatorState();
}

class _DailyRentCalculatorState extends State<DailyRentCalculator> {
  DateTime? _startDate;
  DateTime? _endDate;

  int get _days {
    if (_startDate != null && _endDate != null && _endDate!.isAfter(_startDate!)) {
      return _endDate!.difference(_startDate!).inDays;
    }
    return 0;
  }

  double get _totalCost => _days * widget.property.pricePerDay;

  Future<void> _pickDate({required bool isStart}) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? (DateTime(now.year, now.month, now.day)) : (_startDate ?? now),
      firstDate: isStart ? DateTime(now.year, now.month, now.day) : (_startDate ?? DateTime(now.year, now.month, now.day)),
      lastDate: DateTime(now.year + 1, now.month, now.day),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          if (_endDate != null && _endDate!.isBefore(picked)) {
            _endDate = null;
          }
        } else {
          _endDate = picked;
        }
      });
    }
  }

  String _formatDate(DateTime d) {
    return '${d.year}/${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}';
  }

  bool get _hasError => _endDate != null && _startDate != null && _endDate!.isBefore(_startDate!);

  void _openRentRequestSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => CreateRentRequestSheet(property: widget.property),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hint = AppStrings.isArabic ? 'اختر تواريخ الإقامة' : 'Select your stay dates';
    final endHint = AppStrings.isArabic ? 'اختر تاريخ النهاية' : 'Select end date';
    final endDateError = AppStrings.isArabic ? 'تاريخ النهاية يجب أن يكون بعد تاريخ البداية' : 'End date must be after start date';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderLight, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.dailyRent,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 16),
          Text(
            '${AppStrings.pricePerDayLabel}: ${AppStrings.egp} ${widget.property.pricePerDay.formatWithCommas()} / ${AppStrings.day}',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _DateButton(
                  label: AppStrings.fromDate,
                  date: _startDate,
                  formatDate: _formatDate,
                  onTap: () => _pickDate(isStart: true),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _DateButton(
                  label: AppStrings.toDate,
                  date: _endDate,
                  formatDate: _formatDate,
                  onTap: _startDate != null ? () => _pickDate(isStart: false) : null,
                  enabled: _startDate != null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_hasError)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                endDateError,
                style: const TextStyle(color: AppColors.error, fontSize: 13),
              ),
            )
          else if (_startDate != null && _endDate != null)
            _buildSummary()
          else if (_startDate != null)
            Text(
              endHint,
              style: const TextStyle(color: AppColors.textHint, fontSize: 14),
            )
          else
            Text(
              hint,
              style: const TextStyle(color: AppColors.textHint, fontSize: 14),
            ),
          if (_startDate != null && _endDate != null && !_hasError) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () => requireVerifiedUser(
                  context,
                  onAllowed: _openRentRequestSheet,
                ),
                icon: const Icon(Icons.send_rounded, size: 18),
                label: Text(
                  'Request to Rent',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.navyBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSummary() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppStrings.daysCount,
                style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
              ),
              Text(
                '$_days ${AppStrings.isArabic ? 'أيام' : 'days'}',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppStrings.totalCost,
                style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
              ),
              Text(
                '${AppStrings.egp} ${_totalCost.formatWithCommas(decimals: 2)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DateButton extends StatelessWidget {
  final String label;
  final DateTime? date;
  final String Function(DateTime) formatDate;
  final VoidCallback? onTap;
  final bool enabled;

  const _DateButton({
    required this.label,
    required this.date,
    required this.formatDate,
    required this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: AppColors.navyBlue.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: AppColors.navyBlue.withValues(alpha: 0.15),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today,
              size: 16,
              color: AppColors.navyBlue.withValues(alpha: enabled ? 0.8 : 0.35),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.navyBlue.withValues(alpha: 0.5),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    date != null ? formatDate(date!) : AppStrings.selectDate,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: date != null
                          ? AppColors.textPrimary
                          : AppColors.navyBlue.withValues(alpha: enabled ? 0.6 : 0.3),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
