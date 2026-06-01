import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fe_moblie_flutter/core/theme/app_colors.dart';
import 'package:fe_moblie_flutter/features/home/customer/presentation/providers/rescue_provider.dart';
import 'package:fe_moblie_flutter/features/home/mechanic/data/models/incoming_rescue_request.dart';

import 'package:fe_moblie_flutter/features/home/mechanic/presentation/widgets/mechanic_flow_title_bar.dart';

import 'package:fe_moblie_flutter/features/home/mechanic/presentation/widgets/mechanic_map_draggable_sheet.dart';

import 'package:fe_moblie_flutter/features/home/mechanic/presentation/widgets/mechanic_order_map_background.dart';

import 'package:provider/provider.dart';
import 'package:fe_moblie_flutter/features/home/mechanic/presentation/providers/mechanic_repair_provider.dart';
import 'package:fe_moblie_flutter/features/home/mechanic/presentation/widgets/mechanic_order_stepper.dart';



/// Nội dung **Đến tận nơi** — map kéo được + xác nhận đã đến.

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

  @override
  Widget build(BuildContext context) {
    final rescue = context.watch<RescueProvider>();
    final double distanceKm = rescue.goongDistanceKm ?? (request.distanceMeters / 1000.0);
    final int durationMins = rescue.goongDurationMins ?? (distanceKm * 4).toInt().clamp(2, 60);

    return LayoutBuilder(
      builder: (context, constraints) {
        final sheetMaxH = constraints.maxHeight * 0.52;

        return Stack(
          fit: StackFit.expand,
          children: [
            MechanicOrderMapBackground(
              customerLatitude: request.latitude,
              customerLongitude: request.longitude,
              showRoute: true,
              showUserPulse: false,
            ),

            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxHeight: sheetMaxH),
                child: MechanicOrderFlowSheetBody(
                  title: 'Đến điểm sửa chữa.',
                  subtitle: 'Khoảng cách: ${distanceKm.toStringAsFixed(1)} km • Thời gian di chuyển ước tính: $durationMins phút',
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

        ),

      ],

    );

  }

}


