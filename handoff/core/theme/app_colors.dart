import 'package:flutter/material.dart';

/// Shajarah — Direction A · Olive & Sand (زيتون)
///
/// DROP-IN REPLACEMENT for lib/core/theme/app_colors.dart
/// Same class name, same token names → every widget that already reads
/// `AppColors.*` reskins automatically. No screen edits. No backend edits.
///
/// Only the hex VALUES changed. The gender + deceased + semantic tokens are
/// preserved (they carry meaning in the tree) and merely tuned to sit on the
/// warm ivory background.
class AppColors {
  AppColors._();

  // Brand — olive: family roots, growth, trust, heritage
  static const Color primary = Color(0xFF515E37);        // was #2D6A4F
  static const Color primaryLight = Color(0xFF6E7D4E);   // was #52B788
  static const Color primaryDark = Color(0xFF3C4727);    // was #1B4332
  static const Color primaryContainer = Color(0xFFDDE2CB); // was #D8F3DC

  // Accent — brass/ochre: honesty, heritage, prestige
  static const Color accent = Color(0xFFA9792F);         // was #C9A84C
  static const Color accentLight = Color(0xFFE7DBBF);    // was #FFF3CD

  // Backgrounds — warm sand & ivory
  static const Color background = Color(0xFFF1ECDF);     // was #FBF8F2
  static const Color surface = Color(0xFFFBF7EE);        // was #FFFFFF
  static const Color surfaceVariant = Color(0xFFE9E1CF); // was #F2F8F5
  static const Color card = Color(0xFFFBF7EE);           // was #FFFFFF

  // Borders & Dividers
  static const Color border = Color(0xFFDBD2BD);         // was #CFE3D8
  static const Color divider = Color(0xFFE4DCC9);        // was #E8F4EE

  // Text
  static const Color textPrimary = Color(0xFF2B2A20);    // was #1A2E25
  static const Color textSecondary = Color(0xFF7E775F);  // was #4A7C59
  static const Color textTertiary = Color(0xFFA89F86);   // was #8EB49A
  static const Color textOnPrimary = Color(0xFFFBF7EE);  // was #FFFFFF

  // Semantic — kept functional, nudged warmer
  static const Color success = Color(0xFF4F7A3A);
  static const Color successLight = Color(0xFFE0E8CF);
  static const Color error = Color(0xFFB23A2E);
  static const Color errorLight = Color(0xFFF3DED9);
  static const Color warning = Color(0xFFA9792F);
  static const Color warningLight = Color(0xFFEDE0C6);

  // Gender indicators — PRESERVED (meaningful in the tree), tuned to harmonize
  static const Color male = Color(0xFF3F6F7A);           // muted teal-blue
  static const Color maleLight = Color(0xFFDDE7E6);
  static const Color female = Color(0xFF9B5A4A);         // warm terracotta-rose
  static const Color femaleLight = Color(0xFFEDDED4);

  // Deceased
  static const Color deceased = Color(0xFF8A836E);
  static const Color deceasedLight = Color(0xFFE6E0D2);

  // Shadow — olive-tinted glow (replaces the cool grey shadow)
  static const Color shadow = Color(0x26515E37);         // ~15% olive
  static const Color shadowLight = Color(0x14515E37);
}
