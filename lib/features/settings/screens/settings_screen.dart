import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/widgets.dart';
import '../../auth/providers/auth_provider.dart';
import '../../tree/providers/tree_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool? _showBirth;

  @override
  Widget build(BuildContext context) {
    final role = ref.watch(userRoleProvider).valueOrNull;
    final meId = ref.watch(linkedMemberIdProvider).valueOrNull;
    final me = meId == null ? null : ref.watch(memberByIdProvider(meId)).valueOrNull;
    _showBirth ??= me?.showBirthDate ?? false;
    final myChar = (me != null && me.firstName.isNotEmpty) ? me.firstName.characters.first : '؟';

    return AppScreen(
      title: 'الخصوصية واللغة',
      leading: RoundButton('back', onTap: () => context.pop()),
      child: ListView(children: [
        const SizedBox(height: 4),
        const SectionTitle('الخصوصية'),
        AppCard(
          pad: 4,
          child: Column(children: [
            SettingRow(
              icon: 'calendar',
              title: 'إظهار تاريخ ميلادي',
              sub: 'يراه الأقارب الموثّقون في شجرتي',
              trailing: AppToggle(
                value: _showBirth!,
                onChanged: (v) async {
                  setState(() => _showBirth = v);
                  if (meId != null) {
                    await ref.read(treeNotifierProvider.notifier)
                        .updateMember(meId, {'show_birth_date': v});
                  }
                },
              ),
            ),
            SettingRow(
              icon: 'lock',
              title: 'إظهار اسم الأم',
              sub: 'مخفي عن الغرباء · ظاهر للأقارب',
              trailing: const AppToggle(value: true),
            ),
            SettingRow(
              icon: 'people',
              title: 'عزل العائلة',
              sub: 'لا يُرى محتوى شجرتي خارجيًا',
              last: true,
              trailing: const AppToggle(value: true),
            ),
          ]),
        ),
        const SizedBox(height: 16),
        const SectionTitle('اللغة'),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(color: AppColors.surfaceAlt, borderRadius: BorderRadius.circular(13)),
          child: Row(children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                alignment: Alignment.center,
                decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(10)),
                child: Text('العربية', style: ui(size: 14, weight: FontWeight.w700, color: AppColors.primaryInk)),
              ),
            ),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                alignment: Alignment.center,
                child: Text('English', style: ui(size: 14, weight: FontWeight.w600, color: AppColors.muted)),
              ),
            ),
          ]),
        ),
        const SizedBox(height: 16),
        const SectionTitle('دوري في العائلة'),
        AppCard(
          child: Row(children: [
            Avatar(char: myChar, you: true, size: 42),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(me?.fullName ?? '—', maxLines: 1, overflow: TextOverflow.ellipsis, style: brand(size: 15.5, weight: FontWeight.w600)),
                const SizedBox(height: 1),
                Text(role == 'admin' ? 'تحكّم كامل في العائلة' : 'عضو', style: ui(size: 12, color: AppColors.muted)),
              ]),
            ),
            RoleBadge(role ?? 'viewer'),
          ]),
        ),
        const SizedBox(height: 30),
      ]),
    );
  }
}
