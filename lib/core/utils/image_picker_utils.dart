import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:fe_moblie_flutter/core/theme/app_colors.dart';

/// Chọn ảnh từ camera hoặc thư viện (bottom sheet).
Future<XFile?> pickImageFromCameraOrGallery(
  BuildContext context, {
  double? maxWidth,
  double? maxHeight,
  int imageQuality = 85,
}) async {
  final source = await showModalBottomSheet<ImageSource>(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined, color: AppColors.primary),
              title: const Text('Chụp ảnh'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined, color: AppColors.primary),
              title: const Text('Chọn từ thư viện'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
          ],
        ),
      );
    },
  );

  if (source == null || !context.mounted) return null;

  try {
    return await ImagePicker().pickImage(
      source: source,
      maxWidth: maxWidth,
      maxHeight: maxHeight,
      imageQuality: imageQuality,
    );
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không chọn được ảnh: $e')),
      );
    }
    return null;
  }
}
