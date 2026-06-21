import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/navigation/property_detail_navigator.dart';
import '../../../../core/theme/app_colors.dart';
import '../bloc/property_bloc.dart';
import '../bloc/property_event.dart';
import '../bloc/property_state.dart';
import '../../domain/entities/property_entity.dart';
import '../../domain/entities/property_enums.dart';
import 'select_selling_plan_page.dart';
import 'edit_property_page.dart';
import 'add_property_stepper_page.dart';

class MyPropertiesPage extends StatefulWidget {
  const MyPropertiesPage({super.key});

  @override
  State<MyPropertiesPage> createState() => _MyPropertiesPageState();
}

class _MyPropertiesPageState extends State<MyPropertiesPage>
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
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Properties',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.textPrimary)),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: AppColors.primary),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddPropertyStepperPage()),
            ),
          ),
        ],
      ),
      body: BlocConsumer<PropertyBloc, PropertyState>(
        listener: (context, state) {
          if (state is PropertyOperationSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: AppColors.success),
            );
            context.read<PropertyBloc>().add(const GetMyPropertiesRequested());
          } else if (state is PropertyError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: AppColors.error),
            );
          }
        },
        builder: (context, state) {
          if (state is PropertyLoading || state is PropertyInitial) {
            return _buildShimmer();
          }
          if (state is MyPropertiesLoaded) {
            if (state.properties.isEmpty) return _buildEmpty();
            return _buildList(state.properties);
          }
          if (state is PropertyError) {
            return _buildError(state.message);
          }
          return _buildEmpty();
        },
      ),
    );
  }

  Widget _buildShimmer() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 4,
      itemBuilder: (_, __) => _ShimmerCard(controller: _shimmerCtrl),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.home_outlined, size: 80, color: AppColors.textHint.withValues(alpha: 0.4)),
          const SizedBox(height: 16),
          Text('You haven\'t added\nany properties yet',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: AppColors.textSecondary.withValues(alpha: 0.7), height: 1.4)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddPropertyStepperPage()),
            ),
            icon: const Icon(Icons.add),
            label: const Text('Add Your First Property'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(String message) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, size: 64, color: AppColors.error.withValues(alpha: 0.6)),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => context.read<PropertyBloc>().add(const GetMyPropertiesRequested()),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildList(List<PropertyEntity> properties) {
    return RefreshIndicator(
      onRefresh: () async {
        context.read<PropertyBloc>().add(const GetMyPropertiesRequested());
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: properties.length,
        itemBuilder: (context, index) => _PropertyCard(
          property: properties[index],
          onTap: () => propertyDetailNavigator.value = properties[index],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// SHIMMER CARD
// ---------------------------------------------------------------------------
class _ShimmerCard extends StatelessWidget {
  final AnimationController controller;
  const _ShimmerCard({required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) {
        final opacity = 0.3 + (controller.value * 0.4);
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.horizontal(left: Radius.circular(14)),
                child: Container(
                  width: 120,
                  height: 130,
                  color: Colors.grey.withValues(alpha: opacity),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(height: 14, width: 140,
                          decoration: BoxDecoration(color: Colors.grey.withValues(alpha: opacity),
                              borderRadius: BorderRadius.circular(4))),
                      const SizedBox(height: 8),
                      Container(height: 11, width: 100,
                          decoration: BoxDecoration(color: Colors.grey.withValues(alpha: opacity),
                              borderRadius: BorderRadius.circular(4))),
                      const SizedBox(height: 12),
                      Container(height: 11, width: 80,
                          decoration: BoxDecoration(color: Colors.grey.withValues(alpha: opacity),
                              borderRadius: BorderRadius.circular(4))),
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

// ---------------------------------------------------------------------------
// PROPERTY CARD
// ---------------------------------------------------------------------------
class _PropertyCard extends StatelessWidget {
  final PropertyEntity property;
  final VoidCallback onTap;
  const _PropertyCard({required this.property, required this.onTap});

  PropertyStatus get _status {
    if (property.isSponsored) return PropertyStatus.sponsored;
    if (property.listingStatus == ListingStatus.inactive || property.listingStatus == ListingStatus.expired) {
      return PropertyStatus.archived;
    }
    if (property.listingType == ListingType.forSale) return PropertyStatus.forSale;
    return PropertyStatus.forRent;
  }

  @override
  Widget build(BuildContext context) {
    final status = _status;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.horizontal(left: Radius.circular(14)),
                  child: SizedBox(
                    width: 120,
                    height: 130,
                    child: property.images.isNotEmpty
                        ? Image.network(property.images.first, fit: BoxFit.cover)
                        : Container(color: AppColors.surfaceLight, child: const Icon(Icons.home, color: AppColors.textHint)),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(property.propertyName,
                            maxLines: 1, overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                        const SizedBox(height: 4),
                        Text(property.location,
                            maxLines: 1, overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 12, color: AppColors.textSecondary.withValues(alpha: 0.7))),
                        const SizedBox(height: 8),
                        Text('EGP ${property.priceValue.toStringAsFixed(0)}${property.pricingUnitSuffix}',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.navyBlue)),
                        const SizedBox(height: 6),
                        _StatusChip(status: status),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 10, right: 10),
                  child: Icon(Icons.chevron_right, color: AppColors.textHint.withValues(alpha: 0.5), size: 20),
                ),
              ],
            ),
            const Divider(height: 1, color: AppColors.borderLight),
            _ActionRow(property: property, status: status),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// STATUS CHIP
// ---------------------------------------------------------------------------
class _StatusChip extends StatelessWidget {
  final PropertyStatus status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: status.color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: status.color.withValues(alpha: 0.2)),
      ),
      child: Text(status.label,
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: status.color)),
    );
  }
}

// ---------------------------------------------------------------------------
// ACTION ROW
// ---------------------------------------------------------------------------
class _ActionRow extends StatelessWidget {
  final PropertyEntity property;
  final PropertyStatus status;
  const _ActionRow({required this.property, required this.status});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          _ActionButton(
            icon: Icons.auto_awesome,
            label: 'Sponsor',
            color: AppColors.primary,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => SelectSellingPlanPage(propertyId: property.propertyId)),
            ),
          ),
          const SizedBox(width: 8),
          _ActionButton(
            icon: Icons.edit_outlined,
            label: 'Edit',
            color: AppColors.navyBlue,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => EditPropertyPage(property: property)),
            ),
          ),
          const SizedBox(width: 8),
          _ActionButton(
            icon: Icons.delete_outline,
            label: 'Delete',
            color: AppColors.error,
            onTap: () => _confirmDelete(context),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Property'),
        content: Text('Are you sure you want to delete "${property.propertyName}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _deleteProperty(context);
            },
            child: Text('Delete', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _deleteProperty(BuildContext context) {
    context.read<PropertyBloc>().add(DeletePropertyRequested(id: property.propertyId));
  }
}

// ---------------------------------------------------------------------------
// ACTION BUTTON
// ---------------------------------------------------------------------------
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ActionButton({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(height: 2),
              Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color)),
            ],
          ),
        ),
      ),
    );
  }
}
