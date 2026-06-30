import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:aqar/core/theme/app_colors.dart';
import 'package:aqar/core/widgets/aqar_button.dart';
import 'package:aqar/core/widgets/aqar_text_field.dart';
import 'package:aqar/core/widgets/image_picker_grid.dart';
import 'package:aqar/features/map/presentation/pages/map_picker_page.dart';
import 'package:aqar/features/property/domain/entities/property_enums.dart';
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
  late TextEditingController _sizeController;
  late TextEditingController _bedroomsController;
  late TextEditingController _bedsController;
  late TextEditingController _bathroomsController;

  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;
  bool _pendingImagesSave = false;
  bool _isFurnished = false;
  PricingUnit _pricingUnit = PricingUnit.month;

  double? _lat;
  double? _lng;
  String _resolvedAddress = '';

  List<PickedImage> _newImages = [];
  XFile? _newOwnershipProof;

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
    _sizeController = TextEditingController(text: p.size);
    _bedroomsController = TextEditingController(
      text: p.bedroomsNo > 0 ? p.bedroomsNo.toString() : '',
    );
    _bedsController = TextEditingController(
      text: p.bedsNo > 0 ? p.bedsNo.toString() : '',
    );
    _bathroomsController = TextEditingController(
      text: p.bathroomsNo > 0 ? p.bathroomsNo.toString() : '',
    );
    _lat = p.latitude;
    _lng = p.longitude;
    _resolvedAddress = p.location;
    _isFurnished = p.isFurnished;
    _pricingUnit = p.pricingUnit;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _locationController.dispose();
    _priceController.dispose();
    _sizeController.dispose();
    _bedroomsController.dispose();
    _bedsController.dispose();
    _bathroomsController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final data = <String, dynamic>{
      'propertyName': _nameController.text.trim(),
      'propertyDesc': _descController.text.trim(),
      'location': _locationController.text.trim(),
      'pricePerDay': double.tryParse(_priceController.text.trim()) ?? 0,
      'size': _sizeController.text.trim(),
      'bedroomsNumber': _bedroomsController.text.trim().isEmpty
          ? '0'
          : _bedroomsController.text.trim(),
      'bedsNumber': _bedsController.text.trim().isEmpty
          ? '0'
          : _bedsController.text.trim(),
      'bathroomsNumber': _bathroomsController.text.trim().isEmpty
          ? '0'
          : _bathroomsController.text.trim(),
    };
    if (_lat != null && _lng != null) {
      data['latitude'] = _lat!.toStringAsFixed(6);
      data['longitude'] = _lng!.toStringAsFixed(6);
    }

    final hasNewImages =
        _newImages.isNotEmpty || _newOwnershipProof != null;
    setState(() {
      _isSaving = true;
      _pendingImagesSave = hasNewImages;
    });
    context.read<PropertyBloc>().add(
          EditPropertyRequested(id: widget.property.propertyId, data: data),
        );
  }

  Future<void> _saveImages() async {
    final formData = FormData.fromMap({});
    for (final p in _newImages) {
      final bytes = await p.file.readAsBytes();
      final rawName = p.file.path.split(RegExp(r'[/\\]')).last;
      formData.files.add(MapEntry(
        'images',
        MultipartFile.fromBytes(bytes, filename: rawName),
      ));
    }
    if (_newOwnershipProof != null) {
      final bytes = await _newOwnershipProof!.readAsBytes();
      final rawName =
          _newOwnershipProof!.path.split(RegExp(r'[/\\]')).last;
      formData.files.add(MapEntry(
        'ownershipProof',
        MultipartFile.fromBytes(bytes, filename: rawName),
      ));
    }
    if (!mounted) return;
    context.read<PropertyBloc>().add(
          EditPropertyImagesRequested(
            id: widget.property.propertyId,
            formData: formData,
          ),
        );
  }

  Future<void> _pickMapLocation() async {
    final result = await Navigator.push<MapPickerResult>(
      context,
      MaterialPageRoute(
        builder: (_) => MapPickerPage(
          initialLat: _lat,
          initialLng: _lng,
          initialAddress: _resolvedAddress,
        ),
      ),
    );
    if (result != null && mounted) {
      setState(() {
        _lat = result.lat;
        _lng = result.lng;
        _resolvedAddress = result.address;
        _locationController.text = result.address;
      });
    }
  }

  Future<void> _pickOwnershipDoc() async {
    final files = await ImagePicker().pickMultiImage();
    if (files.isNotEmpty && mounted) {
      setState(() => _newOwnershipProof = files.first);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
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
            if (_pendingImagesSave) {
              setState(() => _pendingImagesSave = false);
              _saveImages();
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: AppColors.success,
                ),
              );
              Navigator.pop(context, true);
            }
          } else if (state is PropertyLoading) {
            setState(() => _isSaving = true);
          } else if (state is PropertyError) {
            setState(() => _isSaving = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
              ),
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
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'Name is required'
                      : null,
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
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'Description is required'
                      : null,
                ),
                const SizedBox(height: 20),
                _buildSectionTitle('Location'),
                const SizedBox(height: 8),
                _buildLocationRow(),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _buildPriceSection(),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildSizeSection(),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _buildSectionTitle('Rooms'),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildNumericField(
                        controller: _bedroomsController,
                        label: 'Bedrooms',
                        icon: Icons.bed,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildNumericField(
                        controller: _bedsController,
                        label: 'Beds',
                        icon: Icons.single_bed,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildNumericField(
                        controller: _bathroomsController,
                        label: 'Bathrooms',
                        icon: Icons.bathroom,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _buildSectionTitle('Location Coordinates'),
                const SizedBox(height: 8),
                _buildMapPickerTile(),
                const SizedBox(height: 20),
                _buildSectionTitle('Property Images'),
                const SizedBox(height: 8),
                _buildExistingImages(),
                const SizedBox(height: 16),
                ImagePickerGrid(
                  images: _newImages,
                  maxImages: 10,
                  title: 'Add New Images',
                  onChanged: (v) => setState(() => _newImages = v),
                ),
                const SizedBox(height: 20),
                _buildSectionTitle('Ownership Proof'),
                const SizedBox(height: 8),
                _buildOwnershipProofSection(),
                const SizedBox(height: 20),
                _buildSectionTitle('Property Type'),
                const SizedBox(height: 8),
                _buildPropertyTypeTile(),
                const SizedBox(height: 16),
                _buildSectionTitle('Furnished'),
                const SizedBox(height: 8),
                _buildFurnishedToggle(),
                if (widget.property.listingType == ListingType.forRent) ...[
                  const SizedBox(height: 20),
                  _buildSectionTitle('Pricing Unit'),
                  const SizedBox(height: 8),
                  _buildPricingUnitToggle(),
                ],
                if (!widget.property.isVerified) ...[
                  const SizedBox(height: 20),
                  _buildReviewWarning(),
                ],
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: AqarButton(
                    text: _isSaving ? 'Saving...' : 'Save Changes',
                    onPressed: _isSaving ? null : _save,
                  ),
                ),
                const SizedBox(height: 16),
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
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: AppColors.textHint,
        letterSpacing: 1,
      ),
    );
  }

  Widget _buildLocationRow() {
    return Row(
      children: [
        Expanded(
          child: AbsorbPointer(
            child: AqarTextField(
              label: 'Address',
              hint: 'Address from map',
              controller: _locationController,
              prefixIcon: const Icon(Icons.location_on),
            ),
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          height: 56,
          child: ElevatedButton(
            onPressed: _pickMapLocation,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            child: const Icon(Icons.map, size: 22),
          ),
        ),
      ],
    );
  }

  Widget _buildPriceSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Price'),
        const SizedBox(height: 8),
        AqarTextField(
          label: 'Price',
          hint: '0',
          controller: _priceController,
          keyboardType: TextInputType.number,
          prefixIcon: const Icon(Icons.attach_money),
          validator: (v) {
            if (v == null || v.trim().isEmpty) return 'Required';
            if (double.tryParse(v.trim()) == null) return 'Invalid';
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildSizeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Size (m\u00B2)'),
        const SizedBox(height: 8),
        AqarTextField(
          label: 'Size',
          hint: '0',
          controller: _sizeController,
          keyboardType: TextInputType.number,
          prefixIcon: const Icon(Icons.square_foot),
          validator: (v) {
            if (v == null || v.trim().isEmpty) return 'Required';
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildNumericField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 4),
          Row(
            children: [
              Icon(icon, size: 16, color: AppColors.textHint),
              SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textHint,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          TextFormField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(vertical: 8),
              isDense: true,
            ),
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapPickerTile() {
    final hasCoords = _lat != null && _lng != null;
    return GestureDetector(
      onTap: _pickMapLocation,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: hasCoords
              ? AppColors.success.withValues(alpha: 0.06)
              : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasCoords
                ? AppColors.success.withValues(alpha: 0.2)
                : AppColors.borderLight,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: hasCoords
                    ? AppColors.success.withValues(alpha: 0.12)
                    : AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                hasCoords ? Icons.check_circle : Icons.map_outlined,
                color: hasCoords ? AppColors.success : AppColors.primary,
                size: 22,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hasCoords ? 'Location Set' : 'Set Location on Map',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (hasCoords)
                    Text(
                      '${_lat!.toStringAsFixed(4)}, ${_lng!.toStringAsFixed(4)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  if (!hasCoords)
                    Text(
                      'Tap to open map picker',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textHint,
                      ),
                    ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: AppColors.textHint),
          ],
        ),
      ),
    );
  }

  Widget _buildExistingImages() {
    if (widget.property.images.isEmpty) {
      return Padding(
        padding: EdgeInsets.only(bottom: 8),
        child: Text(
          'No existing images',
          style: TextStyle(fontSize: 13, color: AppColors.textHint),
        ),
      );
    }
    return SizedBox(
      height: 80,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: widget.property.images.length,
        separatorBuilder: (_, __) => SizedBox(width: 8),
        itemBuilder: (_, i) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 80,
              height: 80,
              child: Image.network(
                widget.property.images[i],
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: AppColors.surfaceLight,
                  child: Icon(Icons.broken_image,
                      color: AppColors.textHint),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildOwnershipProofSection() {
    final hasExisting = widget.property.ownershipProofs.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasExisting) ...[
          SizedBox(
            height: 80,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: widget.property.ownershipProofs.length,
              separatorBuilder: (_, __) => SizedBox(width: 8),
              itemBuilder: (_, i) {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    width: 80,
                    height: 80,
                    child: Image.network(
                      widget.property.ownershipProofs[i],
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: AppColors.surfaceLight,
                        child: Icon(Icons.description_outlined,
                            color: AppColors.textHint),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          SizedBox(height: 8),
        ],
        if (_newOwnershipProof != null)
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 80,
                  height: 80,
                  child: Image.file(
                    File(_newOwnershipProof!.path),
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: AppColors.surfaceLight,
                      child: Icon(Icons.description_outlined,
                          color: AppColors.textHint),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 2,
                right: 2,
                child: GestureDetector(
                  onTap: () => setState(() => _newOwnershipProof = null),
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.error,
                    ),
                    child: const Icon(Icons.close,
                        color: Colors.white, size: 14),
                  ),
                ),
              ),
            ],
          ),
        if (_newOwnershipProof == null)
          TextButton.icon(
            onPressed: _pickOwnershipDoc,
            icon: const Icon(Icons.upload_file, size: 18),
            label: Text(
              hasExisting ? 'Replace Document' : 'Upload Document',
            ),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(
                    color: AppColors.primary.withValues(alpha: 0.3)),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPropertyTypeTile() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        children: [
          Icon(Icons.lock_outline,
              size: 18, color: AppColors.textHint),
          const SizedBox(width: 10),
          Text(
            widget.property.listingType.label,
            style: const TextStyle(
                fontSize: 15, fontWeight: FontWeight.w600),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text(
              'Locked',
              style: TextStyle(
                fontSize: 10,
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFurnishedToggle() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        children: [
          Icon(
            _isFurnished ? Icons.king_bed : Icons.king_bed_outlined,
            size: 20,
            color:
                _isFurnished ? AppColors.primary : AppColors.textHint,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _isFurnished ? 'Furnished' : 'Not Furnished',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFFFFA000).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text(
              'Blocked',
              style: TextStyle(
                fontSize: 9,
                color: Color(0xFFFFA000),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Switch(
            value: _isFurnished,
            onChanged: (v) => setState(() => _isFurnished = v),
            activeThumbColor: AppColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildPricingUnitToggle() {
    return Container(
      width: double.infinity,
      padding:
          EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        children: [
          Icon(
            _pricingUnit == PricingUnit.month
                ? Icons.calendar_month
                : Icons.today,
            size: 20,
            color: AppColors.primary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _pricingUnit.label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFFFFA000).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text(
              'Blocked',
              style: TextStyle(
                fontSize: 9,
                color: Color(0xFFFFA000),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
          SegmentedButton<PricingUnit>(
            segments: const [
              ButtonSegment(
                value: PricingUnit.day,
                label: Text('Day',
                    style: TextStyle(fontSize: 12)),
              ),
              ButtonSegment(
                value: PricingUnit.month,
                label: Text('Month',
                    style: TextStyle(fontSize: 12)),
              ),
            ],
            selected: {_pricingUnit},
            onSelectionChanged: (v) =>
                setState(() => _pricingUnit = v.first),
            style: ButtonStyle(
              visualDensity: VisualDensity.compact,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewWarning() {
    return Container(
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
    );
  }
}
