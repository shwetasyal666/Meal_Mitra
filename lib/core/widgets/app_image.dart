import 'dart:io';

import 'package:flutter/material.dart';

class AppImage extends StatelessWidget {
  const AppImage({
    super.key,
    required this.imagePath,
    required this.fallback,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.borderRadius,
  });

  final String? imagePath;
  final Widget fallback;
  final BoxFit fit;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final source = imagePath?.trim() ?? '';
    Widget child;

    if (source.isEmpty) {
      child = fallback;
    } else if (_isHttpSource(source)) {
      child = Image.network(
        source,
        fit: fit,
        width: width,
        height: height,
        errorBuilder: (context, error, stackTrace) => fallback,
      );
    } else {
      final normalizedPath = source.startsWith('file://')
          ? Uri.parse(source).toFilePath()
          : source;
      child = Image.file(
        File(normalizedPath),
        fit: fit,
        width: width,
        height: height,
        errorBuilder: (context, error, stackTrace) => fallback,
      );
    }

    if (borderRadius == null) {
      return child;
    }

    return ClipRRect(
      borderRadius: borderRadius!,
      child: child,
    );
  }

  static bool isLocalPath(String? source) {
    if (source == null || source.isEmpty) return false;
    return source.startsWith('file://');
  }

  static bool _isHttpSource(String source) {
    return source.startsWith('http://') || source.startsWith('https://');
  }
}
