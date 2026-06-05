import 'package:flutter/material.dart';

/// Maps the design's line-icon names to the closest Material rounded icons.
class AppIcons {
  AppIcons._();

  static const _map = <String, IconData>{
    'search': Icons.search_rounded,
    'plus': Icons.add_rounded,
    'user': Icons.person_outline_rounded,
    'people': Icons.people_outline_rounded,
    'link': Icons.hub_outlined,
    'settings': Icons.tune_rounded,
    'doc': Icons.description_outlined,
    'lock': Icons.lock_outline_rounded,
    'check': Icons.check_rounded,
    'chevron': Icons.chevron_left_rounded, // RTL: points left
    'back': Icons.chevron_right_rounded, // RTL: "back" points right
    'dots': Icons.more_horiz_rounded,
    'calendar': Icons.calendar_today_rounded,
    'pin': Icons.location_on_outlined,
    'eye': Icons.visibility_outlined,
    'upload': Icons.file_upload_outlined,
    'sparkle': Icons.auto_awesome,
  };

  static IconData of(String name) => _map[name] ?? Icons.circle_outlined;
}
