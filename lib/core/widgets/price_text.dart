import 'package:flutter/material.dart';
import '../extensions/num_formatting.dart';

class PriceText extends StatelessWidget {
  final double value;
  final String? currency;
  final int decimals;
  final TextStyle? style;
  final TextAlign? textAlign;

  const PriceText({
    super.key,
    required this.value,
    this.currency,
    this.decimals = 0,
    this.style,
    this.textAlign,
  });

  @override
  Widget build(BuildContext context) {
    final formatted = value.formatWithCommas(decimals: decimals);
    final text = currency != null ? '$currency $formatted' : formatted;
    return Text(text, style: style, textAlign: textAlign);
  }
}
