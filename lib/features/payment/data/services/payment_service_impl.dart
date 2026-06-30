import 'package:flutter/material.dart';
import 'package:aqar/core/services/escrow_service.dart';
import 'package:aqar/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:aqar/features/auth/presentation/bloc/auth_state.dart';
import 'package:aqar/features/payment/data/services/payment_validator.dart';
import 'package:aqar/features/payment/domain/entities/payment_result_entity.dart';
import 'package:aqar/features/payment/domain/services/payment_service.dart';
import 'package:aqar/features/payment/presentation/pages/kashier_web_view_page.dart';
import 'package:aqar/features/rent_request/presentation/bloc/rent_request_bloc.dart';
import 'package:aqar/features/rent_request/presentation/bloc/rent_request_event.dart';

class PaymentServiceImpl implements PaymentService {
  final EscrowService _escrowService;
  final AuthBloc _authBloc;
  final RentRequestBloc _rentRequestBloc;

  PaymentServiceImpl({
    required EscrowService escrowService,
    required AuthBloc authBloc,
    required RentRequestBloc rentRequestBloc,
  })  : _escrowService = escrowService,
        _authBloc = authBloc,
        _rentRequestBloc = rentRequestBloc;

  @override
  Future<PaymentResultEntity> processPayment({
    required String url,
    String? requestId,
    int? propertyId,
    String? ownerId,
    required BuildContext context,
  }) async {
    try {
      final validationError = PaymentValidator.validate(url: url);
      if (validationError != null) {
        return PaymentResultEntity(success: false, message: validationError);
      }

      final result = await KashierWebViewPage.open(context, url: url);
      if (!context.mounted) {
        return PaymentResultEntity(success: false, message: 'Session ended');
      }

      if (result?['status'] == 'success') {
        if (requestId != null && propertyId != null && ownerId != null && ownerId.isNotEmpty) {
          final authState = _authBloc.state;
          if (authState is AuthProfileLoaded) {
            await _escrowService.createLease(
              requestId: requestId,
              propertyId: propertyId,
              renterId: authState.user.id,
              ownerId: ownerId,
            );
            _rentRequestBloc.add(const LoadRentRequests());
          }
        }
        return const PaymentResultEntity(success: true);
      }

      return PaymentResultEntity(
        success: false,
        message: result == null ? 'Payment cancelled' : 'Payment was not completed',
      );
    } catch (e) {
      return PaymentResultEntity(
        success: false,
        message: 'Payment failed: $e',
      );
    }
  }
}