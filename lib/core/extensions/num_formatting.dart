import 'package:intl/intl.dart';

extension NumberFormatting on num {
  String formatWithCommas({int decimals = 0}) =>
      NumberFormat('#,##0${decimals > 0 ? '.${'0' * decimals}' : ''}').format(this);
}
