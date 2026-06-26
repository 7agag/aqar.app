import 'package:flutter/widgets.dart';
import '../entities/payment_result_entity.dart';

abstract class PaymentService {
  Future<PaymentResultEntity> processPayment({
    required String url,
    String? requestId,
    int? propertyId,
    String? ownerId,
    required BuildContext context,
  });
}