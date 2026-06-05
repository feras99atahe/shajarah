import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// Brand mark — a tiny lineage tree (lines + circles). Ports the SVG TreeMark.
class TreeMark extends StatelessWidget {
  final double size;
  final Color? stroke;
  final Color? accent;
  final Color? surface;
  const TreeMark({super.key, this.size = 46, this.stroke, this.accent, this.surface});

  @override
  Widget build(BuildContext context) => CustomPaint(
        size: Size(size, size),
        painter: _TreeMarkPainter(
          stroke ?? AppColors.primary,
          accent ?? AppColors.accent,
          surface ?? AppColors.surface,
        ),
      );
}

class _TreeMarkPainter extends CustomPainter {
  final Color stroke, accent, surface;
  _TreeMarkPainter(this.stroke, this.accent, this.surface);

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 48.0;
    final sw = 2.0 * s;
    final line = Paint()
      ..color = stroke
      ..strokeWidth = sw
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // trunk
    canvas.drawLine(Offset(24 * s, 11 * s), Offset(24 * s, 24 * s), line);
    // left branch  M24 24 C24 30 12 31 12 38
    final lb = Path()
      ..moveTo(24 * s, 24 * s)
      ..cubicTo(24 * s, 30 * s, 12 * s, 31 * s, 12 * s, 38 * s);
    canvas.drawPath(lb, line);
    // right branch M24 24 C24 30 36 31 36 38
    final rb = Path()
      ..moveTo(24 * s, 24 * s)
      ..cubicTo(24 * s, 30 * s, 36 * s, 31 * s, 36 * s, 38 * s);
    canvas.drawPath(rb, line);

    // nodes
    canvas.drawCircle(Offset(24 * s, 9 * s), 4 * s, Paint()..color = stroke);
    // bottom-left: surface fill + stroke
    canvas.drawCircle(Offset(12 * s, 39 * s), 4 * s, Paint()..color = surface);
    canvas.drawCircle(Offset(12 * s, 39 * s), 4 * s, line);
    // bottom-right: accent
    canvas.drawCircle(Offset(36 * s, 39 * s), 4 * s, Paint()..color = accent);
  }

  @override
  bool shouldRepaint(_TreeMarkPainter o) =>
      o.stroke != stroke || o.accent != accent || o.surface != surface;
}

/// Small leaf glyph used in hint badges and "تلميح" chips.
class Leaf extends StatelessWidget {
  final double size;
  final Color color;
  const Leaf({super.key, this.size = 11, this.color = AppColors.accent});

  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: Size(size, size), painter: _LeafPainter(color));
}

class _LeafPainter extends CustomPainter {
  final Color color;
  _LeafPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 12.0;
    final p = Path()
      ..moveTo(10.5 * s, 1.5 * s)
      ..cubicTo(5 * s, 1.5 * s, 2 * s, 4 * s, 2 * s, 8 * s)
      ..cubicTo(2 * s, 9 * s, 2.3 * s, 9.8 * s, 2.3 * s, 9.8 * s)
      ..cubicTo(2.3 * s, 9.8 * s, 4 * s, 6 * s, 8 * s, 5 * s)
      ..cubicTo(5.5 * s, 6.5 * s, 4 * s, 8.5 * s, 3.5 * s, 10.5 * s)
      ..cubicTo(7.5 * s, 11.7 * s, 10.5 * s, 9 * s, 10.5 * s, 4.5 * s)
      ..cubicTo(10.5 * s, 3 * s, 10.5 * s, 1.5 * s, 10.5 * s, 1.5 * s)
      ..close();
    canvas.drawPath(p, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_LeafPainter o) => o.color != color;
}

/// "شجرة" wordmark + optional latin tagline.
class Wordmark extends StatelessWidget {
  final double size;
  final bool tagline;
  final bool center;
  const Wordmark({super.key, this.size = 40, this.tagline = true, this.center = true});

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment:
            center ? CrossAxisAlignment.center : CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('شجرة',
              style: brand(size: size, weight: FontWeight.w600, height: 1)),
          if (tagline) ...[
            const SizedBox(height: 3),
            Text('SHAJARAH',
                style: ui(
                    size: size * 0.21,
                    weight: FontWeight.w600,
                    color: AppColors.accent,
                    letterSpacing: 5)),
          ],
        ],
      );
}
