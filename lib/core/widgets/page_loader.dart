import 'package:flutter/material.dart';
import 'package:fe_moblie_flutter/core/constants/app_assets.dart';
import 'package:fe_moblie_flutter/core/theme/app_colors.dart';

/// Reusable wrapper to show a full-page loading animation during page navigation.
class PageLoader extends StatefulWidget {
  const PageLoader({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 600),
  });

  final Widget child;
  final Duration duration;

  @override
  State<PageLoader> createState() => _PageLoaderState();
}

class _PageLoaderState extends State<PageLoader> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    Future.delayed(widget.duration, () {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                AppAssets.logo,
                width: 100,
                height: 100,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.motorcycle_rounded,
                  color: AppColors.primary,
                  size: 60,
                ),
              ),
              const SizedBox(height: 24),
              const SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(
                  color: AppColors.primary,
                  strokeWidth: 3,
                ),
              ),
            ],
          ),
        ),
      );
    }
    return widget.child;
  }
}
