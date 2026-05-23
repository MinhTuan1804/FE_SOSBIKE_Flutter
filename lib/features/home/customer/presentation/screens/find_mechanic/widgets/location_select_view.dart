import 'package:flutter/material.dart';
import 'package:fe_moblie_flutter/core/theme/app_colors.dart';

class LocationSelectView extends StatelessWidget {
  const LocationSelectView({
    super.key,
    required this.mechanicNote,
    required this.onBack,
    required this.onAddNote,
    required this.onConfirmLocation,
  });

  final String mechanicNote;
  final VoidCallback onBack;
  final VoidCallback onAddNote;
  final VoidCallback onConfirmLocation;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildFlowHeader(context, onBack: onBack),
        const SizedBox(height: 16),
        // Search Address Bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            height: 54,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Icon(Icons.location_on, color: Colors.white, size: 24),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Vị trí hiện tại của bạn',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.camera_alt, color: Colors.white, size: 22),
                ),
              ],
            ),
          ),
        ),
        const Spacer(),
        // Bottom sheet details panel
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 10,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              // Grabber line
              Container(
                width: 48,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2.5),
                ),
              ),
              const SizedBox(height: 16),
              // Suggestions List
              _buildLocationItem(
                icon: Icons.location_on,
                iconColor: AppColors.primary,
                title: 'Cổng Đường Số 55',
                distance: '0.0km',
                isSelected: true,
              ),
              const Divider(height: 1, indent: 64),
              _buildLocationItem(
                icon: Icons.location_on_outlined,
                iconColor: Colors.grey,
                title: 'Cổng Đường Số 62',
                distance: '0.1km',
                isSelected: false,
              ),
              const Divider(height: 1, indent: 64),
              _buildLocationItem(
                icon: Icons.location_on_outlined,
                iconColor: Colors.grey,
                title: 'Cổng Đường Số 51',
                distance: '0.1km',
                isSelected: false,
              ),
              const SizedBox(height: 16),
              // Buttons
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Row(
                  children: [
                    Expanded(
                      flex: 4,
                      child: OutlinedButton(
                        onPressed: onAddNote,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red[800],
                          side: BorderSide(color: Colors.red[200]!, width: 1.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          backgroundColor: Colors.red[50],
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: Text(
                          mechanicNote.isEmpty ? 'Chi tiết' : 'Đã có ghi chú',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 6,
                      child: ElevatedButton(
                        onPressed: onConfirmLocation,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          elevation: 2,
                        ),
                        child: const Text(
                          'Chọn địa điểm này',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Optional helper text
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  'Vào "chi tiết" để gợi ý thêm cho Thợ Lưu Động',
                  style: TextStyle(color: Colors.red[300], fontSize: 12, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLocationItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String distance,
    required bool isSelected,
  }) {
    return Container(
      color: isSelected ? Colors.red[50]?.withValues(alpha: 0.4) : null,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: isSelected ? Colors.red[100] : Colors.grey[100],
            child: Icon(icon, color: iconColor),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  distance,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFlowHeader(BuildContext context, {required VoidCallback onBack}) {
    final top = MediaQuery.paddingOf(context).top;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(top: top + 8, bottom: 12, left: 16),
      color: AppColors.primary,
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: Icon(Icons.arrow_back_ios_new, color: AppColors.primary, size: 20),
            onPressed: onBack,
          ),
        ),
      ),
    );
  }
}
