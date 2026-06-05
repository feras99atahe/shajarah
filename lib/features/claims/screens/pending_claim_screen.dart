import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/widgets.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/claim_provider.dart';

class PendingClaimScreen extends ConsumerWidget {
  const PendingClaimScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final claimAsync = ref.watch(myClaimProvider);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.bg,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(26),
            child: claimAsync.when(
              loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
              error: (e, _) => Center(child: Text('$e')),
              data: (claim) {
                // Approved elsewhere → enter the app.
                if (claim?.status == 'approved') {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (context.mounted) context.go('/tree');
                  });
                  return const Center(child: CircularProgressIndicator(color: AppColors.primary));
                }
                final rejected = claim?.status == 'rejected';
                return Column(children: [
                  const Spacer(),
                  Container(
                    width: 96, height: 96,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      shape: BoxShape.circle,
                      border: Border.all(color: rejected ? AppColors.danger : AppColors.accent, width: 2),
                    ),
                    child: Icon(rejected ? Icons.close_rounded : Icons.hourglass_top_rounded,
                        size: 44, color: rejected ? AppColors.danger : AppColors.accent),
                  ),
                  const SizedBox(height: 24),
                  Text(rejected ? 'لم تتم الموافقة' : 'بانتظار موافقة المشرف',
                      style: brand(size: 24, weight: FontWeight.w600), textAlign: TextAlign.center),
                  const SizedBox(height: 10),
                  Text(
                    rejected
                        ? 'لم يؤكّد مشرف العائلة أنك «${claim?.memberLabel ?? ''}». يمكنك المحاولة مجددًا بملف جديد.'
                        : 'طلبت ربط حسابك بـ «${claim?.memberLabel ?? ''}» في عائلة ${claim?.familyLabel ?? ''}.\nسيؤكّد المشرف هويتك قريبًا.',
                    style: ui(size: 15, color: AppColors.muted, height: 1.7), textAlign: TextAlign.center,
                  ),
                  const Spacer(),
                  if (rejected)
                    PrimaryButton('حاول بملف جديد', onPressed: () => context.go('/name-entry'))
                  else
                    PrimaryButton('تحديث الحالة', onPressed: () => ref.invalidate(myClaimProvider)),
                  const SizedBox(height: 10),
                  GhostButton('تسجيل الخروج', onPressed: () async {
                    await ref.read(authNotifierProvider.notifier).signOut();
                    if (context.mounted) context.go('/');
                  }),
                  const SizedBox(height: 10),
                ]);
              },
            ),
          ),
        ),
      ),
    );
  }
}
