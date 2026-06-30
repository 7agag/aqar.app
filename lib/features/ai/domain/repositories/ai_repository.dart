import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/ai_response_entity.dart';

abstract class AiRepository {
  Future<Either<Failure, AiResponseEntity>> sendMessage({
    required String sessionId,
    required String message,
  });

  Future<Either<Failure, List<Map<String, dynamic>>>> searchProperties(
    String query,
  );

  Future<Either<Failure, List<Map<String, dynamic>>>> recommendSimilarProperties({
    required String description,
    required String sessionId,
    required List<int> propertyIds,
    required int limit,
  });
}
