import 'package:flutter/material.dart';
import 'package:aqar/core/theme/app_colors.dart';

class PhotoTipsCard extends StatelessWidget {
  const PhotoTipsCard({super.key});

  static const _tips = [
    'Include every room — living room, bedroom(s), kitchen, bathroom(s)',
    'Shoot during the day with natural light for best results',
    'Add outdoor / building entrance shots',
    '10 photos recommended — more photos mean more trust from renters',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.navyBlue.withAlpha(10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.navyBlue.withAlpha(30)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb_outline, size: 18, color: AppColors.navyBlue),
              const SizedBox(width: 8),
              Text(
                'Photo Tips',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.navyBlue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...List.generate(_tips.length, (i) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('• ', style: TextStyle(fontSize: 12, color: AppColors.navyBlue, fontWeight: FontWeight.w700)),
                Expanded(
                  child: Text(
                    _tips[i],
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }
}
