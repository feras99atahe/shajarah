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
    await Future.delayed(const Duration(milliseconds: 2000));
    if (!mounted) return;
    final user = ref.read(currentUserProvider);
    if (user != null) {
      context.go('/tree');
    } else {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Vertical gradient: dark green → lighter green
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.primaryDark,
              AppColors.primary,
              Color(0xFF40916C),
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Gold ring around the tree icon
              Container(
                width: 108,
                height: 108,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.accent,
                    width: 2.5,
                  ),
                  color: Colors.white.withValues(alpha: 0.08),
                ),
                child: const Center(
                  child: Text('🌳', style: TextStyle(fontSize: 54)),
                ),
              )
                  .animate()
                  .fadeIn(duration: 700.ms)
                  .scale(
                    begin: const Offset(0.5, 0.5),
                    duration: 700.ms,
                    curve: Curves.elasticOut,
                  ),
              const SizedBox(height: 28),
              Text(
                'شجرة',
                style: GoogleFonts.cairo(
                  fontSize: 52,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  height: 1.0,
                ),
              )
                  .animate()
                  .fadeIn(duration: 600.ms, delay: 350.ms)
                  .slideY(begin: 0.3, end: 0, duration: 500.ms, delay: 350.ms),
              const SizedBox(height: 6),
              // Gold underline
              Container(
                width: 60,
                height: 2,
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(1),
                ),
              ).animate().fadeIn(delay: 700.ms).scaleX(begin: 0, end: 1),
              const SizedBox(height: 10),
              Text(
                'Shajarah',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 20,
                  fontWeight: FontWeight.w400,
                  color: Colors.white.withValues(alpha: 0.75),
                  letterSpacing: 4,
                ),
              ).animate().fadeIn(duration: 600.ms, delay: 600.ms),
              const SizedBox(height: 6),
              Text(
                'ليبيا · Libya',
                style: GoogleFonts.cairo(
                  fontSize: 13,
                  color: AppColors.accent.withValues(alpha: 0.9),
                  letterSpacing: 1,
                ),
              ).animate().fadeIn(duration: 600.ms, delay: 800.ms),
            ],
          ),
        ),
      ),
    );
  }
}
