import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/widgets.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/admin_provider.dart';

class AdminUsersScreen extends ConsumerWidget {
  const AdminUsersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(familyUsersProvider);
    final meId = ref.watch(currentUserProvider)?.id;

    return AppScreen(
      title: 'الأعضاء والأدوار',
      leading: RoundButton('back', onTap: () => context.pop()),
      child: usersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => Center(child: Text('$e')),
        data: (users) => ListView.builder(
          itemCount: users.length,
          itemBuilder: (_, i) {
            final u = users[i];
            final name = u.fullName ?? 'مستخدم';
            final isSelf = u.id == meId;
            return Container(
              padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 4),
              decoration: BoxDecoration(
                  border: i == users.length - 1 ? null : const Border(bottom: BorderSide(color: AppColors.line))),
              child: Row(children: [
                Avatar(char: name.characters.first, size: 42),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Flexible(child: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: brand(size: 15.5, weight: FontWeight.w600))),
                      if (isSelf) ...[
                        const SizedBox(width: 6),
                        Text('(أنت)', style: ui(size: 11, color: AppColors.muted)),
                      ],
                    ]),
                  ]),
                ),
                RoleBadge(u.role),
                if (!isSelf)
                  PopupMenuButton<String>(
                    icon: Icon(AppIcons.of('dots'), size: 20, color: AppColors.faint),
                    onSelected: (v) async {
                      final notifier = ref.read(adminNotifierProvider.notifier);
                      try {
                        if (v == 'remove') {
                          await notifier.removeUser(u.id);
                        } else {
                          await notifier.setUserRole(u.id, v);
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text('$e', textAlign: TextAlign.right),
                            backgroundColor: AppColors.danger,
                            behavior: SnackBarBehavior.floating));
                        }
                      }
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'admin', child: Text('تعيين مشرفًا')),
                      PopupMenuItem(value: 'editor', child: Text('تعيين محرّرًا')),
                      PopupMenuItem(value: 'viewer', child: Text('تعيين مشاهدًا')),
                      PopupMenuDivider(),
                      PopupMenuItem(value: 'remove', child: Text('إزالة من العائلة')),
                    ],
                  ),
              ]),
            );
          },
        ),
      ),
    );
  }
}
