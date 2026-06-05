import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import 'app_icons.dart';
import 'brand_marks.dart';
import 'buttons.dart';

/// App screen shell: full-bleed bg + optional top bar + content (+ tab bar / fab).
class AppScreen extends StatelessWidget {
  final String? title;
  final String? sub;
  final bool big;
  final Widget? leading;
  final Widget? trailing;
  final String? tab; // tree | people | link | me
  final bool fab;
  final VoidCallback? onFab;
  final Widget child;
  final double pad;

  const AppScreen({
    super.key,
    this.title,
    this.sub,
    this.big = false,
    this.leading,
    this.trailing,
    this.tab,
    this.fab = false,
    this.onFab,
    this.child = const SizedBox.shrink(),
    this.pad = 18,
  });

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.bg,
        body: Stack(children: [
          Column(children: [
            if (title != null)
              _TopBar(
                  title: title!, sub: sub, big: big, leading: leading, trailing: trailing),
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: pad),
                child: child,
              ),
            ),
            if (tab != null) _TabBar(active: tab!),
          ]),
          if (fab)
            PositionedDirectional(
              bottom: 96,
              start: 18,
              child: AppFab(onTap: onFab),
            ),
        ]),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final String title;
  final String? sub;
  final bool big;
  final Widget? leading;
  final Widget? trailing;
  const _TopBar({required this.title, this.sub, this.big = false, this.leading, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 60, 18, 12),
      child: Row(children: [
        if (leading != null) ...[leading!, const SizedBox(width: 10)],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: brand(size: big ? 27 : 20, weight: FontWeight.w600, height: 1.2)),
              if (sub != null) ...[
                const SizedBox(height: 2),
                Text(sub!, style: ui(size: 12, color: AppColors.muted)),
              ],
            ],
          ),
        ),
        if (trailing != null) ...[const SizedBox(width: 10), trailing!],
      ]),
    );
  }
}

class _TabBar extends StatelessWidget {
  final String active;
  const _TabBar({required this.active});

  static const _tabs = [
    ('tree', 'tree', 'الشجرة', '/tree'),
    ('people', 'people', 'الأعضاء', '/members'),
    ('link', 'link', 'الصلات', '/relationship'),
    ('me', 'user', 'حسابي', '/account'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 26),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.line)),
      ),
      child: Row(
        children: _tabs.map((t) {
          final (id, icon, label, route) = t;
          final on = id == active;
          return Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: on ? null : () => context.go(route),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  id == 'tree'
                      ? TreeMark(
                          size: 22,
                          stroke: on ? AppColors.primary : AppColors.faint,
                          accent: on ? AppColors.accent : AppColors.faint,
                        )
                      : Icon(AppIcons.of(icon),
                          size: 22, color: on ? AppColors.primary : AppColors.faint),
                  const SizedBox(height: 4),
                  Text(label,
                      style: ui(
                          size: 10.5,
                          weight: on ? FontWeight.w700 : FontWeight.w500,
                          color: on ? AppColors.primary : AppColors.faint)),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
