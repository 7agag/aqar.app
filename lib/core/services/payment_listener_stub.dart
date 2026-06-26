import 'dart:async';

class PaymentListener {
  static void start() {}

  static Stream<Map<String, dynamic>> get stream =>
      const Stream<Map<String, dynamic>>.empty();

  static Map<String, dynamic>? get lastMessage => null;

  static void dispose() {}
}
