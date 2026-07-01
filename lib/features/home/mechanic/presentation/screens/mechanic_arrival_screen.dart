import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:fe_moblie_flutter/core/theme/app_colors.dart';
import 'package:fe_moblie_flutter/features/home/customer/presentation/providers/rescue_provider.dart';
import 'package:fe_moblie_flutter/features/home/mechanic/data/models/incoming_rescue_request.dart';
import 'package:fe_moblie_flutter/features/home/mechanic/presentation/widgets/mechanic_flow_title_bar.dart';
import 'package:fe_moblie_flutter/features/home/mechanic/presentation/widgets/mechanic_map_draggable_sheet.dart';
import 'package:fe_moblie_flutter/features/home/mechanic/presentation/widgets/mechanic_order_map_background.dart';
import 'package:fe_moblie_flutter/features/home/mechanic/presentation/widgets/mechanic_order_stepper.dart';
import 'package:fe_moblie_flutter/features/home/mechanic/presentation/widgets/mechanic_order_shared_widgets.dart';
import 'package:fe_moblie_flutter/features/home/mechanic/presentation/providers/mechanic_repair_provider.dart';
import 'package:fe_moblie_flutter/features/notifications/presentation/screens/chat_detail_screen.dart';

/// Giao diện **Đến tận nơi** của thợ — hiển thị map thực tế, chỉ đường Goong API, và xác nhận đã đến.
class MechanicArrivalView extends StatelessWidget {
  const MechanicArrivalView({
    super.key,
    required this.request,
    required this.onBack,
    required this.onArrived,
    required this.onGoHome,
  });

  final IncomingRescueRequest request;
  final VoidCallback onBack;
  final VoidCallback onArrived;
  final VoidCallback onGoHome;

  @override
  Widget build(BuildContext context) {
    final rescue = context.watch<RescueProvider>();
    final isSubmitting = context.watch<MechanicRepairProvider>().isSubmitting;

    final double distanceKm = rescue.goongDistanceKm ?? (request.distanceMeters / 1000.0);
    final int durationMins = rescue.goongDurationMins ?? (distanceKm * 4).toInt().clamp(2, 60);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MechanicFlowTitleBar(
          title: 'Đến điểm sửa chữa',
          includeTopSafeArea: true,
          onGoHome: onGoHome,
          leading: IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
          ),
        ),
        Expanded(
          child: MechanicMapDraggableSheet(
            map: MechanicOrderMapBackground(
              customerLatitude: request.latitude,
              customerLongitude: request.longitude,
              showRoute: true,
              showUserPulse: false,
            ),
            initialSize: 0.30,
            minSize: 0.06,
            maxSize: 0.92,
            sheetContent: MechanicOrderFlowSheetBody(
              wrapSheet: false,
              title: 'Đến điểm sửa chữa.',
              subtitle: 'Khoảng cách: ${distanceKm.toStringAsFixed(1)} km • Thời gian di chuyển ước tính: $durationMins phút',
              activeStep: 0,
              action: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  MechanicOrderContactRow(
                    phoneNumber: request.phoneNumber,
                    onCall: () async {
                      final Uri telUri = Uri.parse('tel:${request.phoneNumber}');
                      try {
                        if (await canLaunchUrl(telUri)) {
                          await launchUrl(telUri);
                        } else {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Không thể thực hiện gọi điện')),
                            );
                          }
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Lỗi gọi điện: $e')),
                          );
                        }
                      }
                    },
                    onChat: () {
                      final orderId = rescue.currentOrderId ?? '';
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => ChatDetailScreen(
                            orderId: orderId,
                            title: request.customerName,
                            avatarUrl: request.avatarUrl,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () async {
                      final double? originLat = rescue.mechanicLatitude;
                      final double? originLng = rescue.mechanicLongitude;
                      final double? destLat = request.latitude;
                      final double? destLng = request.longitude;

                      if (destLat == null || destLng == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Không tìm thấy tọa độ vị trí của khách hàng.'),
                            backgroundColor: Colors.redAccent,
                          ),
                        );
                        return;
                      }

                      final String urlString;
                      if (originLat != null && originLng != null) {
                        urlString = 'https://www.google.com/maps/dir/?api=1&origin=$originLat,$originLng&destination=$destLat,$destLng&travelmode=driving';
                      } else {
                        urlString = 'https://www.google.com/maps/dir/?api=1&destination=$destLat,$destLng&travelmode=driving';
                      }

                      final Uri url = Uri.parse(urlString);
                      try {
                        if (await canLaunchUrl(url)) {
                          await launchUrl(url, mode: LaunchMode.externalApplication);
                        } else {
                          await launchUrl(url, mode: LaunchMode.platformDefault);
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Không thể mở ứng dụng bản đồ: $e'),
                              backgroundColor: Colors.redAccent,
                            ),
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.navigation_rounded, color: Colors.white, size: 20),
                    label: const Text(
                      'Chỉ đường bằng Google Maps',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E88E5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      elevation: 2,
                    ),
                  ),
                ],
              ),
            ),
            pinnedFooter: Material(
              color: isSubmitting ? const Color(0xFF9CA3AF) : AppColors.primary,
              borderRadius: BorderRadius.circular(16),
              elevation: 6,
              shadowColor: AppColors.primary.withValues(alpha: 0.5),
              child: InkWell(
                onTap: isSubmitting ? null : onArrived,
                borderRadius: BorderRadius.circular(16),
                child: SizedBox(
                  height: 52,
                  child: Center(
                    child: isSubmitting
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text(
                            'Đã đến nơi',
                            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
