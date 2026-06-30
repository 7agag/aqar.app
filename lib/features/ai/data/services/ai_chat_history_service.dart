import 'dart:convert';

import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/ai_message_entity.dart';

@singleton
class AiChatHistoryService {
  static const _key = 'aqar_ai_history_v3';
  static const _maxMessages = 50;

  Future<List<AiMessageEntity>> loadMessages() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return [];

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];
      return decoded
          .whereType<Map>()
          .map((item) =>
              AiMessageEntity.fromJson(Map<String, dynamic>.from(item)))
          .toList(growable: false);
    } catch (_) {
      return [];
    }
  }

  Future<void> saveMessages(List<AiMessageEntity> messages) async {
    final prefs = await SharedPreferences.getInstance();
    final latest = messages.length > _maxMessages
        ? messages.sublist(messages.length - _maxMessages)
        : messages;
    await prefs.setString(
      _key,
      jsonEncode(latest.map((message) => message.toJson()).toList()),
    );
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
