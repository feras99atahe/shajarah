import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/widgets.dart';
import '../../auth/providers/auth_provider.dart';
import '../../claims/providers/claim_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _decide();
  }

  Future<void> _decide() async {
    await Future.delayed(const Duration(milliseconds: 1400));
    if (!mounted) return;
    final user = ref.read(currentUserProvider);
    if (user == null) {
      context.go('/welcome');
      return;
    }
    final familyId = await ref.read(userFamilyIdProvider.future);
    if (!mounted) return;
    if (familyId != null) {
      context.go('/tree');
      return;
    }
    // No family yet — maybe a claim is pending admin approval.
    final claim = await ref.read(myClaimProvider.future);
    if (!mounted) return;
    context.go(claim != null && claim.status == 'pending' ? '/pending' : '/name-entry');
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.bg,
        body: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 120,
              height: 120,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.line, width: 1.5),
                boxShadow: const [BoxShadow(color: AppColors.glow, blurRadius: 40, offset: Offset(0, 16))],
              ),
              child: const TreeMark(size: 64),
            ).animate().fadeIn(duration: 600.ms).scale(begin: const Offset(0.6, 0.6), curve: Curves.easeOutBack, duration: 700.ms),
            const SizedBox(height: 26),
            const Wordmark(size: 44).animate().fadeIn(delay: 250.ms),
          ]),
        ),
      ),
    );
  }
}
