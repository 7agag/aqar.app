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
import '../../domain/entities/property_filter_params.dart';
import '../../domain/usecases/get_properties_usecase.dart';
import '../pages/property_detail_page.dart';

class RecommendedPropertiesRow extends StatefulWidget {
  final PropertyEntity property;

  const RecommendedPropertiesRow({
    super.key,
    required this.property,
  });

  @override
  State<RecommendedPropertiesRow> createState() =>
      _RecommendedPropertiesRowState();
}

class _RecommendedPropertiesRowState extends State<RecommendedPropertiesRow> {
  final Set<int> _favoriteIds = {};
  List<PropertyEntity> _properties = [];
  bool _isLoading = false;
  bool _isFallback = false;

  @override
  void initState() {
    super.initState();
    context.read<FavoriteBloc>().add(GetFavoritesEvent());
    _loadRecommendations();
  }

  @override
  void didUpdateWidget(covariant RecommendedPropertiesRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.property.propertyId != widget.property.propertyId) {
      _loadRecommendations();
    }
  }

  Future<void> _loadRecommendations() async {
    setState(() {
      _isLoading = true;
      _isFallback = false;
      _properties = [];
    });

    // Try AI first
    await _tryAiRecommendations();

    // Fallback to main API if AI returned nothing
    if (mounted && _properties.isEmpty) {
      await _tryApiFallback();
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _tryAiRecommendations() async {
    final useCase = di.sl<RecommendSimilarPropertiesUseCase>();
    final sessionService = di.sl<AiSessionService>();
    final sessionId = await sessionService.getSessionId();
    if (!mounted) return;

    final result = await useCase(
      RecommendSimilarParams(
        description: widget.property.propertyDesc,
        sessionId: sessionId,
        propertyIds: [widget.property.propertyId],
        limit: 8,
      ),
    );
    if (!mounted) return;

    result.fold(
      (_) {},
      (items) {
        final parsed = items
            .map(PropertyModel.fromJson)
            .where((property) =>
                property.propertyId > 0 &&
                property.propertyId != widget.property.propertyId &&
                property.isPubliclyVisible)
            .toList(growable: false);
        if (parsed.isNotEmpty) {
          _properties = parsed;
        }
      },
    );
  }

  Future<void> _tryApiFallback() async {
    final getProperties = di.sl<GetPropertiesUseCase>();
    final result = await getProperties(
      PropertyFilterParams(
        listingType: widget.property.listingType.value,
      ),
    );
    if (!mounted) return;

    result.fold(
      (_) {},
      (items) {
        final filtered = items
            .where((p) =>
                p.propertyId != widget.property.propertyId &&
                p.isPubliclyVisible)
            .take(8)
            .toList(growable: false);
        if (filtered.isNotEmpty) {
          _properties = filtered;
          _isFallback = true;
        }
      },
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
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Icon(
                _isFallback ? Icons.home_work_outlined : Icons.auto_awesome,
                color: AppColors.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                _isFallback ? 'Similar Properties' : 'AI Similar Properties',
                style: const TextStyle(
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
