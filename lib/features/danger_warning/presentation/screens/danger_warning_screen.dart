import 'package:flutter/material.dart';
import 'package:fe_moblie_flutter/core/theme/app_colors.dart';
import 'package:fe_moblie_flutter/core/widgets/coming_soon_overlay.dart';

class DangerWarningScreen extends StatefulWidget {
  const DangerWarningScreen({super.key});

  @override
  State<DangerWarningScreen> createState() => _DangerWarningScreenState();
}

class _DangerWarningScreenState extends State<DangerWarningScreen> {
  bool _isSwitchedOn = true;
  bool _isSoundOn = true;

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.paddingOf(context).top;

    return ComingSoonOverlay(
      featureName: 'Cảnh báo nguy hiểm',
      message: 'Tính năng cảnh báo cung đường nguy hiểm sẽ sớm được tích hợp.',
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0F0303), Color(0xFF4A0505), Color(0xFF0F0303)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Column(
            children: [
              // Red Header
              Container(
                padding: EdgeInsets.only(
                    top: topPadding + 8, bottom: 16, left: 16, right: 16),
                color: AppColors.primary,
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.chevron_left_rounded,
                          color: AppColors.primary,
                          size: 30,
                        ),
                      ),
                    ),
                    const Spacer(),
                  ],
                ),
              ),

              // Body content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24.0, vertical: 20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Top actions
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          _buildCircleButton(
                            icon: Icons.location_on_rounded,
                            onTap: () {},
                          ),
                          const SizedBox(width: 12),
                          _buildCircleButton(
                            icon: _isSoundOn
                                ? Icons.volume_up_rounded
                                : Icons.volume_off_rounded,
                            onTap: () {
                              setState(() => _isSoundOn = !_isSoundOn);
                            },
                          ),
                        ],
                      ),
                      const Spacer(flex: 2),

                      // Center: vertical toggle switch
                      Center(
                        child: GestureDetector(
                          onTap: () =>
                              setState(() => _isSwitchedOn = !_isSwitchedOn),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            width: 140,
                            height: 300,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(70),
                              border:
                                  Border.all(color: Colors.white24, width: 2),
                              gradient: _isSwitchedOn
                                  ? const LinearGradient(
                                      colors: [
                                        Color(0xFFE81B1B),
                                        Color(0xFF800C0C)
                                      ],
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                    )
                                  : const LinearGradient(
                                      colors: [
                                        Color(0xFF333333),
                                        Color(0xFF1A1A1A)
                                      ],
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                    ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.5),
                                  blurRadius: 15,
                                  offset: const Offset(0, 8),
                                ),
                                if (_isSwitchedOn)
                                  BoxShadow(
                                    color:
                                        Colors.red.withValues(alpha: 0.25),
                                    blurRadius: 20,
                                    spreadRadius: 2,
                                  ),
                              ],
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                AnimatedPositioned(
                                  duration: const Duration(milliseconds: 300),
                                  top: _isSwitchedOn ? 40 : 200,
                                  child: Text(
                                    _isSwitchedOn ? 'On' : 'Off',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 34,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                                AnimatedPositioned(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOutBack,
                                  bottom: _isSwitchedOn ? 20 : 160,
                                  child: Container(
                                    width: 100,
                                    height: 100,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black
                                              .withValues(alpha: 0.3),
                                          blurRadius: 8,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const Spacer(flex: 3),

                      const Text(
                        'Khi bật tính năng này, app sẽ thông báo mỗi khi bạn đi vào những cung đường nguy hiểm trong suốt chuyến đi.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCircleButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Icon(icon, color: AppColors.primary, size: 26),
      ),
    );
  }
}
