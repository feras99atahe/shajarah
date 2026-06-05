import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/widgets.dart';
import '../../auth/providers/auth_provider.dart';
import '../../tree/providers/tree_provider.dart';

class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(userRoleProvider).valueOrNull;
    final isAdmin = role == 'admin';
    final meId = ref.watch(linkedMemberIdProvider).valueOrNull;
    final me = meId == null ? null : ref.watch(memberByIdProvider(meId)).valueOrNull;
    final family = ref.watch(currentFamilyProvider).valueOrNull;

    final myName = me?.fullName ?? 'حسابي';
    final myChar = (me != null && me.firstName.isNotEmpty) ? me.firstName.characters.first : '؟';

    return AppScreen(
      tab: 'me',
      title: isAdmin ? 'لوحة الإدارة' : 'حسابي',
      sub: family == null ? null : 'آل ${family.name}',
      child: ListView(children: [
        const SizedBox(height: 4),
        // identity
        AppCard(
          child: Row(children: [
            Avatar(char: myChar, you: true, size: 46),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(myName, maxLines: 1, overflow: TextOverflow.ellipsis, style: brand(size: 15.5, weight: FontWeight.w600)),
                const SizedBox(height: 1),
                Text(isAdmin ? 'تحكّم كامل في العائلة' : 'عضو في العائلة', style: ui(size: 12, color: AppColors.muted)),
              ]),
            ),
            RoleBadge(role ?? 'viewer'),
          ]),
        ),
        const SizedBox(height: 16),

        AppCard(
          pad: 4,
          child: Column(children: [
            if (isAdmin)
              SettingRow(
                  icon: 'lock',
                  title: 'لوحة الإدارة',
                  sub: 'الإحصاءات · الطلبات · الأعضاء · الاستيراد',
                  trailing: Icon(AppIcons.of('chevron'), size: 18, color: AppColors.faint),
                  onTap: () => context.push('/admin')),
            SettingRow(icon: 'user', title: 'الملف الشخصي', trailing: Icon(AppIcons.of('chevron'), size: 18, color: AppColors.faint), onTap: () => meId == null ? null : context.push('/profile/$meId')),
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
