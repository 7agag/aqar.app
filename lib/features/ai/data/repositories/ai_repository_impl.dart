import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/ai_response_entity.dart';
import '../../domain/repositories/ai_repository.dart';
import '../datasources/ai_remote_datasource.dart';

@Injectable(as: AiRepository)
class AiRepositoryImpl implements AiRepository {
  final AiRemoteDataSource remoteDataSource;

  AiRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<Failure, AiResponseEntity>> sendMessage({
    required String sessionId,
    required String message,
  }) async {
    try {
      final result = await remoteDataSource.sendChatMessage(sessionId, message);
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, List<Map<String, dynamic>>>> searchProperties(
    String query,
  ) async {
    try {
      final result = await remoteDataSource.searchProperties(query);
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, List<Map<String, dynamic>>>>
      recommendSimilarProperties({
    required String description,
    required String sessionId,
    required List<int> propertyIds,
    required int limit,
  }) async {
    try {
      final result = await remoteDataSource.recommendSimilarProperties(
        description: description,
        sessionId: sessionId,
        propertyIds: propertyIds,
        limit: limit,
      );
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Unexpected error: $e'));
    }
  }
}
