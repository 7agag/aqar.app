import 'dart:async';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../config/app_config.dart';

class SocketService {
  final FlutterSecureStorage _storage;
  io.Socket? _socket;
  final _messageController = StreamController<Map<String, dynamic>>.broadcast();

  SocketService(this._storage);

  Stream<Map<String, dynamic>> get onMessage => _messageController.stream;

  bool get isConnected => _socket?.connected ?? false;

  Future<void> connect() async {
    if (_socket?.connected == true) return;

    final token = await _storage.read(key: 'access_token');
    if (token == null || token.isEmpty) return;

    _disconnectCurrent();

    _socket = io.io(
      AppConfig.baseUrl,
      <String, dynamic>{
        'transports': ['websocket'],
        'query': {'token': token},
        'reconnection': true,
        'reconnectionAttempts': 10,
        'reconnectionDelay': 2000,
      },
    );

    _socket!.onConnect((_) {});

    _socket!.on('new_chat_message', (data) {
      if (data is Map<String, dynamic>) {
        _messageController.add(data);
      }
    });

    _socket!.onDisconnect((_) {});

    _socket!.onConnectError((_) {});
  }

  void disconnect() {
    _disconnectCurrent();
  }

  void _disconnectCurrent() {
    _socket?.off('new_chat_message');
    _socket?.disconnect();
    _socket?.close();
    _socket = null;
  }

  void dispose() {
    _disconnectCurrent();
    _messageController.close();
  }
}
