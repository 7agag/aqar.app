num? parseNum(dynamic v) {
  if (v is num) return v;
  if (v is String) return num.tryParse(v);
  return null;
}

int parseInt(dynamic v, [int defaultValue = 0]) {
  return (parseNum(v)?.toInt()) ?? defaultValue;
}

double parseDouble(dynamic v, [double defaultValue = 0.0]) {
  return (parseNum(v)?.toDouble()) ?? defaultValue;
}
