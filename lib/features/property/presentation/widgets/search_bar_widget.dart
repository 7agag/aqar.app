// lib/features/property/presentation/widgets/search_bar_widget.dart

import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class SearchBarWidget extends StatefulWidget {
  final Function(String) onSubmitted; // ✅ البحث عند Enter فقط
  final VoidCallback onFilterTap;
  final bool hasActiveFilters;
  final String? currentQuery;

  const SearchBarWidget({
    super.key,
    required this.onSubmitted,
    required this.onFilterTap,
    this.hasActiveFilters = false,
    this.currentQuery,
  });

  @override
  State<SearchBarWidget> createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends State<SearchBarWidget> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller.text = widget.currentQuery ?? '';
  }

  @override
  void didUpdateWidget(covariant SearchBarWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentQuery != oldWidget.currentQuery) {
      _controller.text = widget.currentQuery ?? '';
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _clearSearch() {
    _controller.clear();
    widget.onSubmitted(''); // استدعاء البحث عند المسح
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final hasText = _controller.text.isNotEmpty;

    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const SizedBox(width: 16),
          Icon(
            Icons.search_rounded,
            color: hasText ? AppColors.primary : AppColors.textHint,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              onSubmitted: widget.onSubmitted, // ✅ البحث عند الضغط على Enter
              decoration: const InputDecoration(
                hintText: 'Search by name, location...',
                hintStyle: TextStyle(
                  color: AppColors.textHint,
                  fontSize: 14,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
                filled: false,
              ),
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          if (hasText)
            GestureDetector(
              onTap: _clearSearch,
              child: Container(
                width: 28,
                height: 28,
                margin: const EdgeInsets.only(right: 4),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close_rounded,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          GestureDetector(
            onTap: widget.onFilterTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              width: 38,
              height: 38,
              margin: const EdgeInsets.only(right: 6),
              decoration: BoxDecoration(
                color: widget.hasActiveFilters ? AppColors.primary : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: widget.hasActiveFilters ? AppColors.primary : AppColors.borderLight,
                ),
                boxShadow: widget.hasActiveFilters
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.28),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
              ),
              child: Icon(
                Icons.tune_rounded,
                color: widget.hasActiveFilters ? Colors.white : AppColors.textPrimary,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }
}