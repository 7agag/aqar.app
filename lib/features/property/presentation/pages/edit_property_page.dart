import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:aqar/core/theme/app_colors.dart';
import 'package:aqar/core/widgets/aqar_button.dart';
import 'package:aqar/core/widgets/aqar_text_field.dart';
import 'package:aqar/features/property/domain/entities/property_entity.dart';
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
              if (!widget.property.isVerified) ...[
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFA000).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: const Color(0xFFFFA000).withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline,
                          size: 20, color: Color(0xFFFFA000)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Changes will trigger a new admin review.',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF8B6914),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 32),
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
}

