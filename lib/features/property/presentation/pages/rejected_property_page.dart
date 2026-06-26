import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:aqar/core/network/api_client.dart';
import 'package:aqar/core/theme/app_colors.dart';
import 'package:aqar/injection_container.dart' as di;

class RejectionSheet {
  static Future<void> show(
    BuildContext context, {
    required int propertyId,
    required String rejectionReason,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _RejectionSheetBody(
        propertyId: propertyId,
        rejectionReason: rejectionReason,
      ),
    );
  }
}

class _RejectionSheetBody extends StatefulWidget {
  final int propertyId;
  final String rejectionReason;

  const _RejectionSheetBody({
    required this.propertyId,
    required this.rejectionReason,
  });

  @override
  State<_RejectionSheetBody> createState() => _RejectionSheetBodyState();
}

class _RejectionSheetBodyState extends State<_RejectionSheetBody> {
  XFile? _ownershipDoc;
  XFile? _billDoc;
  bool _isSubmitting = false;
  bool _isSubmitted = false;

  Future<void> _pickOwnership() async {
    final file = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (file != null) setState(() => _ownershipDoc = file);
  }

  Future<void> _pickBill() async {
    final file = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (file != null) setState(() => _billDoc = file);
  }

  Future<void> _submit() async {
    if (_ownershipDoc == null || _billDoc == null) return;
    setState(() => _isSubmitting = true);
    try {
      final formData = FormData();
      for (final doc in [_ownershipDoc!, _billDoc!]) {
        final bytes = await doc.readAsBytes();
        final name = doc.path.split(RegExp(r'[/\\]')).last;
        final mime = _detectMime(bytes);
        formData.files.add(MapEntry(
          'ownershipProof',
          MultipartFile.fromBytes(
            bytes,
            filename: mime != null && !name.contains('.')
                ? '$name.${mime.subtype.replaceAll('jpeg', 'jpg')}'
                : name,
            contentType: mime,
          ),
        ));
      }
      await di.sl<ApiClient>().dio.put(
            '/property/${widget.propertyId}/images',
            data: formData,
          );
      if (!mounted) return;
      setState(() {
        _isSubmitted = true;
        _isSubmitting = false;
      });
      await Future<void>.delayed(const Duration(seconds: 2));
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _isSubmitted = false;
        });
        final msg = e is DioException
            ? (e.response?.data is Map
                    ? (e.response!.data as Map)['msg']?.toString()
                    : null) ??
                (e.message ?? 'Upload failed')
            : e.toString();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  DioMediaType? _detectMime(Uint8List bytes) {
    if (bytes.length >= 2 && bytes[0] == 0xFF && bytes[1] == 0xD8) {
      return DioMediaType('image', 'jpeg');
    }
    if (bytes.length >= 8 &&
        bytes[0] == 0x89 && bytes[1] == 0x50 &&
        bytes[2] == 0x4E && bytes[3] == 0x47 &&
        bytes[4] == 0x0D && bytes[5] == 0x0A &&
        bytes[6] == 0x1A && bytes[7] == 0x0A) {
      return DioMediaType('image', 'png');
    }
    if (bytes.length >= 12 &&
        bytes[0] == 0x52 && bytes[1] == 0x49 &&
        bytes[2] == 0x46 && bytes[3] == 0x46 &&
        bytes[8] == 0x57 && bytes[9] == 0x45 &&
        bytes[10] == 0x45 && bytes[11] == 0x42) {
      return DioMediaType('image', 'webp');
    }
    if (bytes.length >= 4 &&
        bytes[0] == 0x25 && bytes[1] == 0x50 &&
        bytes[2] == 0x44 && bytes[3] == 0x46) {
      return DioMediaType('application', 'pdf');
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return PopScope(
      canPop: !_isSubmitting,
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottomInset),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHandle(),
            const SizedBox(height: 20),
            if (_isSubmitted)
              _buildSubmittedState()
            else
              _buildForm(),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildHandle() {
    return Container(
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: AppColors.borderLight,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildForm() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: AppColors.error.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.shield_outlined,
            color: AppColors.error,
            size: 28,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Verification Declined',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.error.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.error.withValues(alpha: 0.15),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.format_quote,
                size: 16,
                color: AppColors.error.withValues(alpha: 0.5),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.rejectionReason,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary.withValues(alpha: 0.9),
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _buildTopic(),
        const SizedBox(height: 20),
        _buildDocUploader(
          label: 'Ownership Document',
          icon: Icons.description_outlined,
          file: _ownershipDoc,
          onPick: _pickOwnership,
          onClear: () => setState(() => _ownershipDoc = null),
        ),
        const SizedBox(height: 12),
        _buildDocUploader(
          label: 'Utility Bill',
          icon: Icons.receipt_outlined,
          file: _billDoc,
          onPick: _pickBill,
          onClear: () => setState(() => _billDoc = null),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _ownershipDoc != null &&
                    _billDoc != null &&
                    !_isSubmitting
                ? _submit
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.navyBlue,
              foregroundColor: Colors.white,
              disabledBackgroundColor: AppColors.navyBlue.withValues(alpha: 0.4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
            ),
            child: _isSubmitting
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'Submit for Recheck',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  ({IconData icon, String label, String tip}) _getTopic() {
    return (
      icon: Icons.info_outline,
      label: 'Owner Recheck',
      tip:
          'Your property was rejected due to invalid data. '
          'Please correct the information and upload the required '
          'documents for re-verification.',
    );
  }

  Widget _buildTopic() {
    final topic = _getTopic();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(topic.icon, size: 16, color: AppColors.navyBlue),
            const SizedBox(width: 6),
            Text(topic.label,
                style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: AppColors.textPrimary)),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.lightbulb_outline,
                size: 14, color: AppColors.textHint),
            const SizedBox(width: 6),
            Expanded(
              child: Text(topic.tip,
                  style: TextStyle(
                      fontSize: 12,
                      color:
                          AppColors.textSecondary.withValues(alpha: 0.8))),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDocUploader({
    required String label,
    required IconData icon,
    required XFile? file,
    required VoidCallback onPick,
    required VoidCallback onClear,
  }) {
    return GestureDetector(
      onTap: onPick,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: file != null
              ? AppColors.success.withValues(alpha: 0.05)
              : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: file != null
                ? AppColors.success.withValues(alpha: 0.4)
                : AppColors.borderLight,
            width: 1.5,
          ),
        ),
        child: file != null
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 18, color: AppColors.success),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      file.name,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.success,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: onClear,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        size: 14,
                        color: AppColors.error,
                      ),
                    ),
                  ),
                ],
              )
            : Column(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.navyBlue.withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      icon,
                      color: AppColors.navyBlue,
                      size: 22,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'PDF, JPG or PNG accepted',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textHint.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildSubmittedState() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check_circle,
            color: AppColors.success,
            size: 36,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Submitted for Review!',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Your document has been uploaded.\nYou\'ll be notified once reviewed.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            color: AppColors.textSecondary.withValues(alpha: 0.8),
            height: 1.4,
          ),
        ),
        const SizedBox(height: 8),
        const SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.success,
          ),
        ),
      ],
    );
  }
}
