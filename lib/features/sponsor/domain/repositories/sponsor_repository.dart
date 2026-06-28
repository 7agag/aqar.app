import 'package:dartz/dartz.dart';
import 'package:aqar/core/error/failures.dart';
import 'package:aqar/features/sponsor/domain/entities/sponsor_entity.dart';

abstract class SponsorRepository {
  Future<Either<Failure, SponsorEntity>> createCheckout({
    required int propertyId,
    required int duration,
    required String redirect,
  });
}
