import 'package:flutter/material.dart';

class ChatUserColors {
  static final _cache = <String, Color>{};

  static const _palette = [
    Color(0xFF5C6BC0),
    Color(0xFF26A69A),
    Color(0xFFEF5350),
    Color(0xFF42A5F5),
    Color(0xFFFF7043),
    Color(0xFFAB47BC),
    Color(0xFF66BB6A),
    Color(0xFFEC407A),
    Color(0xFF26C6DA),
    Color(0xFF8D6E63),
    Color(0xFF7E57C2),
    Color(0xFFFFCA28),
    Color(0xFF78909C),
    Color(0xFFA1887F),
  ];

  static Color forUser(String userId) =>
      _cache.putIfAbsent(userId, () =>
          _palette[userId.hashCode.abs() % _palette.length]);
}
