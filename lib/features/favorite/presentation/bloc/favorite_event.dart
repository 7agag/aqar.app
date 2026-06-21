part of 'favorite_bloc.dart';

abstract class FavoriteEvent extends Equatable {
  const FavoriteEvent();
  @override
  List<Object?> get props => [];
}

class AddFavoriteEvent extends FavoriteEvent {
  final int propertyId;
  const AddFavoriteEvent(this.propertyId);
  @override
  List<Object?> get props => [propertyId];
}

class RemoveFavoriteEvent extends FavoriteEvent {
  final int propertyId;
  const RemoveFavoriteEvent(this.propertyId);
  @override
  List<Object?> get props => [propertyId];
}

class GetFavoritesEvent extends FavoriteEvent {}

class CompareFavoritesEvent extends FavoriteEvent {
  final List<int> propertyIds;
  const CompareFavoritesEvent({required this.propertyIds});
  @override
  List<Object?> get props => [propertyIds];
}