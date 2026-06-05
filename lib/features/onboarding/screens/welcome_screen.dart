import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/widgets.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return OnboardingShell(
      footer: Column(mainAxisSize: MainAxisSize.min, children: [
        PrimaryButton('إنشاء حساب جديد', onPressed: () => context.go('/signup')),
        const SizedBox(height: 11),
        GhostButton('تسجيل الدخول', onPressed: () => context.go('/login')),
        const SizedBox(height: 4),
        TextButton(
          onPressed: () => context.go('/admin-login'),
          child: Text('دخول المشرف', style: ui(size: 13, weight: FontWeight.w600, color: AppColors.muted)),
        ),
      ]),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 132,
            height: 132,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.line, width: 1.5),
              boxShadow: const [
                BoxShadow(color: AppColors.glow, blurRadius: 44, offset: Offset(0, 18))
              ],
            ),
            child: const TreeMark(size: 70),
          )
              .animate()
              .fadeIn(duration: 600.ms)
              .scale(begin: const Offset(0.6, 0.6), curve: Curves.easeOutBack, duration: 700.ms),
          const SizedBox(height: 30),
          const Wordmark(size: 46).animate().fadeIn(delay: 250.ms),
          const SizedBox(height: 30),
          SizedBox(
            width: 260,
            child: Text(
              'شجرة عائلتك، محفوظة للأجيال القادمة. اكتب اسمك الكامل، ويتكفّل النظام بربط أقاربك تلقائيًا.',
              textAlign: TextAlign.center,
              style: ui(size: 16.5, color: AppColors.muted, height: 1.7),
            ).animate().fadeIn(delay: 400.ms),
          ),
        ],
      ),
    );
  }
}
