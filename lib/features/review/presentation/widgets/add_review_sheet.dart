import 'package:flutter/material.dart';
import 'package:aqar/core/theme/app_colors.dart';

class AddReviewSheet extends StatefulWidget {
  final void Function(double rating, String phrase) onSubmit;

  const AddReviewSheet({super.key, required this.onSubmit});

  @override
  State<AddReviewSheet> createState() => _AddReviewSheetState();
}

class _AddReviewSheetState extends State<AddReviewSheet> {
  double _rating = 5;
  final _phraseController = TextEditingController();

  @override
  void dispose() {
    _phraseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Write a Review',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (i) {
              final starIdx = i + 1;
              return GestureDetector(
                onTap: () => setState(() => _rating = starIdx.toDouble()),
                child: Icon(
                  starIdx <= _rating.round()
                      ? Icons.star_rounded
                      : Icons.star_border_rounded,
                  size: 40,
                  color: const Color(0xFFFFA000),
                ),
              );
            }),
          ),
          const SizedBox(height: 4),
          Center(
            child: Text(
              _ratingText(_rating),
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _phraseController,
            maxLines: 3,
            maxLength: 500,
            decoration: InputDecoration(
              hintText: 'Share your experience...',
              hintStyle: TextStyle(color: AppColors.textHint.withValues(alpha: 0.6)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.textHint.withValues(alpha: 0.2)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.primary),
              ),
              contentPadding: const EdgeInsets.all(14),
              counterStyle: TextStyle(
                fontSize: 11,
                color: AppColors.textHint.withValues(alpha: 0.6),
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                widget.onSubmit(
                  _rating,
                  _phraseController.text.trim(),
                );
              },
              child: const Text(
                'Submit Review',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _ratingText(double rating) {
    switch (rating.round()) {
      case 1:
        return 'Poor';
      case 2:
        return 'Fair';
      case 3:
        return 'Good';
      case 4:
        return 'Very Good';
      case 5:
        return 'Excellent';
      default:
        return '';
    }
  }
}
