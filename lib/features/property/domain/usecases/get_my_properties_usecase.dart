import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import '../../../../../core/error/failures.dart';
import '../../../../../core/usecases/usecase.dart';
import '../entities/property_entity.dart';
import '../repositories/property_repository.dart';

@injectable
class GetMyPropertiesUseCase extends UseCase<List<PropertyEntity>, NoParams> {
  final PropertyRepository repository;
  GetMyPropertiesUseCase(this.repository);

  @override
  Future<Either<Failure, List<PropertyEntity>>> call(NoParams params) {
    return repository.getMyProperties();
  }
}