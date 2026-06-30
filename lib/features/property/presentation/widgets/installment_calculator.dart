import 'dart:math';

import 'package:flutter/material.dart';

import '../../../../core/extensions/num_formatting.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/localization/app_strings.dart';
import '../../domain/entities/property_entity.dart';

class InstallmentCalculator extends StatefulWidget {
  final PropertyEntity property;

  const InstallmentCalculator({super.key, required this.property});

  @override
  State<InstallmentCalculator> createState() => _InstallmentCalculatorState();
}

class _InstallmentCalculatorState extends State<InstallmentCalculator> {
  double _downPaymentPercent = 20;
  int _years = 10;
  double? _monthlyResult;

  @override
  void initState() {
    super.initState();
    _calculate();
  }

  void _calculate() {
    final price = widget.property.priceValue;
    final principal = price * (1 - _downPaymentPercent / 100);
    const annualRate = 0.085;
    final r = annualRate / 12;
    final n = _years * 12;
    if (r == 0 || n == 0) return;
    final monthly = principal * (r * pow(1 + r, n)) / (pow(1 + r, n) - 1);
    _monthlyResult = monthly;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.installmentCalc,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Text(
                AppStrings.salePrice,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              const Spacer(),
              Text(
                'EGP ${widget.property.priceValue.formatWithCommas()}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppStrings.downPayment,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                '${_downPaymentPercent.toStringAsFixed(0)}%',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          Slider(
            min: 0,
            max: 90,
            divisions: 18,
            value: _downPaymentPercent,
            activeColor: AppColors.primary,
            inactiveColor: AppColors.primary.withValues(alpha: 0.2),
            onChanged: (v) {
              setState(() {
                _downPaymentPercent = v;
                _calculate();
              });
            },
          ),
          Text(
            'EGP ${(widget.property.priceValue * _downPaymentPercent / 100).formatWithCommas()}',
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppStrings.numberOfYears,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                '$_years ${AppStrings.year}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          Slider(
            min: 1,
            max: 30,
            divisions: 29,
            value: _years.toDouble(),
            activeColor: AppColors.primary,
            inactiveColor: AppColors.primary.withValues(alpha: 0.2),
            onChanged: (v) {
              setState(() {
                _years = v.toInt();
                _calculate();
              });
            },
          ),
          const SizedBox(height: 20),
          Divider(color: AppColors.borderLight, height: 1),
          const SizedBox(height: 16),
          if (_monthlyResult != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        AppStrings.monthlyPayment,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        'EGP ${_monthlyResult!.formatWithCommas()}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        AppStrings.totalPayment,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        'EGP ${(_monthlyResult! * _years * 12).formatWithCommas()}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
