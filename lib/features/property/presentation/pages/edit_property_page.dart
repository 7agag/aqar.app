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
import 'package:aqar/features/payment/presentation/pages/payment_gateway_page.dart';

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
  late PropertyStatus _status;
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;

  final _statusOptions = <PropertyStatus>[
    PropertyStatus.forRent,
    PropertyStatus.archived,
    PropertyStatus.forSale,
  ];

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
    _status = p.listingStatus == ListingStatus.inactive
        ? PropertyStatus.archived
        : p.listingStatus == ListingStatus.sold
            ? PropertyStatus.forSale
            : PropertyStatus.forRent;
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

    final oldListStatus = widget.property.listingStatus;
    if (_status == PropertyStatus.forSale && oldListStatus != ListingStatus.sold) {
      data['listingStatus'] = 'sold';
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
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.borderLight),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: DropdownButtonFormField<PropertyStatus>(
                  initialValue: _status,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                  items: _statusOptions.map((s) {
                    return DropdownMenuItem(
                      value: s,
                      child: Row(
                        children: [
                          Container(
                            width: 10, height: 10,
                            decoration: BoxDecoration(
                              color: s.color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(s.label),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => _status = v);
                  },
                ),
              ),
              if (widget.property.listingType == ListingType.forSale &&
                  !widget.property.isSponsored) ...[
                const SizedBox(height: 32),
                _buildSectionTitle('Sponsor this Property'),
                const SizedBox(height: 12),
                _SponsorPlanCard(
                  months: 1,
                  fee: 120,
                  onSelect: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const PaymentGatewayPage(
                        itemName: '1 Month Sale Plan',
                        amount: 120,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                _SponsorPlanCard(
                  months: 3,
                  fee: 360,
                  onSelect: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const PaymentGatewayPage(
                        itemName: '3 Month Sale Plan',
                        amount: 360,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                _SponsorPlanCard(
                  months: 6,
                  fee: 600,
                  onSelect: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const PaymentGatewayPage(
                        itemName: '6 Month Sale Plan',
                        amount: 600,
                      ),
                    ),
                  ),
                ),
              ],
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
}

class _SponsorPlanCard extends StatelessWidget {
  final int months;
  final int fee;
  final VoidCallback onSelect;

  const _SponsorPlanCard({
    required this.months,
    required this.fee,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onSelect,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.navyBlue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.star, color: AppColors.navyBlue, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$months Month${months > 1 ? 's' : ''}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'EGP $fee',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textHint,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textHint),
          ],
        ),
      ),
    );
  }
}
