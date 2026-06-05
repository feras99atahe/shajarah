import 'package:flutter/material.dart';

/// Shajarah · Olive & Sand (الاتجاه أ · زيتون)
/// Tokens taken verbatim from the design system (THEMES.olive).
class AppColors {
  AppColors._();

  // Surfaces
  static const bg          = Color(0xFFF1ECDF);
  static const surface     = Color(0xFFFBF7EE);
  static const surfaceAlt  = Color(0xFFE9E1CF);

  // Text
  static const ink   = Color(0xFF2B2A20);
  static const muted = Color(0xFF7E775F);
  static const faint = Color(0xFFA89F86);

  // Lines
  static const line = Color(0xFFDBD2BD);

  // Brand
  static const primary     = Color(0xFF515E37);
  static const primaryDeep = Color(0xFF3C4727);
  static const primaryInk  = Color(0xFFFBF7EE);

  // Accent (brass)
  static const accent     = Color(0xFFA9792F);
  static const accentSoft = Color(0xFFE7DBBF);

  // Glow — rgba(81,94,55,0.30)
  static const glow = Color(0x4D515E37);

  // Semantic (kept minimal; derived to harmonize with the palette)
  static const danger      = Color(0xFFB23A2E);
  static const dangerSoft  = Color(0xFFF3DED9);
  static const success     = primary;
  static const successSoft = accentSoft;
}
