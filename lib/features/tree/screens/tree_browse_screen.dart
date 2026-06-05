import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/widgets.dart';
import '../providers/tree_provider.dart';
import '../widgets/family_tree_view.dart';

class TreeBrowseScreen extends ConsumerWidget {
  const TreeBrowseScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membersAsync = ref.watch(membersProvider);
    final adjacencyAsync = ref.watch(adjacencyProvider);
    final meId = ref.watch(linkedMemberIdProvider).valueOrNull;
    final family = ref.watch(currentFamilyProvider);

    return AppScreen(
      tab: 'tree',
      fab: true,
      onFab: () => context.push('/add-member'),
      title: family.maybeWhen(
          data: (f) => f == null ? 'شجرتي' : 'آل ${f.name}', orElse: () => 'الشجرة'),
      sub: membersAsync.maybeWhen(
          data: (m) => '${m.length} أفراد', orElse: () => null),
      leading: Container(
        width: 40,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.line),
        ),
        child: const TreeMark(size: 24),
      ),
      trailing: RoundButton('search', onTap: () => context.push('/search')),
      child: membersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => Center(child: Text('$e')),
        data: (members) {
          if (members.isEmpty) {
            return Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Text('🌱', style: TextStyle(fontSize: 56)),
                const SizedBox(height: 16),
                Text('شجرتك فارغة', style: brand(size: 20, weight: FontWeight.w600)),
                const SizedBox(height: 20),
                SizedBox(
                  width: 200,
                  child: PrimaryButton('أضف أول فرد',
                      onPressed: () => context.push('/add-member')),
                ),
              ]),
            );
          }
          return Stack(children: [
            Center(
              child: SingleChildScrollView(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(12, 22, 12, 26),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.line),
                  ),
                  child: adjacencyAsync.maybeWhen(
                    data: (adj) => FamilyTreeView(
                      meId: meId,
                      members: members,
                      adjacency: adj,
                      onTapMember: (id) => context.push('/profile/$id'),
                    ),
                    orElse: () => const Padding(
                      padding: EdgeInsets.all(40),
                      child: CircularProgressIndicator(color: AppColors.primary),
                    ),
                  ),
                ),
              ),
            ),
            PositionedDirectional(
              end: 4,
              top: 4,
              child: Column(children: [
                RoundButton('plus', onTap: () {}),
                const SizedBox(height: 8),
                Material(
                  color: AppColors.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: AppColors.line),
                  ),
                  child: const SizedBox(
                    width: 40,
                    height: 40,
                    child: Icon(Icons.remove_rounded, size: 22, color: AppColors.ink),
                  ),
                ),
              ]),
            ),
          ]);
        },
      ),
    );
  }
}
