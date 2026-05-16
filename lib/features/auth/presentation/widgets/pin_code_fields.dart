import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fe_moblie_flutter/core/theme/app_colors.dart';

/// 6 ô nhập — chỉ số (OTP / mật khẩu PIN).
class PinCodeFields extends StatelessWidget {
  const PinCodeFields({
    super.key,
    required this.controllers,
    required this.focusNodes,
    this.obscure = false,
    this.onChanged,
  });

  final List<TextEditingController> controllers;
  final List<FocusNode> focusNodes;
  final bool obscure;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(6, (index) {
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(left: index == 0 ? 0 : 4, right: index == 5 ? 0 : 4),
            child: SizedBox(
              height: 52,
              child: TextField(
                controller: controllers[index],
                focusNode: focusNodes[index],
                textAlign: TextAlign.center,
                obscureText: obscure,
                obscuringCharacter: '•',
                keyboardType: TextInputType.number,
                maxLength: 1,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  counterText: '',
                  filled: true,
                  fillColor: AppColors.pinFill,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.primary, width: 2),
                  ),
                ),
                onChanged: (value) {
                  if (value.length > 1) {
                    final last = value.substring(value.length - 1);
                    if (!RegExp(r'^\d$').hasMatch(last)) {
                      controllers[index].clear();
                      return;
                    }
                    controllers[index].text = last;
                    controllers[index].selection = const TextSelection.collapsed(offset: 1);
                  }
                  if (value.isNotEmpty && index < 5) {
                    focusNodes[index + 1].requestFocus();
                  } else if (value.isEmpty && index > 0) {
                    focusNodes[index - 1].requestFocus();
                  }
                  onChanged?.call(controllers.map((c) => c.text).join());
                },
              ),
            ),
          ),
        );
      }),
    );
  }
}
