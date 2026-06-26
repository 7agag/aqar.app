import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/navigation/property_detail_navigator.dart';
import '../../../../core/theme/app_colors.dart';
import '../bloc/property_bloc.dart';
import '../bloc/property_event.dart';
import '../bloc/property_state.dart';
import '../../domain/entities/property_entity.dart';
import '../../domain/entities/property_enums.dart';
import '../pages/my_properties_page.dart';
import '../pages/edit_property_page.dart';
import '../pages/add_property_stepper_page.dart';

class ProfilePropertiesWidget extends StatefulWidget {
  const ProfilePropertiesWidget({super.key});

  @override
  State<ProfilePropertiesWidget> createState() => _ProfilePropertiesWidgetState();
}

class _ProfilePropertiesWidgetState extends State<ProfilePropertiesWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerCtrl;

  @override
  void initState() {
    super.initState();
    _shimmerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    context.read<PropertyBloc>().add(const GetMyPropertiesRequested());
  }

  @override
  void dispose() {
    _shimmerCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PropertyBloc, PropertyState>(
      builder: (context, state) {
        if (state is PropertyLoading || state is PropertyInitial) {
          return _buildShimmer();
        }
        if (state is MyPropertiesLoaded) {
          return _buildContent(state.properties);
        }
        if (state is PropertyError) {
          return _buildError(state.message);
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildShimmer() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 18, width: 140,
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 12),
          ...List.generate(2, (_) => _ShimmerCard(controller: _shimmerCtrl)),
        ],
      ),
    );
  }

  Widget _buildError(String message) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('My Listings',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.error_outline, size: 20, color: AppColors.error.withValues(alpha: 0.7)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(message,
                      style: TextStyle(fontSize: 13, color: AppColors.error.withValues(alpha: 0.7))),
                ),
                TextButton(
                  onPressed: () => context.read<PropertyBloc>().add(const GetMyPropertiesRequested()),
                  child: const Text('Retry', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(List<PropertyEntity> properties) {
    final visible = properties.where((p) => p.isVisible).toList();
    final count = visible.length;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'My Listings ($count)',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MyPropertiesPage()),
                ),
                child: Text(
                  'See All',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary.withValues(alpha: 0.8),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (count == 0)
            _buildEmpty()
          else
            Builder(
              builder: (context) {
                final cardWidth = (MediaQuery.of(context).size.width * 0.4).clamp(140, 220).toDouble();
                final cardHeight = (cardWidth * 1.15).clamp(160, 230).toDouble();
                return SizedBox(
                  height: cardHeight,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: count,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (context, index) => _PropertyCardHorizontal(
                      property: visible[index],
                      cardWidth: cardWidth,
                      onTap: () => propertyDetailNavigator.value = visible[index].propertyId,
                      onEdit: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => _EditPropertyPageWrapper(property: visible[index]),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        children: [
          Icon(Icons.home_outlined, size: 40, color: AppColors.textHint.withValues(alpha: 0.5)),
          const SizedBox(height: 8),
          const Text('No listings yet',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
          const SizedBox(height: 4),
          const Text('Add your first property to get started',
              style: TextStyle(fontSize: 12, color: AppColors.textHint)),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const _AddPropertyPageWrapper()),
            ),
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Add Property', style: TextStyle(fontSize: 13)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }
}

class _EditPropertyPageWrapper extends StatelessWidget {
  final PropertyEntity property;
  const _EditPropertyPageWrapper({required this.property});

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: context.read<PropertyBloc>(),
      child: EditPropertyPage(property: property),
    );
  }
}

class _AddPropertyPageWrapper extends StatelessWidget {
  const _AddPropertyPageWrapper();

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: context.read<PropertyBloc>(),
      child: const AddPropertyStepperPage(),
    );
  }
}

class _ShimmerCard extends StatelessWidget {
  final AnimationController controller;
  const _ShimmerCard({required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) {
        final opacity = 0.2 + (controller.value * 0.4);
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.borderLight.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
                child: Container(
                  width: 90, height: 100,
                  color: Colors.grey.withValues(alpha: opacity),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 12, width: 120,
                        decoration: BoxDecoration(
                          color: Colors.grey.withValues(alpha: opacity),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        height: 10, width: 80,
                        decoration: BoxDecoration(
                          color: Colors.grey.withValues(alpha: opacity),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 10, width: 60,
                        decoration: BoxDecoration(
                          color: Colors.grey.withValues(alpha: opacity),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PropertyCardHorizontal extends StatelessWidget {
  final PropertyEntity property;
  final double cardWidth;
  final VoidCallback onTap;
  final VoidCallback onEdit;

  const _PropertyCardHorizontal({
    required this.property,
    required this.cardWidth,
    required this.onTap,
    required this.onEdit,
  });

  PropertyStatus get _status {
    if (property.isSponsored) return PropertyStatus.sponsored;
    if (property.listingStatus == ListingStatus.inactive ||
        property.listingStatus == ListingStatus.expired) {
      return PropertyStatus.archived;
    }
    if (property.listingType == ListingType.forSale) {
      return PropertyStatus.forSale;
    }
    return PropertyStatus.forRent;
  }

  @override
  Widget build(BuildContext context) {
    final status = _status;
    final imageHeight = cardWidth * 0.58;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: cardWidth,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderLight.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: SizedBox(
                width: cardWidth,
                height: imageHeight,
                child: property.images.isNotEmpty
                    ? Image.network(property.images.first, fit: BoxFit.cover)
                    : Container(
                        color: AppColors.surfaceLight,
                        child: const Icon(Icons.home, color: AppColors.textHint, size: 28),
                      ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Flexible(
                      child: Text(
                        property.propertyName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 5, height: 5,
                          decoration: BoxDecoration(color: status.color, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 3),
                        Text(
                          status.label,
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: status.color),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            'EGP ${property.priceValue.toStringAsFixed(0)}${property.pricingUnitSuffix}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: AppColors.navyBlue,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        GestureDetector(
                          onTap: onEdit,
                          child: Icon(Icons.edit_outlined, size: 16, color: AppColors.textHint.withValues(alpha: 0.6)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
