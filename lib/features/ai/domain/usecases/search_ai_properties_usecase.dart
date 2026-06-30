import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/ai_repository.dart';

@injectable
class SearchAiPropertiesUseCase extends UseCase<List<Map<String, dynamic>>, SearchAiPropertiesParams> {
  final AiRepository repository;
  SearchAiPropertiesUseCase(this.repository);

  @override
  Future<Either<Failure, List<Map<String, dynamic>>>> call(SearchAiPropertiesParams params) {
    return repository.searchProperties(params.query);
  }
}

class SearchAiPropertiesParams {
  final String query;
  const SearchAiPropertiesParams({required this.query});
}
