import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import '../../../../../core/error/failures.dart';
import '../../../../../core/usecases/usecase.dart';
import '../repositories/property_repository.dart';

@injectable
class AddPropertyUseCase extends UseCase<void, FormData> {
  final PropertyRepository repository;
  AddPropertyUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(FormData params) {
    return repository.addProperty(params);
  }
}
