import 'package:flutter/material.dart';
import 'package:fe_moblie_flutter/core/theme/app_colors.dart';
import 'package:fe_moblie_flutter/features/home/mechanic/data/models/incoming_rescue_request.dart';
import 'package:fe_moblie_flutter/features/home/mechanic/presentation/widgets/mechanic_flow_title_bar.dart';
import 'package:fe_moblie_flutter/features/home/mechanic/presentation/widgets/mechanic_order_map_background.dart';
import 'package:fe_moblie_flutter/features/home/mechanic/presentation/widgets/mechanic_order_shared_widgets.dart';

/// Nội dung **Nhận Đơn** — nằm trong MainShell (giữ header + bottom nav).
class MechanicAcceptOrderView extends StatelessWidget {
  const MechanicAcceptOrderView({
    super.key,
    required this.request,
    required this.onCancel,
    required this.onGoNow,
  });

  final IncomingRescueRequest request;
  final VoidCallback onCancel;
  final VoidCallback onGoNow;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final sheetMaxH = constraints.maxHeight * 0.58;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const MechanicFlowTitleBar(title: 'Nhận Đơn'),
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  MechanicOrderMapBackground(
                    customerLatitude: request.latitude,
                    customerLongitude: request.longitude,
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxHeight: sheetMaxH),
                      child: MechanicOrderBottomSheet(
                        child: SingleChildScrollView(
                          child: Column(
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
                            const SizedBox(height: 12),
                            Container(
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
                          ],
                        ),
                      ),
                    ),
                  ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
