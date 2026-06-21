import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import '../../../../../core/error/failures.dart';
import '../../../../../core/usecases/usecase.dart';
import '../repositories/property_repository.dart';

@injectable
class GetBookedDatesUseCase extends UseCase<List<Map<String, dynamic>>, int> {
  final PropertyRepository repository;
  GetBookedDatesUseCase(this.repository);

  @override
  Future<Either<Failure, List<Map<String, dynamic>>>> call(int params) {
    return repository.getBookedDates(params);
  }
}
