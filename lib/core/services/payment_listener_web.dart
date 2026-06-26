import 'dart:async';
import 'dart:html' as html;

class PaymentListener {
  static html.BroadcastChannel? _channel;
  static StreamController<Map<String, dynamic>>? _controller;
  static bool _initialized = false;
  static Map<String, dynamic>? _lastMessage;
  static StreamSubscription<dynamic>? _messageSub;

  static void start() {
    if (_initialized) return;
    _initialized = true;
    _controller = StreamController<Map<String, dynamic>>.broadcast();

    // 1. BroadcastChannel (fallback)
    _channel = html.BroadcastChannel('kashier_payment');
    _channel!.onMessage.listen((html.MessageEvent event) {
      final data = event.data;
      if (data is Map) {
        _onMessage(data.cast<String, dynamic>());
      }
    });

    // 2. postMessage from window.opener (primary)
    _messageSub = html.window.onMessage.listen((html.MessageEvent event) {
      final data = event.data;
      if (data is Map && data['type'] == 'kashier_payment') {
        _onMessage(data.cast<String, dynamic>());
      }
    });
  }

  static void _onMessage(Map<String, dynamic> data) {
    _lastMessage = data;
    _controller!.add(data);
  }

  static Stream<Map<String, dynamic>> get stream {
    if (_controller == null) throw StateError('PaymentListener not started');
    return _controller!.stream;
  }

  static Map<String, dynamic>? get lastMessage => _lastMessage;

  static void dispose() {
    _channel?.close();
    _messageSub?.cancel();
    _controller?.close();
    _lastMessage = null;
    _initialized = false;
  }
}
