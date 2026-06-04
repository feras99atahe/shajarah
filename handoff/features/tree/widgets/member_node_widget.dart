import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_avatar.dart';
import '../models/member.dart';

/// DROP-IN REPLACEMENT for lib/features/tree/widgets/member_node_widget.dart
///
/// Mockup styling: calm olive card; the signed-in member ("you") gets the gold
/// accent treatment; auto-linked members show the hint leaf. New optional flags
/// default to false, so existing usages still compile.
class MemberNodeWidget extends StatelessWidget {
  final Member member;
  final bool isArabic;
  final bool isSelected;
  final bool isSelf;     // the signed-in user's own node
  final bool isLineage;  // direct ancestor/descendant line
  final bool showHint;   // smart auto-link match
  final VoidCallback? onTap;

  const MemberNodeWidget({
    super.key,
    required this.member,
    this.isArabic = false,
    this.isSelected = false,
    this.isSelf = false,
    this.isLineage = false,
    this.showHint = false,
    this.onTap,
  });

  Color get _borderColor {
    if (isSelf) return AppColors.accent;
    if (isSelected) return AppColors.primary;
    if (member.isDeceased) return AppColors.deceased;
    if (isLineage) return AppColors.primary;
    return AppColors.border;
  }

  double get _borderWidth => (isSelf || isSelected) ? 2 : 1.5;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap ?? () => context.push('/member/${member.id}'),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 112,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelf ? AppColors.primaryContainer : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _borderColor, width: _borderWidth),
          boxShadow: [
            BoxShadow(
              color: (isSelf ? AppColors.accent : AppColors.primary)
                  .withOpacity(isSelf || isSelected ? 0.22 : 0.12),
              blurRadius: isSelf || isSelected ? 14 : 7,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppAvatar(
              photoUrl: member.photoUrl,
              name: member.displayName(isArabic),
              gender: member.gender,
              size: 52,
              isDeceased: member.isDeceased,
              isSelf: isSelf,
              isLineage: isLineage,
              showHint: showHint,
            ),
            const SizedBox(height: 8),
            Text(
              member.displayName(isArabic),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: isSelf ? FontWeight.w700 : FontWeight.w600,
                color: member.isDeceased
                    ? AppColors.textTertiary
                    : AppColors.textPrimary,
              ),
            ),
            if (isSelf) ...[
              const SizedBox(height: 3),
              Text(
                isArabic ? 'أنت' : 'You',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppColors.accent,
                ),
              ),
            ] else if (member.age != null) ...[
              const SizedBox(height: 2),
              Text(
                isArabic ? '${member.age} سنة' : '${member.age} yrs',
                style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.textTertiary,
                ),
              ),
            ],
            if (member.isDeceased) ...[
              const SizedBox(height: 4),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.deceasedLight,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.deceased),
                ),
                child: const Text(
                  'رحمه الله',
                  style: TextStyle(
                    fontSize: 9,
                    color: AppColors.deceased,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
