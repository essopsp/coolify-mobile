import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Lazily renders a one-click service logo from the network.
///
/// Logos are never bundled — they are fetched on demand from the Coolify
/// catalogue and served through Flutter's image caches (memory + disk), so
/// scrolling the list only pays for what is actually visible.
///
/// Handles both raster (png/jpg/webp) and vector (svg) sources, and degrades
/// to a neutral glyph when a logo is missing or fails to load.
class ServiceLogo extends StatelessWidget {
  const ServiceLogo({
    super.key,
    required this.url,
    this.size = 28,
    this.fallbackIcon = Icons.widgets_outlined,
  });

  final String? url;
  final double size;
  final IconData fallbackIcon;

  @override
  Widget build(BuildContext context) {
    final u = url;
    if (u == null || u.isEmpty) return _fallback();

    // A subtle placeholder box keeps list rows from resizing as images arrive.
    if (u.toLowerCase().endsWith('.svg')) {
      return SvgPicture.network(
        u,
        width: size,
        height: size,
        fit: BoxFit.contain,
        placeholderBuilder: _placeholder,
        errorBuilder: (context, error, stack) => _fallback(),
      );
    }
    return Image.network(
      u,
      width: size,
      height: size,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.medium,
      gaplessPlayback: true,
      loadingBuilder: (context, child, progress) =>
          progress == null ? child : _placeholderBox(),
      errorBuilder: (context, error, stack) => _fallback(),
    );
  }

  Widget _placeholder(BuildContext context) => _placeholderBox();

  Widget _placeholderBox() => SizedBox(
        width: size,
        height: size,
        child: Center(
          child: SizedBox(
            width: size * 0.5,
            height: size * 0.5,
            child: CircularProgressIndicator(
              strokeWidth: 1.5,
              color: Colors.white.withValues(alpha: 0.22),
            ),
          ),
        ),
      );

  Widget _fallback() => Icon(fallbackIcon, size: size, color: Colors.white38);
}