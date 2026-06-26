import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:aqar/core/theme/app_colors.dart';
import 'package:aqar/core/widgets/aqar_button.dart';
import 'package:aqar/core/widgets/aqar_text_field.dart';
import 'package:aqar/features/property/domain/entities/property_entity.dart';
import 'package:aqar/features/property/domain/entities/property_enums.dart';
import 'package:aqar/features/property/presentation/bloc/property_bloc.dart';
import 'package:aqar/features/property/presentation/bloc/property_event.dart';
import 'package:aqar/features/property/presentation/bloc/property_state.dart';


class EditPropertyPage extends StatefulWidget {
  final PropertyEntity property;
  const EditPropertyPage({super.key, required this.property});

  @override
  State<EditPropertyPage> createState() => _EditPropertyPageState();
}

class _EditPropertyPageState extends State<EditPropertyPage> {
  late TextEditingController _nameController;
  late TextEditingController _descController;
  late TextEditingController _locationController;
  late TextEditingController _priceController;
  ListingStatus? _pendingAction;
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final p = widget.property;
    _nameController = TextEditingController(text: p.propertyName);
    _descController = TextEditingController(text: p.propertyDesc);
    _locationController = TextEditingController(text: p.location);
    _priceController = TextEditingController(
      text: p.priceValue.toStringAsFixed(0),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _locationController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final data = <String, dynamic>{
      'propertyName': _nameController.text.trim(),
      'propertyDesc': _descController.text.trim(),
      'location': _locationController.text.trim(),
      'pricePerDay': double.tryParse(_priceController.text.trim()) ?? 0,
    };

    if (_pendingAction != null) {
      data['listingStatus'] = _pendingAction!.value;
    }

    setState(() => _isSaving = true);
    context.read<PropertyBloc>().add(EditPropertyRequested(id: widget.property.propertyId, data: data));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Edit Property',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: true,
      ),
      body: BlocListener<PropertyBloc, PropertyState>(
        listener: (context, state) {
          if (state is PropertyOperationSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: AppColors.success),
            );
            Navigator.pop(context, true);
          } else if (state is PropertyLoading) {
            setState(() => _isSaving = true);
          } else if (state is PropertyError) {
            setState(() => _isSaving = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: AppColors.error),
            );
          }
        },
        child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('Property Name'),
              const SizedBox(height: 8),
              AqarTextField(
                label: 'Name',
                hint: 'Enter property name',
                controller: _nameController,
                prefixIcon: const Icon(Icons.home),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Name is required' : null,
              ),
              const SizedBox(height: 20),
              _buildSectionTitle('Description'),
              const SizedBox(height: 8),
              AqarTextField(
                label: 'Description',
                hint: 'Enter property description',
                controller: _descController,
                prefixIcon: const Icon(Icons.description),
                maxLines: 4,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Description is required' : null,
              ),
              const SizedBox(height: 20),
              _buildSectionTitle('Location'),
              const SizedBox(height: 8),
              AqarTextField(
                label: 'Location',
                hint: 'Enter location',
                controller: _locationController,
                prefixIcon: const Icon(Icons.location_on),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Location is required' : null,
              ),
              const SizedBox(height: 20),
              _buildSectionTitle('Price'),
              const SizedBox(height: 8),
              AqarTextField(
                label: 'Price',
                hint: 'Enter price',
                controller: _priceController,
                keyboardType: TextInputType.number,
                prefixIcon: const Icon(Icons.attach_money),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Price is required';
                  if (double.tryParse(v.trim()) == null) return 'Enter a valid price';
                  return null;
                },
              ),
              const SizedBox(height: 24),
              _buildSectionTitle('Property Type'),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: Row(
                  children: [
                    Icon(Icons.lock_outline, size: 18, color: AppColors.textHint),
                    const SizedBox(width: 10),
                    Text(
                      widget.property.listingType.label,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'Locked',
                        style: TextStyle(fontSize: 10, color: AppColors.primary, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _buildSectionTitle('Listing Status'),
              const SizedBox(height: 8),
              _buildStatusSection(),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: AqarButton(
                  text: _isSaving ? 'Saving...' : 'Save Changes',
                  onPressed: _isSaving ? null : _save,
                ),
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: AppColors.textHint,
        letterSpacing: 1,
      ),
    );
  }

  Widget _buildStatusSection() {
    final current = widget.property.listingStatus ?? ListingStatus.inactive;
    final isSale = widget.property.listingType == ListingType.forSale;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatusChip(current, isSale),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildActionButton(ListingStatus.active, isSale),
              const SizedBox(width: 8),
              _buildActionButton(ListingStatus.sold, isSale),
              const SizedBox(width: 8),
              _buildActionButton(ListingStatus.inactive, isSale),
            ],
          ),
          if (_pendingAction != null) ...[
            const SizedBox(height: 12),
            Text(
              'Status will change to "${_labelFor(_pendingAction!, isSale)}" on save.',
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textHint,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusChip(ListingStatus status, bool isSale) {
    final label = _labelFor(status, isSale);
    final color = _colorFor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8, height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(ListingStatus target, bool isSale) {
    final current = widget.property.listingStatus;
    final isCurrent = target == current;
    final isSelected = _pendingAction == target;
    final label = _labelFor(target, isSale);
    final color = _colorFor(target);
    final icon = _iconFor(target);

    return Expanded(
      child: GestureDetector(
        onTap: isCurrent
            ? null
            : () {
                setState(() {
                  _pendingAction = isSelected ? null : target;
                });
              },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
          decoration: BoxDecoration(
            color: isSelected
                ? color
                : isCurrent
                    ? color.withValues(alpha: 0.08)
                    : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? color
                  : isCurrent
                      ? color.withValues(alpha: 0.2)
                      : color.withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 22,
                color: isSelected
                    ? Colors.white
                    : isCurrent
                        ? color.withValues(alpha: 0.4)
                        : color,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: isSelected
                      ? Colors.white
                      : isCurrent
                          ? color.withValues(alpha: 0.4)
                          : color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _labelFor(ListingStatus status, bool isSale) {
    switch (status) {
      case ListingStatus.active:
        return 'Active';
      case ListingStatus.sold:
        return isSale ? 'Sold' : 'Rented';
      case ListingStatus.inactive:
        return 'Inactive';
      default:
        return status.label;
    }
  }

  Color _colorFor(ListingStatus status) {
    switch (status) {
      case ListingStatus.active:
        return AppColors.success;
      case ListingStatus.sold:
        return AppColors.error;
      case ListingStatus.inactive:
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  IconData _iconFor(ListingStatus status) {
    switch (status) {
      case ListingStatus.active:
        return Icons.check_circle_outline;
      case ListingStatus.sold:
        return Icons.cancel_outlined;
      case ListingStatus.inactive:
        return Icons.archive_outlined;
      default:
        return Icons.help_outline;
    }
  }
}


