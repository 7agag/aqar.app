import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';
import 'package:aqar/core/theme/app_colors.dart';
import 'package:aqar/features/review/presentation/bloc/review_bloc.dart';

class AddReviewSheet extends StatefulWidget {
  final void Function(double rating, String phrase) onSubmit;

  const AddReviewSheet({super.key, required this.onSubmit});

  @override
  State<AddReviewSheet> createState() => _AddReviewSheetState();
}

class _AddReviewSheetState extends State<AddReviewSheet> {
  double _rating = 0;
  bool _isSubmitting = false;
  final _phraseController = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _phraseController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return BlocListener<ReviewBloc, ReviewState>(
      listener: (context, state) {
        if (state is ReviewError) {
          setState(() => _isSubmitting = false);
        }
      },
      child: Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 12,
          bottom: bottomInset > 0 ? bottomInset + 12 : bottomPad + 24,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDragHandle(),
              const SizedBox(height: 12),
              _buildHeader(),
              const SizedBox(height: 16),
              _buildStarRow(),
              const SizedBox(height: 4),
              _buildRatingLabel(),
              const SizedBox(height: 20),
              _buildTextField(),
              const SizedBox(height: 24),
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDragHandle() {
    return Center(
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Write a Review',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }

  Widget _buildStarRow() {
    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(5, (i) {
          final starIdx = i + 1;
          final filled = starIdx <= _rating.round();
          return _AnimatedStar(
            filled: filled,
            onTap: () {
              HapticFeedback.lightImpact();
              setState(() => _rating = starIdx.toDouble());
              if (starIdx > 0) _focusNode.requestFocus();
            },
          );
        }),
      ),
    );
  }

  Widget _buildRatingLabel() {
    final labels = {
      0: 'Tap a star to rate',
      1: '\u{1F61E}  Poor',
      2: '\u{1F610}  Fair',
      3: '\u{1F642}  Good',
      4: '\u{1F60A}  Very Good',
      5: '\u{1F929}  Excellent',
    };

    return Center(
      child: Text(
        labels[_rating.round()] ?? '',
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: _rating == 0 ? AppColors.textHint : AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildTextField() {
    return TextField(
      controller: _phraseController,
      focusNode: _focusNode,
      maxLines: 3,
      maxLength: 500,
      autofocus: false,
      decoration: InputDecoration(
        hintText: 'Tell others about your experience...',
        hintStyle: TextStyle(
          color: AppColors.textHint.withValues(alpha: 0.8),
          fontWeight: FontWeight.w400,
        ),
        filled: true,
        fillColor: AppColors.surfaceLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Colors.black.withValues(alpha: 0.08),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Colors.black.withValues(alpha: 0.08),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.all(14),
        counterStyle: TextStyle(
          fontSize: 11,
          color: AppColors.textHint.withValues(alpha: 0.6),
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    final canSubmit = !_isSubmitting && _rating > 0;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: canSubmit
              ? AppColors.primary
              : AppColors.primary.withValues(alpha: 0.4),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
          shadowColor: Colors.transparent,
        ),
        onPressed: canSubmit
            ? () {
                HapticFeedback.mediumImpact();
                setState(() => _isSubmitting = true);
                widget.onSubmit(
                  _rating,
                  _phraseController.text.trim(),
                );
              }
            : null,
        child: _isSubmitting
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Text(
                'Submit Review',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }
}

class _AnimatedStar extends StatefulWidget {
  final bool filled;
  final VoidCallback onTap;

  const _AnimatedStar({required this.filled, required this.onTap});

  @override
  State<_AnimatedStar> createState() => _AnimatedStarState();
}

class _AnimatedStarState extends State<_AnimatedStar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scale = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _scale,
        builder: (context, child) => Transform.scale(
          scale: _scale.value,
          child: child,
        ),
        child: Container(
          width: 46,
          height: 46,
          alignment: Alignment.center,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            transitionBuilder: (child, animation) => ScaleTransition(
              scale: animation,
              child: child,
            ),
            child: Icon(
              widget.filled ? Icons.star : Icons.star_border,
              key: ValueKey(widget.filled),
              size: 36,
              color: widget.filled
                  ? const Color(0xFFFFA000)
                  : const Color(0xFFF0EBE3),
            ),
          ),
        ),
      ),
    );
  }
}
