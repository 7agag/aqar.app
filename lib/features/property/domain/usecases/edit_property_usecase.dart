import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import '../../../../../core/error/failures.dart';
import '../../../../../core/usecases/usecase.dart';
import '../repositories/property_repository.dart';

@injectable
class EditPropertyUseCase extends UseCase<void, EditPropertyParams> {
  final PropertyRepository repository;
  EditPropertyUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(EditPropertyParams params) {
    return repository.editProperty(params.id, params.data);
  }
}

class EditPropertyParams {
  final int id;
  final Map<String, dynamic> data;
  const EditPropertyParams({required this.id, required this.data});
}
