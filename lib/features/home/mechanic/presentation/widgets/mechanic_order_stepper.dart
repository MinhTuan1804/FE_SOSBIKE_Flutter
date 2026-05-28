import 'package:flutter/material.dart';
import 'package:fe_moblie_flutter/core/theme/app_colors.dart';
import 'package:fe_moblie_flutter/features/home/mechanic/presentation/widgets/mechanic_order_shared_widgets.dart';

class MechanicOrderSteps {
  static const items = [
    (Icons.two_wheeler_rounded, 'Đến nơi'),
    (Icons.fact_check_outlined, 'Kiểm tra\ntình trạng xe'),
    (Icons.build_circle_outlined, 'Sửa xe'),
    (Icons.check_circle_outline, 'Hoàn thành'),
  ];
}

class MechanicOrderStepper extends StatelessWidget {
  const MechanicOrderStepper({super.key, required this.activeIndex});

  final int activeIndex;

  @override
  Widget build(BuildContext context) {
    final steps = MechanicOrderSteps.items;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < steps.length; i++) ...[
          Expanded(
            child: _StepItem(
              icon: steps[i].$1,
              label: steps[i].$2,
              isActive: i == activeIndex,
            ),
          ),
          if (i < steps.length - 1)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Container(width: 14, height: 2, color: const Color(0xFFE5E7EB)),
            ),
        ],
      ],
    );
  }
}

class MechanicOrderFlowSheetBody extends StatelessWidget {
  const MechanicOrderFlowSheetBody({
    super.key,
    required this.title,
    required this.activeStep,
    required this.action,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final int activeStep;
  final Widget action;

  @override
  Widget build(BuildContext context) {
    return MechanicOrderBottomSheet(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF111827)),
            ),
            const SizedBox(height: 10),
            MechanicOrderStepper(activeIndex: activeStep),
            if (subtitle != null) ...[
              const SizedBox(height: 10),
              Text(
                subtitle!,
                style: const TextStyle(
                  fontSize: 12,
                  height: 1.3,
                  color: Color(0xFF6B7280),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
            const SizedBox(height: 12),
            action,
          ],
        ),
      ),
    );
  }
}

class _StepItem extends StatelessWidget {
  const _StepItem({required this.icon, required this.label, required this.isActive});

  final IconData icon;
  final String label;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? AppColors.primary : const Color(0xFFF3F4F6),
            border: Border.all(
              color: isActive ? AppColors.primary : const Color(0xFFE5E7EB),
              width: 1.5,
            ),
          ),
          child: Icon(icon, size: 18, color: isActive ? Colors.white : AppColors.primary),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 9,
            height: 1.15,
            fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
            color: isActive ? AppColors.primary : const Color(0xFF6B7280),
          ),
        ),
      ],
    );
  }
}
