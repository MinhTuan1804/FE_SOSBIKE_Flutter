import 'package:flutter/material.dart';
import 'package:fe_moblie_flutter/core/theme/app_colors.dart';
import 'package:fe_moblie_flutter/features/home/mechanic/data/models/incoming_rescue_request.dart';
import 'package:fe_moblie_flutter/features/home/mechanic/presentation/widgets/mechanic_order_map_background.dart';
import 'package:fe_moblie_flutter/features/home/mechanic/presentation/widgets/mechanic_order_stepper.dart';

/// Nội dung **Đến tận nơi** — nằm trong MainShell (giữ header + bottom nav).
class MechanicArrivalView extends StatelessWidget {
  const MechanicArrivalView({
    super.key,
    required this.request,
    required this.onBack,
    required this.onArrived,
  });

  final IncomingRescueRequest request;
  final VoidCallback onBack;
  final VoidCallback onArrived;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final sheetMaxH = constraints.maxHeight * 0.52;

        return Stack(
          fit: StackFit.expand,
          children: [
            const MechanicOrderMapBackground(showRoute: true, showUserPulse: false),
            Positioned(
              top: 8,
              left: 8,
              child: Material(
                color: Colors.white,
                shape: const CircleBorder(),
                elevation: 4,
                child: InkWell(
                  onTap: onBack,
                  customBorder: const CircleBorder(),
                  child: const SizedBox(
                    width: 36,
                    height: 36,
                    child: Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: Color(0xFF374151)),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxHeight: sheetMaxH),
                child: MechanicOrderFlowSheetBody(
                  title: 'Đến điểm sửa chữa.',
                  activeStep: 0,
                  action: Material(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(16),
                    elevation: 6,
                    shadowColor: AppColors.primary.withValues(alpha: 0.5),
                    child: InkWell(
                      onTap: onArrived,
                      borderRadius: BorderRadius.circular(16),
                      child: const SizedBox(
                        height: 46,
                        child: Center(
                          child: Text(
                            'Đã đến nơi',
                            style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
