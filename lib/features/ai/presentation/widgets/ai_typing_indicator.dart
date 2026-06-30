import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class AiTypingIndicator extends StatefulWidget {
  const AiTypingIndicator({super.key});

  @override
  State<AiTypingIndicator> createState() => _AiTypingIndicatorState();
}

class _AiTypingIndicatorState extends State<AiTypingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _dotController;
  late final Animation<double> _dot1;
  late final Animation<double> _dot2;
  late final Animation<double> _dot3;

  static const _navy = Color(0xFF1A237E);

  @override
  void initState() {
    super.initState();
    _dotController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _dot1 = Tween(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(
        parent: _dotController,
        curve: const Interval(0.0, 1.0, curve: Curves.easeInOut),
      ),
    );
    _dot2 = Tween(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(
        parent: _dotController,
        curve: const Interval(0.2, 1.0, curve: Curves.easeInOut),
      ),
    );
    _dot3 = Tween(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(
        parent: _dotController,
        curve: const Interval(0.4, 1.0, curve: Curves.easeInOut),
      ),
    );
  }

  @override
  void dispose() {
    _dotController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          RepaintBoundary(
            child: Container(
              width: 28,
              height: 28,
              decoration: const BoxDecoration(
                color: _navy,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.auto_awesome,
                size: 14,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 8),
          RepaintBoundary(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(20),
              ),
              child: AnimatedBuilder(
                animation: _dotController,
                builder: (_, __) {
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildDot(_dot1),
                      const SizedBox(width: 5),
                      _buildDot(_dot2),
                      const SizedBox(width: 5),
                      _buildDot(_dot3),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDot(Animation<double> animation) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: AppColors.textHint.withValues(alpha: animation.value),
        shape: BoxShape.circle,
      ),
    );
  }
}
