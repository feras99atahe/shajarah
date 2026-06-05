import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import 'brand_marks.dart';

/// Char-based tree avatar. States:
///   you     → primary fill + gold ring + glow (the signed-in member)
///   line    → direct lineage: olive border + olive initial
///   add     → dashed "+" placeholder
///   hint    → pulsing leaf badge (auto-link match)
class Avatar extends StatelessWidget {
  final String? char;
  final String? photoUrl;
  final double size;
  final bool you;
  final bool line;
  final bool add;
  final bool hint;
  final VoidCallback? onTap;

  const Avatar({
    super.key,
    this.char,
    this.photoUrl,
    this.size = 46,
    this.you = false,
    this.line = false,
    this.add = false,
    this.hint = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Widget circle;
    if (add) {
      circle = SizedBox(
        width: size,
        height: size,
        child: _DashedRing(
          size: size,
          child: Text('+',
              style: TextStyle(
                  fontSize: size * 0.5,
                  fontWeight: FontWeight.w300,
                  color: AppColors.faint,
                  height: 1)),
        ),
      );
    } else {
      final hasPhoto = photoUrl != null && photoUrl!.isNotEmpty;
      circle = Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: you ? AppColors.primary : AppColors.surface,
          image: hasPhoto
              ? DecorationImage(
                  image: CachedNetworkImageProvider(photoUrl!), fit: BoxFit.cover)
              : null,
          border: Border.all(
            color: you
                ? AppColors.accent
                : (line ? AppColors.primary : AppColors.line),
            width: you ? 2 : 1.5,
          ),
          boxShadow: you
              ? const [
                  BoxShadow(
                      color: AppColors.accentSoft, blurRadius: 0, spreadRadius: 4),
                  BoxShadow(
                      color: AppColors.glow, blurRadius: 16, offset: Offset(0, 6)),
                ]
              : null,
        ),
        child: hasPhoto
            ? null
            : Text(
                char ?? '',
                style: brand(
                  size: size * 0.42,
                  weight: FontWeight.w600,
                  color: you
                      ? AppColors.primaryInk
                      : (line ? AppColors.primary : AppColors.muted),
                ),
              ),
      );
    }

    Widget node = circle;
    if (hint) {
      node = SizedBox(
        width: size,
        height: size,
        child: Stack(clipBehavior: Clip.none, children: [
          circle,
          const PositionedDirectional(top: -3, end: -3, child: HintBadge()),
        ]),
      );
    }

    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: node);
    }
    return node;
  }
}

/// Pulsing gold leaf badge — the smart auto-link marker.
class HintBadge extends StatefulWidget {
  const HintBadge({super.key});

  @override
  State<HintBadge> createState() => _HintBadgeState();
}

class _HintBadgeState extends State<HintBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 2400))
        ..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, child) {
        final t = Curves.easeOut.transform(_c.value);
        return Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.glow.withValues(alpha: (1 - t) * 0.5),
                spreadRadius: 2 + t * 6,
              ),
            ],
          ),
          child: child,
        );
      },
      child: Container(
        width: 18,
        height: 18,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.accent,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.surface, width: 2),
        ),
        child: const Leaf(color: AppColors.primaryInk, size: 10),
      ),
    );
  }
}

/// Dashed ring used by the "add" avatar (Flutter has no dashed border).
class _DashedRing extends StatelessWidget {
  final double size;
  final Widget child;
  const _DashedRing({required this.size, required this.child});

  @override
  Widget build(BuildContext context) =>
      CustomPaint(painter: _DashPainter(), child: Center(child: child));
}

class _DashPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.faint
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke;
    final r = size.width / 2 - 1;
    final c = Offset(size.width / 2, size.height / 2);
    const dash = 0.5; // radians
    const gap = 0.35;
    for (double a = 0; a < 6.283; a += dash + gap) {
      canvas.drawArc(Rect.fromCircle(center: c, radius: r), a, dash, false, paint);
    }
  }

  @override
  bool shouldRepaint(_DashPainter o) => false;
}
