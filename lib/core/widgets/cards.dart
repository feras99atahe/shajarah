import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import 'app_icons.dart';
import 'avatar.dart';

class AppCard extends StatelessWidget {
  final Widget child;
  final double pad;
  final EdgeInsetsGeometry? margin;
  const AppCard({super.key, required this.child, this.pad = 14, this.margin});

  @override
  Widget build(BuildContext context) => Container(
        margin: margin,
        padding: EdgeInsets.all(pad),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.line),
        ),
        child: child,
      );
}

class RoleBadge extends StatelessWidget {
  final String role; // admin | editor | viewer
  const RoleBadge(this.role, {super.key});

  @override
  Widget build(BuildContext context) {
    final (label, bg, c) = switch (role) {
      'admin' => ('مشرف', AppColors.primary, AppColors.primaryInk),
      'editor' => ('محرّر', AppColors.accentSoft, AppColors.accent),
      _ => ('مشاهد', AppColors.surfaceAlt, AppColors.muted),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Text(label, style: ui(size: 11, weight: FontWeight.w700, color: c)),
    );
  }
}

class AppChip extends StatelessWidget {
  final String label;
  final bool on;
  final VoidCallback? onTap;
  const AppChip(this.label, {super.key, this.on = false, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
        decoration: BoxDecoration(
          color: on ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(99),
          border: Border.all(color: on ? AppColors.primary : AppColors.line),
        ),
        child: Text(label,
            style: ui(
                size: 13,
                weight: FontWeight.w600,
                color: on ? AppColors.primaryInk : AppColors.muted)),
      ),
    );
  }
}

class Stat extends StatelessWidget {
  final String value;
  final String label;
  const Stat({super.key, required this.value, required this.label});

  @override
  Widget build(BuildContext context) => Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
          child: Column(children: [
            Text(value, style: brand(size: 25, weight: FontWeight.w700, color: AppColors.primary)),
            const SizedBox(height: 2),
            Text(label, style: ui(size: 11.5, color: AppColors.muted)),
          ]),
        ),
      );
}

class SectionTitle extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onAction;
  const SectionTitle(this.title, {super.key, this.action, this.onAction});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(2, 4, 2, 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(title, style: ui(size: 12.5, weight: FontWeight.w700, color: AppColors.muted)),
            const Spacer(),
            if (action != null)
              GestureDetector(
                onTap: onAction,
                child: Text(action!,
                    style: ui(size: 12.5, weight: FontWeight.w600, color: AppColors.accent)),
              ),
          ],
        ),
      );
}

class MemberRow extends StatelessWidget {
  final String char;
  final String? photoUrl;
  final String name;
  final String? rel;
  final String? role;
  final bool last;
  final bool you;
  final bool line;
  final VoidCallback? onTap;

  const MemberRow({
    super.key,
    required this.char,
    this.photoUrl,
    required this.name,
    this.rel,
    this.role,
    this.last = false,
    this.you = false,
    this.line = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 4),
        decoration: BoxDecoration(
          border: last
              ? null
              : const Border(bottom: BorderSide(color: AppColors.line)),
        ),
        child: Row(children: [
          Avatar(char: char, photoUrl: photoUrl, size: 42, you: you, line: line),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: brand(size: 15.5, weight: FontWeight.w600)),
                if (rel != null) ...[
                  const SizedBox(height: 1),
                  Text(rel!, style: ui(size: 12, color: AppColors.muted)),
                ],
              ],
            ),
          ),
          if (role != null) ...[RoleBadge(role!), const SizedBox(width: 8)],
          Icon(AppIcons.of('chevron'), size: 18, color: AppColors.faint),
        ]),
      ),
    );
  }
}

class SettingRow extends StatelessWidget {
  final String? icon;
  final String title;
  final String? sub;
  final Widget? trailing;
  final bool last;
  final VoidCallback? onTap;

  const SettingRow({
    super.key,
    this.icon,
    required this.title,
    this.sub,
    this.trailing,
    this.last = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 2),
        decoration: BoxDecoration(
          border: last
              ? null
              : const Border(bottom: BorderSide(color: AppColors.line)),
        ),
        child: Row(children: [
          if (icon != null) ...[
            Container(
              width: 34,
              height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.surfaceAlt,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(AppIcons.of(icon!), size: 19, color: AppColors.primary),
            ),
            const SizedBox(width: 13),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: ui(size: 14.5, weight: FontWeight.w600)),
                if (sub != null) ...[
                  const SizedBox(height: 2),
                  Text(sub!, style: ui(size: 12, color: AppColors.muted, height: 1.4)),
                ],
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ]),
      ),
    );
  }
}
