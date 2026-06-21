import 'package:dartz/dartz.dart';
import 'package:aqar/core/error/failures.dart';
import 'package:aqar/features/purchase_request/domain/entities/purchase_request_entity.dart';

abstract class PurchaseRequestRepository {
  Future<Either<Failure, List<PurchaseRequestEntity>>> getMyRequests();
  Future<Either<Failure, List<PurchaseRequestEntity>>> getReceivedRequests();
  Future<Either<Failure, String>> createRequest({
    required int propertyId,
    String? message,
  });
  Future<Either<Failure, String>> updateRequestStatus({
    required String requestId,
    required String status,
  });
  Future<Either<Failure, String>> cancelRequest(String requestId);
  Future<Either<Failure, String>> markPropertySold(int propertyId);
}
