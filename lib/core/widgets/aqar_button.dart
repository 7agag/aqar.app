import 'package:flutter/material.dart';
//import '../theme/app_colors.dart';

class AqarButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isLoading;
  final Widget? suffix;

  const AqarButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        child: isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(text),
                  if (suffix != null) ...[
                    const SizedBox(width: 8),
                    suffix!,
                  ],
                ],
              ),
      ),
    );
  }
}