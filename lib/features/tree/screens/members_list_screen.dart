import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_avatar.dart';
import '../providers/tree_provider.dart';

class MembersListScreen extends ConsumerWidget {
  const MembersListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membersAsync = ref.watch(membersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('كل الأعضاء'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded),
            onPressed: () => context.push('/search'),
          ),
          IconButton(
            icon: const Icon(Icons.playlist_add_rounded),
            tooltip: 'استيراد جماعي / CSV',
            onPressed: () => context.push('/admin/bulk-add'),
          ),
        ],
      ),
      body: membersAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (members) {
          if (members.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('👥', style: TextStyle(fontSize: 56)),
                  const Gap(16),
                  Text('لا يوجد أعضاء بعد',
                      style: Theme.of(context).textTheme.headlineSmall),
                  const Gap(24),
                  ElevatedButton.icon(
                    onPressed: () => context.push('/add-member'),
                    icon: const Icon(Icons.person_add_rounded),
                    label: const Text('إضافة فرد'),
                  ),
                ],
              ),
            );
          }

          // Sort: alive first, then alphabetically
          final sorted = [...members]
            ..sort((a, b) {
              if (a.isDeceased != b.isDeceased) {
                return a.isDeceased ? 1 : -1;
              }
              return a.fullName.compareTo(b.fullName);
            });

          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: sorted.length,
            separatorBuilder: (_, __) => const Divider(height: 1, indent: 76),
            itemBuilder: (context, i) {
              final m = sorted[i];
              return ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                leading: AppAvatar(
                  photoUrl: m.photoUrl,
                  name: m.fullName,
                  gender: m.gender,
                  size: 48,
                  isDeceased: m.isDeceased,
                  onTap: () => context.push('/member/${m.id}'),
                ),
                title: Text(
                  m.fullName,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: m.isDeceased
                            ? AppColors.textTertiary
                            : AppColors.textPrimary,
                      ),
                ),
                subtitle: Row(
                  children: [
                    const Icon(Icons.location_city_outlined,
                        size: 12, color: AppColors.textTertiary),
                    const Gap(4),
                    Text(m.city,
                        style: Theme.of(context).textTheme.bodySmall
                            ?.copyWith(color: AppColors.textTertiary)),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (m.age != null)
                      Text(
                        '${m.age} سنة',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: AppColors.textTertiary),
                      ),
                    const Gap(4),
                    const Icon(Icons.chevron_left_rounded,
                        color: AppColors.textTertiary),
                  ],
                ),
                onTap: () => context.push('/member/${m.id}'),
              ).animate().fadeIn(delay: (i * 20).ms).slideX(begin: 0.05);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/add-member'),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.person_add_rounded, color: Colors.white),
      ),
    );
  }
}
