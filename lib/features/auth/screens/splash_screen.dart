import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../providers/auth_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigate();
  }

  Future<void> _navigate() async {
    await Future.delayed(const Duration(milliseconds: 2400));
    if (!mounted) return;
    final user = ref.read(currentUserProvider);
    context.go(user != null ? '/tree' : '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF303B1A), // primaryDark
              Color(0xFF4E5E2E), // primary
              Color(0xFF6B7D3A), // slightly lighter
            ],
            stops: [0.0, 0.55, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // Subtle geometric background pattern
            ...List.generate(6, (i) => Positioned(
              right: -30.0 + i * 60,
              top: 80.0 + i * 90,
              child: Container(
                width: 120, height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.04),
                    width: 1,
                  ),
                ),
              ),
            )),

            // Main content
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Logo ring
                  Container(
                    width: 120, height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.07),
                      border: Border.all(
                        color: AppColors.accent,
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '🌳',
                        style: const TextStyle(fontSize: 58),
                      ),
                    ),
                  )
                      .animate()
                      .fadeIn(duration: 700.ms)
                      .scale(
                        begin: const Offset(0.4, 0.4),
                        duration: 800.ms,
                        curve: Curves.elasticOut,
                      ),

                  const SizedBox(height: 32),

                  // Arabic title
                  Text(
                    'شجرة',
                    style: GoogleFonts.reemKufi(
                      fontSize: 64,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      height: 1.0,
                    ),
                  )
                      .animate()
                      .fadeIn(delay: 400.ms, duration: 600.ms)
                      .slideY(begin: 0.3, duration: 500.ms, delay: 400.ms),

                  const SizedBox(height: 8),

                  // Gold divider
                  Container(
                    width: 48, height: 2,
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ).animate().fadeIn(delay: 800.ms).scaleX(begin: 0),

                  const SizedBox(height: 10),

                  // Latin subtitle
                  Text(
                    'S H A J A R A H',
                    style: GoogleFonts.ibmPlexSansArabic(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: Colors.white.withValues(alpha: 0.65),
                      letterSpacing: 5,
                    ),
                  ).animate().fadeIn(delay: 700.ms, duration: 600.ms),

                  const SizedBox(height: 8),

                  // Region tag
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.accent.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Text(
                      'شجرة عائلتك',
                      style: GoogleFonts.reemKufi(
                        fontSize: 13,
                        color: AppColors.accent,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ).animate().fadeIn(delay: 900.ms, duration: 500.ms),
                ],
              ),
            ),

            // Bottom loading dots
            Positioned(
              bottom: 60,
              left: 0, right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (i) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: 6, height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.4),
                  ),
                ).animate(delay: Duration(milliseconds: 1000 + i * 150))
                    .fadeIn(duration: 300.ms)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
