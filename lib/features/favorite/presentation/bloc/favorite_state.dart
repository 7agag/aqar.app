part of 'favorite_bloc.dart';

abstract class FavoriteState extends Equatable {
  const FavoriteState();
  @override
  List<Object?> get props => [];
}

class FavoriteInitial extends FavoriteState {}

class FavoriteLoading extends FavoriteState {}

class FavoriteLoaded extends FavoriteState {
  final List<PropertyEntity> favorites;
  const FavoriteLoaded(this.favorites);
  @override
  List<Object?> get props => [favorites];
}

class FavoriteOperationSuccess extends FavoriteState {
  final String message;
  const FavoriteOperationSuccess(this.message);
  @override
  List<Object?> get props => [message];
}

class FavoriteError extends FavoriteState {
  final String message;
  const FavoriteError(this.message);
  @override
  List<Object?> get props => [message];
}