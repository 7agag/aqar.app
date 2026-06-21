import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:aqar/core/navigation/property_detail_navigator.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../../../features/auth/presentation/bloc/auth_state.dart';
import '../../../property/presentation/widgets/sponsored_property_card.dart';
import '../bloc/favorite_bloc.dart';

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  bool _isRefreshing = false;
  bool _hasDispatched = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasDispatched) {
      final authState = context.read<AuthBloc>().state;
      if (authState is AuthProfileLoaded) {
        context.read<FavoriteBloc>().add(GetFavoritesEvent());
        _hasDispatched = true;
      }
    }
  }

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
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthUnauthenticated || state is AuthInitial) {
            _hasDispatched = false;
          }
        },
        child: BlocBuilder<FavoriteBloc, FavoriteState>(
          builder: (context, state) {
            if (state is FavoriteLoading) {
              return const Center(child: CircularProgressIndicator(color: AppColors.primary));
            }
            if (state is FavoriteLoaded) {
              final favorites = state.favorites;
              if (favorites.isEmpty) {
                return _buildEmpty();
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
                      onTap: () => propertyDetailNavigator.value = property.propertyId,
                      onFavTap: () {
                        context.read<FavoriteBloc>().add(RemoveFavoriteEvent(property.propertyId));
                      },
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
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        state.message.contains('401') || state.message.contains('Unauthorized')
                            ? 'Session expired. Please log in again.'
                            : state.message,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppColors.error),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        if (state.message.contains('401') || state.message.contains('Unauthorized')) {
                          Navigator.pushReplacementNamed(context, '/auth');
                        } else {
                          context.read<FavoriteBloc>().add(GetFavoritesEvent());
                        }
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                      child: Text(
                        state.message.contains('401') || state.message.contains('Unauthorized')
                            ? 'Go to Login'
                            : 'Retry',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              );
            }
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          },
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.borderLight),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(Icons.favorite_border_rounded, size: 42, color: AppColors.textHint),
            ),
            const SizedBox(height: 24),
            const Text(
              'No favorites yet',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              'Start adding properties you love.\nTap the heart icon on any listing.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary.withValues(alpha: 0.8), height: 1.5),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => Navigator.pushReplacementNamed(context, '/home'),
              icon: const Icon(Icons.explore_outlined, size: 18),
              label: const Text('Browse Properties'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
