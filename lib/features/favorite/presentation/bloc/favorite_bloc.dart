import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../property/domain/entities/property_entity.dart';
import '../../domain/usecases/add_to_favorite_usecase.dart';
import '../../domain/usecases/remove_from_favorite_usecase.dart';
import '../../domain/usecases/get_favorites_usecase.dart';

part 'favorite_event.dart';
part 'favorite_state.dart';

@injectable
class FavoriteBloc extends Bloc<FavoriteEvent, FavoriteState> {
  final AddToFavoriteUseCase addToFavorite;
  final RemoveFromFavoriteUseCase removeFromFavorite;
  final GetFavoritesUseCase getFavorites;

  FavoriteBloc({
    required this.addToFavorite,
    required this.removeFromFavorite,
    required this.getFavorites,
  }) : super(FavoriteInitial()) {
    on<AddFavoriteEvent>(_onAddFavorite);
    on<RemoveFavoriteEvent>(_onRemoveFavorite);
    on<GetFavoritesEvent>(_onGetFavorites);
  }

  Future<void> _onAddFavorite(
      AddFavoriteEvent event, Emitter<FavoriteState> emit) async {
    emit(FavoriteLoading());
    final result = await addToFavorite(event.propertyId);
    result.fold(
      (failure) => emit(FavoriteError(failure.message)),
      (_) => emit(FavoriteOperationSuccess('Added to favorites')),
    );
    add(GetFavoritesEvent()); // تحديث القائمة بعد الإضافة
  }

  Future<void> _onRemoveFavorite(
      RemoveFavoriteEvent event, Emitter<FavoriteState> emit) async {
    emit(FavoriteLoading());
    final result = await removeFromFavorite(event.propertyId);
    result.fold(
      (failure) => emit(FavoriteError(failure.message)),
      (_) => emit(FavoriteOperationSuccess('Removed from favorites')),
    );
    add(GetFavoritesEvent());
  }

  Future<void> _onGetFavorites(
      GetFavoritesEvent event, Emitter<FavoriteState> emit) async {
    final result = await getFavorites(NoParams());
    result.fold(
      (failure) => emit(FavoriteError(failure.message)),
      (favorites) => emit(FavoriteLoaded(favorites)),
    );
  }
}
