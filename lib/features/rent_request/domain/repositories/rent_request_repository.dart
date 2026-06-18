import 'package:dartz/dartz.dart';
import 'package:aqar/core/error/failures.dart';
import 'package:aqar/features/rent_request/domain/entities/rent_request_entity.dart';

abstract class RentRequestRepository {
  Future<Either<Failure, List<RentRequestEntity>>> getSentRequests();
  Future<Either<Failure, List<RentRequestEntity>>> getReceivedRequests();
  Future<Either<Failure, String>> createRequest({
    required int propertyId,
    required String checkInDate,
    required String checkOutDate,
    required String rentingType,
  });
  Future<Either<Failure, void>> acceptRequest(String requestId);
  Future<Either<Failure, void>> rejectRequest(String requestId);
  Future<Either<Failure, void>> cancelRequest(String requestId);
}
