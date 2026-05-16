import 'package:flutter/material.dart';
import 'package:fe_moblie_flutter/features/auth/presentation/widgets/auth_pattern_background.dart';
import 'package:fe_moblie_flutter/features/auth/presentation/widgets/auth_screen_shell.dart';

/// Khung màn auth: cuộn được khi bàn phím mở, tránh overflow ◤◢.
class AuthFormLayout extends StatelessWidget {
  const AuthFormLayout({
    super.key,
    required this.children,
    this.bottomFixed,
  });

  final List<Widget> children;
  final Widget? bottomFixed;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return AuthScreenShell(
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        body: AuthPatternBackground(
          child: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: EdgeInsets.fromLTRB(24, 8, 24, 16 + bottomInset),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: children,
                    ),
                  ),
                ),
                if (bottomFixed != null)
                  Padding(
                    padding: EdgeInsets.fromLTRB(24, 0, 24, 16 + bottomInset),
                    child: bottomFixed!,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
