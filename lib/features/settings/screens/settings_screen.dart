import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/providers/auth_provider.dart';

final _localeProvider = StateProvider<Locale>((ref) => const Locale('en'));

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(_localeProvider);
    final isAr = locale.languageCode == 'ar';
    final roleAsync = ref.watch(userRoleProvider);
    final isAdmin = roleAsync.valueOrNull == 'admin';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (isAdmin) ...[
            _SectionCard(
              title: 'ADMINISTRATION',
              children: [
                _SettingsTile(
                  icon: Icons.admin_panel_settings_rounded,
                  label: 'Admin Dashboard',
                  onTap: () => context.push('/admin'),
                ),
              ],
            ).animate().fadeIn().slideY(begin: 0.2),
            const Gap(16),
          ],
          _SectionCard(
            title: 'LANGUAGE',
            children: [
              _SettingsTile(
                icon: Icons.language_rounded,
                label: 'Language',
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _LangChip(
                      label: 'EN',
                      selected: !isAr,
                      onTap: () => ref.read(_localeProvider.notifier).state =
                          const Locale('en'),
                    ),
                    const Gap(8),
                    _LangChip(
                      label: 'AR',
                      selected: isAr,
                      onTap: () => ref.read(_localeProvider.notifier).state =
                          const Locale('ar'),
                    ),
                  ],
                ),
              ),
            ],
          ).animate().fadeIn().slideY(begin: 0.2),
          const Gap(16),
          _SectionCard(
            title: 'ACCOUNT',
            children: [
              _SettingsTile(
                icon: Icons.person_outline_rounded,
                label: 'Profile',
                onTap: () => context.push('/profile-setup'),
              ),
              const Divider(height: 1, indent: 52),
              _SettingsTile(
                icon: Icons.logout_rounded,
                label: 'Logout',
                color: AppColors.error,
                onTap: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Logout'),
                      content:
                          const Text('Are you sure you want to log out?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Cancel'),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.error,
                          ),
                          child: const Text('Logout'),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true && context.mounted) {
                    await ref.read(authNotifierProvider.notifier).signOut();
                    if (context.mounted) context.go('/login');
                  }
                },
              ),
            ],
          ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.2),
          const Gap(40),
          Center(
            child: Text(
              'Shajarah · شجرة  v1.0.0',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textTertiary,
                  ),
            ),
          ).animate().fadeIn(delay: 200.ms),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _SectionCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.textTertiary,
                  letterSpacing: 1.2,
                ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? color;

  const _SettingsTile({
    required this.icon,
    required this.label,
    this.trailing,
    this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: color ?? AppColors.primary, size: 22),
      title: Text(
        label,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: color ?? AppColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
      ),
      trailing: trailing ??
          (onTap != null
              ? const Icon(Icons.chevron_right_rounded,
                  color: AppColors.textTertiary)
              : null),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    );
  }
}

class _LangChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _LangChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
