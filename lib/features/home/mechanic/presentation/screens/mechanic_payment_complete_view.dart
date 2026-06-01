import 'package:flutter/material.dart';
import 'package:fe_moblie_flutter/core/theme/app_colors.dart';
import 'package:fe_moblie_flutter/features/home/mechanic/presentation/widgets/mechanic_flow_home_button.dart';
import 'package:fe_moblie_flutter/features/home/mechanic/presentation/widgets/mechanic_flow_title_bar.dart';
import 'package:fe_moblie_flutter/features/home/mechanic/presentation/widgets/mechanic_order_stepper.dart';

/// **Thanh toán hoàn tất** — màn kết thúc chuyến (Figma).
class MechanicPaymentCompleteView extends StatelessWidget {
  const MechanicPaymentCompleteView({
    super.key,
    required this.onFinish,
    required this.onGoHome,
    this.paymentMethod = 'Tiền mặt',
  });

  final VoidCallback onFinish;
  final VoidCallback onGoHome;
  final String paymentMethod;

  static const _illustrationAsset = 'assets/images/main/mechanic_payment_success.png';

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final sheetMaxH = constraints.maxHeight * kMechanicFlowSheetRatio;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            MechanicFlowTitleBar(title: 'Hoàn thành', includeTopSafeArea: true, onGoHome: onGoHome),
            Expanded(
              child: ColoredBox(
                color: Colors.white,
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    Text(
                      paymentMethod,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Thanh toán hoàn tất',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Image.asset(
                          _illustrationAsset,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.celebration_rounded,
                            size: 120,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: sheetMaxH),
              child: MechanicOrderFlowSheetBody(
                title: 'Kiểm tra xe.',
                activeStep: 3,
                subtitle:
                    'Chúc mừng bạn đã hoàn thành nhiệm vụ. Hãy xác nhận phí dịch vụ trước khi đi nhé!',
                action: Center(
                  child: Material(
                    color: const Color(0xFF16A34A),
                    shape: const CircleBorder(),
                    elevation: 8,
                    shadowColor: const Color(0xFF16A34A).withValues(alpha: 0.5),
                    child: InkWell(
                      onTap: onFinish,
                      customBorder: const CircleBorder(),
                      child: const SizedBox(
                        width: 56,
                        height: 56,
                        child: Icon(Icons.check_rounded, color: Colors.white, size: 32),
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
