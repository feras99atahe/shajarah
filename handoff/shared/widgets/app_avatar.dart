import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import 'hint_leaf.dart';

/// DROP-IN REPLACEMENT for lib/shared/widgets/app_avatar.dart
///
/// Mockup look: calm olive nodes (not gender-colored). New OPTIONAL flags —
/// every existing call site keeps working unchanged:
///   isSelf     → the signed-in member: olive fill + gold accent ring + glow
///   isLineage  → a direct-line ancestor/descendant: olive border emphasis
///   showHint   → smart auto-link leaf badge (top-trailing corner)
///   showGenderDot → tiny gender indicator (default true; data isn't lost)
class AppAvatar extends StatelessWidget {
  final String? photoUrl;
  final String name;
  final String gender;
  final double size;
  final bool isDeceased;
  final bool isSelf;
  final bool isLineage;
  final bool showHint;
  final bool showGenderDot;
  final VoidCallback? onTap;

  const AppAvatar({
    super.key,
    this.photoUrl,
    required this.name,
    required this.gender,
    this.size = 48,
    this.isDeceased = false,
    this.isSelf = false,
    this.isLineage = false,
    this.showHint = false,
    this.showGenderDot = true,
    this.onTap,
  });

  // ── colour logic: olive system, not gender-driven ──────────────────────
  Color get _bg {
    if (isSelf) return AppColors.primary;
    if (isDeceased) return AppColors.deceasedLight;
    return AppColors.surface;
  }

  Color get _fg {
    if (isSelf) return AppColors.textOnPrimary;
    if (isDeceased) return AppColors.deceased;
    if (isLineage) return AppColors.primary;
    return AppColors.textSecondary;
  }

  Color get _border {
    if (isSelf) return AppColors.accent;
    if (isDeceased) return AppColors.deceased;
    if (isLineage) return AppColors.primary;
    return AppColors.border;
  }

  Color get _genderColor =>
      gender == 'male' ? AppColors.male : AppColors.female;

  String get _initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2 && parts.first.isNotEmpty && parts.last.isNotEmpty) {
      return '${parts.first[0]}${parts.last[0]}';
    }
    return name.isNotEmpty ? name[0] : '?';
  }

  @override
  Widget build(BuildContext context) {
    final circle = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _bg,
        border: Border.all(color: _border, width: isSelf ? 2 : 1.5),
        boxShadow: isSelf
            ? [
                // gold halo + soft olive glow
                BoxShadow(
                  color: AppColors.accentLight,
                  blurRadius: 0,
                  spreadRadius: 4,
                ),
                const BoxShadow(
                  color: AppColors.shadow,
                  blurRadius: 16,
                  offset: Offset(0, 6),
                ),
              ]
            : null,
      ),
      clipBehavior: Clip.antiAlias,
      child: photoUrl != null && photoUrl!.isNotEmpty
          ? CachedNetworkImage(
              imageUrl: photoUrl!,
              fit: BoxFit.cover,
              placeholder: (_, __) => _initialsWidget(),
              errorWidget: (_, __, ___) => _initialsWidget(),
            )
          : _initialsWidget(),
    );

    // overlays (hint leaf + gender dot) need a Stack sized a touch larger
    final hasOverlay = showHint || (showGenderDot && !isSelf);
    if (!hasOverlay) {
      return _wrap(circle);
    }

    return _wrap(SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          circle,
          if (showHint)
            PositionedDirectional(
              top: -3,
              end: -3,
              child: HintLeafBadge(size: size * 0.36),
            ),
          if (showGenderDot && !isSelf)
            PositionedDirectional(
              bottom: 0,
              start: 0,
              child: Container(
                width: size * 0.24,
                height: size * 0.24,
                decoration: BoxDecoration(
                  color: _genderColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.surface, width: 1.5),
                ),
              ),
            ),
        ],
      ),
    ));
  }

  Widget _wrap(Widget child) =>
      onTap != null ? GestureDetector(onTap: onTap, child: child) : child;

  Widget _initialsWidget() => Center(
        child: Text(
          _initials,
          style: TextStyle(
            fontSize: size * 0.38,
            fontWeight: FontWeight.w700,
            color: _fg,
          ),
        ),
      );
}
