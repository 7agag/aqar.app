import 'dart:async';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../config/app_config.dart';

class SocketService {
  final FlutterSecureStorage _storage;
  io.Socket? _socket;
  bool _connecting = false;
  final _messageController = StreamController<Map<String, dynamic>>.broadcast();
  final _connectionController = StreamController<bool>.broadcast();
  final _notificationController = StreamController<Map<String, dynamic>>.broadcast();

  SocketService(this._storage);

  Stream<Map<String, dynamic>> get onMessage => _messageController.stream;
  Stream<bool> get onConnectionChange => _connectionController.stream;
  Stream<Map<String, dynamic>> get onNotification => _notificationController.stream;

  bool get isConnected => _socket?.connected ?? false;

  Future<void> connect() async {
    if (_socket?.connected == true || _connecting) return;

    _connecting = true;
    try {
      final token = await _storage.read(key: 'access_token');
      if (token == null || token.isEmpty) {
        _connecting = false;
        return;
      }

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

      _socket!.onConnect((_) {
        _connecting = false;
        _connectionController.add(true);
      });

      _socket!.on('new_chat_message', (data) {
        if (data is Map<String, dynamic>) {
          _messageController.add(data);
        }
      });

      _socket!.on('new_notification', (data) {
        if (data is Map<String, dynamic>) {
          _notificationController.add(data);
        }
      });

      _socket!.onDisconnect((reason) {
        _connecting = false;
        _connectionController.add(false);
      });

      _socket!.onConnectError((error) {
        _connecting = false;
      });
    } catch (_) {
      _connecting = false;
    }
  }

  void disconnect() {
    _connecting = false;
    _disconnectCurrent();
  }

  void _disconnectCurrent() {
    if (_socket == null) return;
    _socket!.off('new_chat_message');
    _socket!.off('new_notification');
    _socket!.disconnect();
    _socket!.close();
    _socket = null;
  }

  void dispose() {
    _connecting = false;
    _disconnectCurrent();
    _messageController.close();
    _connectionController.close();
    _notificationController.close();
  }
}
