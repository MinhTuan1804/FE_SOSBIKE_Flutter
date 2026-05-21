import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Ảnh từ BE — Web dùng Dio (CORS); mobile/desktop dùng Image.network.
class AppNetworkImage extends StatelessWidget {
  const AppNetworkImage({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.errorWidget,
  });

  final String url;
  final BoxFit fit;
  final double? width;
  final double? height;
  final Widget? errorWidget;

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) {
      return Image.network(
        url,
        fit: fit,
        width: width,
        height: height,
        errorBuilder: (_, __, ___) => errorWidget ?? _defaultError(),
      );
    }

    return FutureBuilder<Uint8List?>(
      future: _fetchBytes(url),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(strokeWidth: 2));
        }
        final bytes = snap.data;
        if (bytes == null || bytes.isEmpty) {
          return errorWidget ?? _defaultError();
        }
        return Image.memory(bytes, fit: fit, width: width, height: height);
      },
    );
  }

  static final Map<String, Future<Uint8List?>> _mem = {};

  static Future<Uint8List?> _fetchBytes(String url) {
    return _mem.putIfAbsent(url, () async {
      try {
        final res = await Dio().get<List<int>>(
          url,
          options: Options(responseType: ResponseType.bytes),
        );
        final data = res.data;
        if (data == null || data.isEmpty) return null;
        return Uint8List.fromList(data);
      } catch (_) {
        return null;
      }
    });
  }

  Widget _defaultError() => const Icon(Icons.broken_image_outlined, color: Colors.grey);
}
