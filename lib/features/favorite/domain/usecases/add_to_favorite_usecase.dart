import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/favorite_repository.dart';

@injectable
class AddToFavoriteUseCase implements UseCase<void, int> {
  final FavoriteRepository repository;

  AddToFavoriteUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(int propertyId) {
    return repository.addToFavorites(propertyId);
  }
}