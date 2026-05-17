import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class SearchBarWidget extends StatefulWidget {
  final Function(String) onSearch;
  final VoidCallback onFilterTap;

  const SearchBarWidget({
    super.key,
    required this.onSearch,
    required this.onFilterTap,
  });

  @override
  State<SearchBarWidget> createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends State<SearchBarWidget> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: [
          const SizedBox(width: 16),
          const Icon(Icons.search, color: AppColors.textHint, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _controller,
              onChanged: widget.onSearch,
              onSubmitted: widget.onSearch,
              decoration: const InputDecoration(
                hintText: 'Search by location, neighborhood...',
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
          GestureDetector(
            onTap: widget.onFilterTap,
            child: Container(
              width: 38,
              height: 38,
              margin: const EdgeInsets.only(right: 6),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.tune_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }
}