import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import '../../../../../core/error/failures.dart';
import '../../../../../core/usecases/usecase.dart';
import '../entities/property_entity.dart';
import '../entities/property_filter_params.dart';
import '../repositories/property_repository.dart';

@injectable
class GetPropertiesUseCase extends UseCase<List<PropertyEntity>, PropertyFilterParams> {
  final PropertyRepository repository;
  GetPropertiesUseCase(this.repository);

  @override
  Future<Either<Failure, List<PropertyEntity>>> call(PropertyFilterParams params) {
    return repository.getProperties(params);
  }
}