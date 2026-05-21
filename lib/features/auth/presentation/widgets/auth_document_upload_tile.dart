import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:fe_moblie_flutter/core/theme/app_colors.dart';
import 'package:fe_moblie_flutter/core/widgets/app_network_image.dart';

/// Ô upload ảnh giấy tờ (Figma: khung xám + icon camera).
class AuthDocumentUploadTile extends StatelessWidget {
  const AuthDocumentUploadTile({
    super.key,
    required this.label,
    required this.hint,
    required this.file,
    required this.onChanged,
    this.required = true,
    this.existingImageUrl,
    this.onViewExisting,
  });

  final String label;
  final String hint;
  final bool required;
  final XFile? file;
  final ValueChanged<XFile?> onChanged;
  /// Ảnh đã lưu trên server (hiển thị preview nếu chưa chọn ảnh mới).
  final String? existingImageUrl;
  final VoidCallback? onViewExisting;

  Future<void> _pick(BuildContext context) async {
    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1600,
        imageQuality: 85,
      );
      onChanged(picked);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không chọn được ảnh: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        RichText(
          text: TextSpan(
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
            children: [
              TextSpan(text: label),
              if (required)
                const TextSpan(
                  text: ' *',
                  style: TextStyle(color: AppColors.primary),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () {
            if (file == null &&
                existingImageUrl != null &&
                existingImageUrl!.isNotEmpty &&
                onViewExisting != null) {
              onViewExisting!();
            } else {
              _pick(context);
            }
          },
          onLongPress: () => _pick(context),
          child: Container(
            height: 120,
            decoration: BoxDecoration(
              color: const Color(0xFFE8EAED),
              borderRadius: BorderRadius.circular(12),
            ),
            child: _buildPreview(),
          ),
        ),
        if (existingImageUrl != null &&
            existingImageUrl!.isNotEmpty &&
            file == null) ...[
          const SizedBox(height: 4),
          Text(
            'Đã có ảnh — chạm để xem, giữ lâu để đổi ảnh',
            style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
          ),
        ],
        const SizedBox(height: 6),
        Text(
          hint,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade600,
            height: 1.35,
          ),
        ),
      ],
    );
  }

  Widget _buildPreview() {
    if (file != null) {
      return FutureBuilder(
        future: file!.readAsBytes(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          return ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.memory(snap.data!, fit: BoxFit.cover, width: double.infinity),
          );
        },
      );
    }

    final url = existingImageUrl;
    if (url != null && url.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          fit: StackFit.expand,
          children: [
            AppNetworkImage(
              url: url,
              fit: BoxFit.cover,
              errorWidget: const Center(
                child: Icon(Icons.broken_image_outlined, size: 40, color: Colors.grey),
              ),
            ),
            Positioned(
              right: 8,
              bottom: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('Xem', style: TextStyle(color: Colors.white, fontSize: 11)),
              ),
            ),
          ],
        ),
      );
    }

    return Center(
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          color: const Color(0xFFD0D4D9),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white, width: 2),
        ),
        child: const Icon(Icons.photo_camera_outlined, size: 32, color: Colors.white),
      ),
    );
  }
}
