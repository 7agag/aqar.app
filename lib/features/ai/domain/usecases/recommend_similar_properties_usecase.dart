import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/ai_repository.dart';

@injectable
class RecommendSimilarPropertiesUseCase
    extends UseCase<List<Map<String, dynamic>>, RecommendSimilarParams> {
  final AiRepository repository;

  RecommendSimilarPropertiesUseCase(this.repository);

  @override
  Future<Either<Failure, List<Map<String, dynamic>>>> call(
    RecommendSimilarParams params,
  ) {
    return repository.recommendSimilarProperties(
      description: params.description,
      sessionId: params.sessionId,
      propertyIds: params.propertyIds,
      limit: params.limit,
    );
  }
}

class RecommendSimilarParams {
  final String description;
  final String sessionId;
  final List<int> propertyIds;
  final int limit;

  const RecommendSimilarParams({
    required this.description,
    required this.sessionId,
    required this.propertyIds,
    required this.limit,
  });
}
