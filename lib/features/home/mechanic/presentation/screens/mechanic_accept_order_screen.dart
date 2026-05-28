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
                  const MechanicOrderMapBackground(),
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
                            Row(
                              children: [
                                Expanded(
                                  flex: 4,
                                  child: OutlinedButton(
                                    onPressed: onCancel,
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppColors.primary,
                                      side: const BorderSide(color: AppColors.primary, width: 1.5),
                                      minimumSize: const Size(0, 44),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                    ),
                                    child: const Text(
                                      'Hủy chuyến',
                                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  flex: 6,
                                  child: ElevatedButton(
                                    onPressed: onGoNow,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                      foregroundColor: Colors.white,
                                      elevation: 4,
                                      shadowColor: AppColors.primary.withValues(alpha: 0.45),
                                      minimumSize: const Size(0, 44),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                    ),
                                    child: const Text(
                                      'Đi ngay!',
                                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                                    ),
                                  ),
                                ),
                              ],
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
