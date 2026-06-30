import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../injection_container.dart' as di;
import '../../../ai/data/services/ai_session_service.dart';
import '../../../ai/domain/usecases/recommend_similar_properties_usecase.dart';
import '../../../favorite/presentation/bloc/favorite_bloc.dart';
import '../../../sponsor/presentation/widgets/sponsored_property_card.dart';
import '../../data/models/property_model.dart';
import '../../domain/entities/property_entity.dart';
import '../pages/property_detail_page.dart';

class RecommendedPropertiesRow extends StatefulWidget {
  final int propertyId;
  final String propertyDescription;

  const RecommendedPropertiesRow({
    super.key,
    required this.propertyId,
    this.propertyDescription = '',
  });

  @override
  State<RecommendedPropertiesRow> createState() =>
      _RecommendedPropertiesRowState();
}

class _RecommendedPropertiesRowState extends State<RecommendedPropertiesRow> {
  final Set<int> _favoriteIds = {};
  List<PropertyEntity> _properties = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    context.read<FavoriteBloc>().add(GetFavoritesEvent());
    _loadRecommendations();
  }

  @override
  void didUpdateWidget(covariant RecommendedPropertiesRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.propertyId != widget.propertyId ||
        oldWidget.propertyDescription != widget.propertyDescription) {
      _loadRecommendations();
    }
  }

  Future<void> _loadRecommendations() async {
    setState(() => _isLoading = true);

    final useCase = di.sl<RecommendSimilarPropertiesUseCase>();
    final sessionService = di.sl<AiSessionService>();
    final sessionId = await sessionService.getSessionId();
    if (!mounted) return;

    final result = await useCase(
      RecommendSimilarParams(
        description: widget.propertyDescription,
        sessionId: sessionId,
        propertyIds: [widget.propertyId],
        limit: 8,
      ),
    );
    if (!mounted) return;

    result.fold(
      (_) => setState(() {
        _properties = [];
        _isLoading = false;
      }),
      (items) => setState(() {
        _properties = items
            .map(PropertyModel.fromJson)
            .where((property) =>
                property.propertyId > 0 &&
                property.propertyId != widget.propertyId &&
                property.isPubliclyVisible)
            .toList(growable: false);
        _isLoading = false;
      }),
    );
  }

  void _toggleFavorite(PropertyEntity property) {
    final isFavorite = _favoriteIds.contains(property.propertyId);
    if (isFavorite) {
      context
          .read<FavoriteBloc>()
          .add(RemoveFavoriteEvent(property.propertyId));
      setState(() => _favoriteIds.remove(property.propertyId));
    } else {
      context.read<FavoriteBloc>().add(AddFavoriteEvent(property.propertyId));
      setState(() => _favoriteIds.add(property.propertyId));
    }
  }

  void _openProperty(PropertyEntity property) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PropertyDetailPage(propertyId: property.propertyId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<FavoriteBloc, FavoriteState>(
      listener: (context, state) {
        if (state is FavoriteLoaded) {
          setState(() {
            _favoriteIds
              ..clear()
              ..addAll(state.favorites.map((property) => property.propertyId));
          });
        }
      },
      child: _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        child: Row(
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primary,
              ),
            ),
            SizedBox(width: 10),
            Text(
              'Finding matches...',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    if (_properties.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Icon(Icons.auto_awesome, color: AppColors.primary, size: 20),
              SizedBox(width: 8),
              Text(
                'AI Similar Properties',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 300,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: _properties.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final property = _properties[index];
              return SizedBox(
                width: 220,
                child: AspectRatio(
                  aspectRatio: 0.75,
                  child: SponsoredPropertyCard(
                    property: property,
                    onTap: () => _openProperty(property),
                    onFavTap: () => _toggleFavorite(property),
                    isFavorite: _favoriteIds.contains(property.propertyId),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
