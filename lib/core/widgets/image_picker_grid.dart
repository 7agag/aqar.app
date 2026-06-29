import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:aqar/core/theme/app_colors.dart';
import 'package:aqar/core/theme/app_spacing.dart';

class PickedImage {
  final XFile file;
  final String? url;

  const PickedImage({required this.file, this.url});
}

class ImagePickerGrid extends StatelessWidget {
  final List<PickedImage> images;
  final int maxImages;
  final String title;
  final ValueChanged<List<PickedImage>> onChanged;

  const ImagePickerGrid({
    super.key,
    required this.images,
    this.maxImages = 10,
    this.title = 'Images',
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$title (${images.length}/$maxImages)',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.textHint,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: images.length + (images.length < maxImages ? 1 : 0),
            itemBuilder: (_, i) {
              if (i < images.length) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _ImageThumb(
                    image: images[i],
                    onDelete: () {
                      final updated = [...images];
                      updated.removeAt(i);
                      onChanged(updated);
                    },
                  ),
                );
              }
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _AddImageButton(
                  onTap: () => _showSourceSheet(context),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showSourceSheet(BuildContext context) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textHint.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Add Photo',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: _sourceOption(
                      icon: Icons.camera_alt_outlined,
                      label: 'Camera',
                      subtitle: 'Take a photo now',
                      onTap: () {
                        Navigator.pop(ctx);
                        _pickFromCamera();
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _sourceOption(
                      icon: Icons.photo_library_outlined,
                      label: 'Gallery',
                      subtitle: 'Choose from library',
                      onTap: () {
                        Navigator.pop(ctx);
                        _pickFromGallery();
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickFromCamera() async {
    final file = await ImagePicker().pickImage(source: ImageSource.camera);
    if (file != null && images.length < maxImages) {
      onChanged([...images, PickedImage(file: file)]);
    }
  }

  Future<void> _pickFromGallery() async {
    final files = await ImagePicker().pickMultiImage();
    if (files.isNotEmpty) {
      final updated = [...images];
      for (final f in files) {
        if (updated.length < maxImages) {
          updated.add(PickedImage(file: f));
        }
      }
      onChanged(updated);
    }
  }

  Widget _sourceOption({
    required IconData icon,
    required String label,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Column(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.primary, size: 26),
            ),
            const SizedBox(height: 10),
            Text(label,
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 2),
            Text(subtitle,
                style: const TextStyle(
                    fontSize: 11, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}

class _ImageThumb extends StatelessWidget {
  final PickedImage image;
  final VoidCallback onDelete;

  const _ImageThumb({required this.image, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          child: SizedBox(
            width: 90,
            height: 90,
            child: image.url != null
                ? Image.network(image.url!, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(Icons.broken_image))
                : kIsWeb
                    ? _PickedImageTile(file: image.file)
                    : Image.file(File(image.file.path), fit: BoxFit.cover),
          ),
        ),
        Positioned(
          top: 2,
          right: 2,
          child: GestureDetector(
            onTap: onDelete,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                  shape: BoxShape.circle, color: AppColors.error),
              child: const Icon(Icons.close, color: Colors.white, size: 14),
            ),
          ),
        ),
      ],
    );
  }
}

class _AddImageButton extends StatelessWidget {
  final VoidCallback onTap;

  const _AddImageButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 90,
        height: 90,
        decoration: BoxDecoration(
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.4),
            width: 1.5,
            strokeAlign: BorderSide.strokeAlignInside,
          ),
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          color: AppColors.primary.withValues(alpha: 0.05),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_photo_alternate_outlined,
                color: AppColors.primary, size: 28),
            SizedBox(height: 2),
            Text('Add',
                style: TextStyle(
                    fontSize: 11,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class _PickedImageTile extends StatefulWidget {
  final XFile file;
  const _PickedImageTile({required this.file});

  @override
  State<_PickedImageTile> createState() => _PickedImageTileState();
}

class _PickedImageTileState extends State<_PickedImageTile> {
  Uint8List? _bytes;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final bytes = await widget.file.readAsBytes();
      if (mounted) setState(() => _bytes = bytes);
    } catch (_) {
      if (mounted) setState(() => _hasError = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return Container(
        color: AppColors.surfaceLight,
        child:
            const Icon(Icons.broken_image_outlined, color: AppColors.textHint),
      );
    }
    if (_bytes == null) {
      return const Center(
          child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2)));
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      child: Image.memory(_bytes!, fit: BoxFit.cover),
    );
  }
}
