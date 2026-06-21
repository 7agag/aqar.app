import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import '../../../../../core/error/failures.dart';
import '../../../../../core/usecases/usecase.dart';
import '../repositories/property_repository.dart';

@injectable
class EditPropertyImagesUseCase extends UseCase<void, EditPropertyImagesParams> {
  final PropertyRepository repository;
  EditPropertyImagesUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(EditPropertyImagesParams params) {
    return repository.editPropertyImages(params.id, params.formData);
  }
}

class EditPropertyImagesParams {
  final int id;
  final FormData formData;
  const EditPropertyImagesParams({required this.id, required this.formData});
}
