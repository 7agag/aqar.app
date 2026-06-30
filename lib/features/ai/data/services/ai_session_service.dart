import 'dart:math';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:injectable/injectable.dart';

@singleton
class AiSessionService {
  final FlutterSecureStorage _storage;
  static const _key = 'aqar_ai_session_id';

  AiSessionService(this._storage);

  Future<String> getSessionId() async {
    final stored = await _storage.read(key: _key);
    if (stored != null && stored.isNotEmpty) return stored;
    return _generateNew();
  }

  Future<String> resetSessionId() async {
    await _storage.delete(key: _key);
    return _generateNew();
  }

  Future<String> _generateNew() async {
    final random = Random();
    final id =
        '${DateTime.now().millisecondsSinceEpoch}-${random.nextInt(999999)}';
    await _storage.write(key: _key, value: id);
    return id;
  }
}
