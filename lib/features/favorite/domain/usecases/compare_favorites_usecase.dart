import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../property/domain/entities/property_entity.dart';
import '../repositories/favorite_repository.dart';

@injectable
class CompareFavoritesUseCase extends UseCase<List<PropertyEntity>, CompareFavoritesParams> {
  final FavoriteRepository repository;
  CompareFavoritesUseCase(this.repository);

  @override
  Future<Either<Failure, List<PropertyEntity>>> call(CompareFavoritesParams params) {
    return repository.compareFavorites(params.propertyIds);
  }
}

class CompareFavoritesParams extends Equatable {
  final List<int> propertyIds;
  const CompareFavoritesParams({required this.propertyIds});
  @override
  List<Object?> get props => [propertyIds];
}
