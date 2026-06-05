import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/widgets.dart';
import '../../auth/providers/auth_provider.dart';
import '../../claims/providers/claim_provider.dart';
import '../../tree/providers/tree_provider.dart';
import '../providers/admin_provider.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(userRoleProvider).valueOrNull;
    if (role != 'admin') {
      return AppScreen(
        title: 'لوحة الإدارة',
        leading: RoundButton('back', onTap: () => context.go('/tree')),
        child: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.lock_outline_rounded, size: 56, color: AppColors.faint),
            const SizedBox(height: 12),
            Text('للمشرفين فقط', style: brand(size: 18, weight: FontWeight.w600)),
          ]),
        ),
      );
    }

    final stats = ref.watch(adminStatsProvider).valueOrNull;
    final users = ref.watch(familyUsersProvider).valueOrNull ?? const [];
    final claimsAsync = ref.watch(pendingClaimsProvider);
    final family = ref.watch(currentFamilyProvider).valueOrNull;

    return AppScreen(
      title: 'لوحة الإدارة',
      sub: family == null ? null : 'آل ${family.name}',
      leading: RoundButton('back', onTap: () => context.go('/tree')),
      child: ListView(children: [
        const SizedBox(height: 4),
        AppCard(
          pad: 2,
          child: Row(children: [
            Stat(value: '${stats?.memberCount ?? '…'}', label: 'أفراد'),
            Container(width: 1, color: AppColors.line, margin: const EdgeInsets.symmetric(vertical: 10)),
            Stat(value: '${users.length}', label: 'مستخدمون'),
            Container(width: 1, color: AppColors.line, margin: const EdgeInsets.symmetric(vertical: 10)),
            Stat(value: '${users.where((u) => u.role == 'admin').length}', label: 'مشرفون'),
          ]),
        ),
        const SizedBox(height: 16),

        // ── Pending claims ──────────────────────────────────────────────
        claimsAsync.maybeWhen(
          data: (claims) => claims.isEmpty
              ? const SizedBox.shrink()
              : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  SectionTitle('طلبات الانضمام (${claims.length})'),
                  ...claims.map((c) => _ClaimCard(claim: c)),
                  const SizedBox(height: 6),
                ]),
          orElse: () => const SizedBox.shrink(),
        ),

        const SectionTitle('الإدارة'),
        AppCard(
          pad: 4,
          child: Column(children: [
            SettingRow(icon: 'people', title: 'الأعضاء والأدوار', sub: '${users.length} مستخدمين', trailing: Icon(AppIcons.of('chevron'), size: 18, color: AppColors.faint), onTap: () => context.push('/admin/users')),
            SettingRow(icon: 'doc', title: 'استيراد من CSV', sub: 'إضافة دفعة مع كشف العلاقات', trailing: Icon(AppIcons.of('chevron'), size: 18, color: AppColors.faint), onTap: () => context.push('/import')),
            SettingRow(icon: 'settings', title: 'الخصوصية واللغة', last: true, trailing: Icon(AppIcons.of('chevron'), size: 18, color: AppColors.faint), onTap: () => context.push('/settings')),
          ]),
        ),
        const SizedBox(height: 14),
        AppCard(
          pad: 4,
          child: SettingRow(
            icon: 'lock',
            title: 'تسجيل الخروج',
            last: true,
            onTap: () async {
              await ref.read(authNotifierProvider.notifier).signOut();
              if (context.mounted) context.go('/');
            },
          ),
        ),
        const SizedBox(height: 30),
      ]),
    );
  }
}

class _ClaimCard extends ConsumerWidget {
  final PendingClaim claim;
  const _ClaimCard({required this.claim});

  Future<void> _act(BuildContext context, WidgetRef ref, bool approve) async {
    try {
      final n = ref.read(claimNotifierProvider.notifier);
      if (approve) {
        await n.approve(claim.claimId);
      } else {
        await n.reject(claim.claimId);
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(approve ? 'تمت الموافقة على ${claim.memberLabel}' : 'تم رفض الطلب', textAlign: TextAlign.right),
          backgroundColor: approve ? AppColors.primary : AppColors.muted,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('$e', textAlign: TextAlign.right),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppCard(
      margin: const EdgeInsets.only(bottom: 10),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Avatar(char: claim.memberLabel.isNotEmpty ? claim.memberLabel.characters.first : '؟', size: 42),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(claim.memberLabel, style: brand(size: 15, weight: FontWeight.w600)),
              const SizedBox(height: 1),
              Text(claim.claimantEmail, style: ui(size: 11.5, color: AppColors.muted)),
            ]),
          ),
        ]),
        const SizedBox(height: 6),
        Text('يطلب هذا الحساب ربط نفسه بهذا الفرد. أكّد هويته في الواقع قبل الموافقة.',
            style: ui(size: 12, color: AppColors.muted, height: 1.5)),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(
            child: SizedBox(
              height: 42,
              child: ElevatedButton(
                onPressed: () => _act(context, ref, true),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: AppColors.primaryInk, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: Text('موافقة', style: ui(size: 14, weight: FontWeight.w700, color: AppColors.primaryInk)),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: SizedBox(
              height: 42,
              child: OutlinedButton(
                onPressed: () => _act(context, ref, false),
                style: OutlinedButton.styleFrom(foregroundColor: AppColors.danger, side: const BorderSide(color: AppColors.danger), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: Text('رفض', style: ui(size: 14, weight: FontWeight.w700, color: AppColors.danger)),
              ),
            ),
          ),
        ]),
      ]),
    );
  }
}
