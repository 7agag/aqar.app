import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/property_entity.dart';
import '../repositories/property_repository.dart';

@injectable
class GetPropertyByIdUseCase extends UseCase<PropertyEntity, GetPropertyByIdParams> {
  final PropertyRepository repository;
  GetPropertyByIdUseCase(this.repository);

  @override
  Future<Either<Failure, PropertyEntity>> call(GetPropertyByIdParams params) {
    return repository.getPropertyById(params.id);
  }
}

class GetPropertyByIdParams extends Equatable {
  final int id;
  const GetPropertyByIdParams({required this.id});

  @override
  List<Object> get props => [id];
}