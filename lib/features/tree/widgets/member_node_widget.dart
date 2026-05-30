import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_avatar.dart';
import '../models/member.dart';

class MemberNodeWidget extends StatelessWidget {
  final Member member;
  final bool isArabic;
  final bool isSelected;
  final VoidCallback? onTap;

  const MemberNodeWidget({
    super.key,
    required this.member,
    this.isArabic = false,
    this.isSelected = false,
    this.onTap,
  });

  Color get _borderColor {
    if (isSelected) return AppColors.accent;
    if (member.isDeceased) return AppColors.deceased;
    return member.isMale ? AppColors.male : AppColors.female;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap ?? () => context.push('/member/${member.id}'),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 110,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _borderColor,
            width: isSelected ? 2.5 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: _borderColor.withOpacity(0.18),
              blurRadius: isSelected ? 12 : 6,
              offset: const Offset(0, 3),
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
            ),
            const SizedBox(height: 8),
            Text(
              member.displayName(isArabic),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: member.isDeceased
                    ? AppColors.textTertiary
                    : AppColors.textPrimary,
              ),
            ),
            if (member.age != null) ...[
              const SizedBox(height: 2),
              Text(
                '${member.age} yrs',
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
                    fontWeight: FontWeight.w500,
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
