import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Font families — Reem Kufi (brand/display) + IBM Plex Sans Arabic (UI/body).
TextStyle brand(
        {double size = 20,
        FontWeight weight = FontWeight.w600,
        Color color = AppColors.ink,
        double? height,
        double? letterSpacing}) =>
    GoogleFonts.reemKufi(
        fontSize: size,
        fontWeight: weight,
        color: color,
        height: height,
        letterSpacing: letterSpacing);

TextStyle ui(
        {double size = 14,
        FontWeight weight = FontWeight.w400,
        Color color = AppColors.ink,
        double? height,
        double? letterSpacing}) =>
    GoogleFonts.ibmPlexSansArabic(
        fontSize: size,
        fontWeight: weight,
        color: color,
        height: height,
        letterSpacing: letterSpacing);

class AppTheme {
  AppTheme._();

  static ThemeData get light {
    final base = ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.bg,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        onPrimary: AppColors.primaryInk,
        primaryContainer: AppColors.accentSoft,
        onPrimaryContainer: AppColors.primaryDeep,
        secondary: AppColors.accent,
        onSecondary: AppColors.primaryInk,
        surface: AppColors.surface,
        onSurface: AppColors.ink,
        surfaceContainerHighest: AppColors.surfaceAlt,
        onSurfaceVariant: AppColors.muted,
        outline: AppColors.line,
        error: AppColors.danger,
      ),
      textTheme: GoogleFonts.ibmPlexSansArabicTextTheme().apply(
        bodyColor: AppColors.ink,
        displayColor: AppColors.ink,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        titleTextStyle: brand(size: 20, weight: FontWeight.w600),
      ),
      dividerTheme: const DividerThemeData(
          color: AppColors.line, thickness: 1, space: 1),
      splashColor: AppColors.accentSoft.withValues(alpha: 0.4),
      highlightColor: Colors.transparent,
      pageTransitionsTheme: const PageTransitionsTheme(builders: {
        TargetPlatform.android: CupertinoPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
      }),
    );
    return base;
  }
}
