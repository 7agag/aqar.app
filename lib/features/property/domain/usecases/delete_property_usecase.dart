import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import '../../../../../core/error/failures.dart';
import '../../../../../core/usecases/usecase.dart';
import '../repositories/property_repository.dart';

@injectable
class DeletePropertyUseCase extends UseCase<void, int> {
  final PropertyRepository repository;
  DeletePropertyUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(int params) {
    return repository.deleteProperty(params);
  }
}
