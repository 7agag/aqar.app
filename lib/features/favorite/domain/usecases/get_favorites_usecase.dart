import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../property/domain/entities/property_entity.dart';
import '../repositories/favorite_repository.dart';

@injectable
class GetFavoritesUseCase implements UseCase<List<PropertyEntity>, NoParams> {
  final FavoriteRepository repository;

  GetFavoritesUseCase(this.repository);

  @override
  Future<Either<Failure, List<PropertyEntity>>> call(NoParams params) {
    return repository.getUserFavorites();
  }
}