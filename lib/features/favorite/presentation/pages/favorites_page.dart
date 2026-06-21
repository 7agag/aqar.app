// lib/features/favorite/presentation/pages/favorites_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:aqar/core/navigation/property_detail_navigator.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../property/presentation/widgets/sponsored_property_card.dart';
import '../bloc/favorite_bloc.dart';

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  bool _isRefreshing = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Favorites'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: BlocBuilder<FavoriteBloc, FavoriteState>(
        builder: (context, state) {
          if (state is FavoriteLoading) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }
          if (state is FavoriteLoaded) {
            final favorites = state.favorites;
            if (favorites.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.favorite_border, size: 64, color: AppColors.textHint),
                    SizedBox(height: 16),
                    Text('No favorites yet.\nStart adding properties you like!', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondary)),
                  ],
                ),
              );
            }
            return RefreshIndicator(
              onRefresh: () async {
                if (_isRefreshing) return;
                _isRefreshing = true;
                context.read<FavoriteBloc>().add(GetFavoritesEvent());
                await context.read<FavoriteBloc>().stream.firstWhere(
                  (s) => s is FavoriteLoaded || s is FavoriteError,
                );
                if (mounted) _isRefreshing = false;
              },
              color: AppColors.primary,
              child: GridView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.9,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: favorites.length,
                itemBuilder: (context, index) {
                  final property = favorites[index];
                  return SponsoredPropertyCard(
                    property: property,
                    onTap: () => propertyDetailNavigator.value = property,
                    onFavTap: () { context.read<FavoriteBloc>().add(RemoveFavoriteEvent(property.propertyId)); },
                    isFavorite: true,
                  );
                },
              ),
            );
          }
          if (state is FavoriteError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                  const SizedBox(height: 16),
                  Text(state.message, style: const TextStyle(color: AppColors.error)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.read<FavoriteBloc>().add(GetFavoritesEvent()),
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                    child: const Text('Retry', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            );
          }
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        },
      ),
    );
  }
}
