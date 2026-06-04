import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Small "smart auto-link" leaf badge — the Shajarah hint marker.
/// Sits on the top-trailing corner of an avatar/node when a member was
/// matched automatically (e.g. a Supabase name match).
///
/// Usage: overlay it in a Stack on top of an AppAvatar (AppAvatar already
/// does this for you when `showHint: true`).
class HintLeafBadge extends StatelessWidget {
  final double size;
  final Color color;
  final Color ringColor;

  const HintLeafBadge({
    super.key,
    this.size = 18,
    this.color = AppColors.accent,
    this.ringColor = AppColors.surface,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: ringColor, width: 2),
      ),
      child: Center(
        child: CustomPaint(
          size: Size(size * 0.58, size * 0.58),
          painter: _LeafPainter(AppColors.textOnPrimary),
        ),
      ),
    );
  }
}

class _LeafPainter extends CustomPainter {
  final Color color;
  _LeafPainter(this.color);

  @override
  void paint(Canvas canvas, Size s) {
    final w = s.width, h = s.height;
    final fill = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    // simple leaf: rounded teardrop with a vein
    final path = Path()
      ..moveTo(w * 0.92, h * 0.10)
      ..cubicTo(w * 0.30, h * 0.10, w * 0.10, h * 0.42, w * 0.12, h * 0.86)
      ..cubicTo(w * 0.50, h * 0.55, w * 0.78, h * 0.40, w * 0.92, h * 0.10)
      ..close();
    canvas.drawPath(path, fill);
    final vein = Paint()
      ..color = color.withOpacity(0.0); // vein kept invisible for tiny sizes
    canvas.drawPath(path, vein);
  }

  @override
  bool shouldRepaint(_LeafPainter old) => old.color != color;
}
