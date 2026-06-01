import 'package:flutter/material.dart';
import 'package:fe_moblie_flutter/core/theme/app_colors.dart';
import 'package:fe_moblie_flutter/features/home/mechanic/data/models/incoming_rescue_request.dart';
import 'package:fe_moblie_flutter/features/home/mechanic/presentation/widgets/mechanic_flow_title_bar.dart';
import 'package:fe_moblie_flutter/features/home/mechanic/presentation/widgets/mechanic_map_draggable_sheet.dart';
import 'package:fe_moblie_flutter/features/home/mechanic/presentation/widgets/mechanic_order_map_background.dart';
import 'package:fe_moblie_flutter/features/home/mechanic/presentation/widgets/mechanic_order_shared_widgets.dart';

/// Giao diện **Nhận Đơn** của thợ — hiển thị map thực tế + draggable sheet + thẻ chờ khách xác nhận.
class MechanicAcceptOrderView extends StatelessWidget {
  const MechanicAcceptOrderView({
    super.key,
    required this.request,
    required this.onCancel,
    required this.onGoNow,
    required this.onGoHome,
  });

  final IncomingRescueRequest request;
  final VoidCallback onCancel;
  final VoidCallback onGoNow;
  final VoidCallback onGoHome;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MechanicFlowTitleBar(title: 'Nhận đơn', includeTopSafeArea: true, onGoHome: onGoHome),
        Expanded(
          child: MechanicMapDraggableSheet(
            map: MechanicOrderMapBackground(
              customerLatitude: request.latitude,
              customerLongitude: request.longitude,
            ),
            initialSize: 0.38,
            minSize: 0.05,
            maxSize: 0.92,
            sheetContent: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                MechanicOrderCustomerHeader(request: request),
                const SizedBox(height: 10),
                MechanicOrderAddressBox(
                  fullAddress: request.fullAddress,
                  distanceLabel: request.distanceLabel,
                ),
                const SizedBox(height: 10),
                MechanicOrderContactRow(
                  phoneNumber: request.phoneNumber,
                  onCall: () {},
                  onChat: () {},
                ),
              ],
            ),
            pinnedFooter: Container(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Đang chờ khách hàng xác nhận...',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
