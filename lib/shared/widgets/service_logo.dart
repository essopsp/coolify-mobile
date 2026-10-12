import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Renders a one-click service logo.
///
/// Handles both raster (png/jpg/webp) and vector (svg) assets, falling back to
/// a neutral glyph when the asset is missing or fails to decode — some upstream
/// catalogue entries have no logo at all.
class ServiceLogo extends StatelessWidget {
  const ServiceLogo({
    super.key,
    required this.asset,
    this.size = 28,
    this.fallbackIcon = Icons.widgets_outlined,
  });

  final String? asset;
  final double size;
  final IconData fallbackIcon;

  @override
  Widget build(BuildContext context) {
    final path = asset;
    if (path == null || path.isEmpty) return _fallback();
    if (path.toLowerCase().endsWith('.svg')) {
      return SvgPicture.asset(
        path,
        width: size,
        height: size,
        // Some catalogue SVGs have no explicit viewBox; fit them into a box.
        fit: BoxFit.contain,
        placeholderBuilder: (_) => _fallback(),
      );
    }
    return Image.asset(
      path,
      width: size,
      height: size,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.medium,
      errorBuilder: (_, _, _) => _fallback(),
    );
  }

  Widget _fallback() => Icon(
        fallbackIcon,
        size: size,
        color: Colors.white38,
      );
}