import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/widgets.dart';
import '../../tree/providers/tree_provider.dart';
import '../../tree/widgets/family_tree_view.dart';

class TreeRevealScreen extends ConsumerWidget {
  const TreeRevealScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final members = ref.watch(membersProvider);
    final adjacency = ref.watch(adjacencyProvider);
    final meId = ref.watch(linkedMemberIdProvider);
    final family = ref.watch(currentFamilyProvider);

    return OnboardingShell(
      step: 4,
      pad: 18,
      footer: PrimaryButton('ادخل إلى الشجرة', onPressed: () => context.go('/tree')),
      child: Column(children: [
        // header
        Row(children: [
          Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.line),
            ),
            child: const TreeMark(size: 26),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                family.maybeWhen(
                    data: (f) => f == null ? 'شجرتي' : 'شجرة ${f.name}', orElse: () => 'شجرتي'),
                style: brand(size: 20, weight: FontWeight.w600),
              ),
              const SizedBox(height: 1),
              Text(
                members.maybeWhen(
                    data: (m) => '${m.length} أفراد', orElse: () => '…'),
                style: ui(size: 12, color: AppColors.muted),
              ),
            ]),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(
                color: AppColors.accentSoft, borderRadius: BorderRadius.circular(99)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Leaf(size: 11, color: AppColors.accent),
              const SizedBox(width: 5),
              Text('تلميح', style: ui(size: 11, weight: FontWeight.w700, color: AppColors.accent)),
            ]),
          ),
        ]),
        const SizedBox(height: 14),

        // tree
        Expanded(
          child: SingleChildScrollView(
            child: Column(children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(12, 22, 12, 26),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.line),
                ),
                child: members.when(
                  loading: () => const Padding(
                      padding: EdgeInsets.all(40),
                      child: CircularProgressIndicator(color: AppColors.primary)),
                  error: (e, _) => Text('$e'),
                  data: (m) => adjacency.maybeWhen(
                    data: (adj) => FamilyTreeView(
                      meId: meId.valueOrNull,
                      members: m,
                      adjacency: adj,
                      onTapMember: (id) => context.push('/profile/$id'),
                    ),
                    orElse: () => const SizedBox(height: 80),
                  ),
                ),
              ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.1),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
                decoration: BoxDecoration(
                    color: AppColors.surfaceAlt, borderRadius: BorderRadius.circular(14)),
                child: Row(children: [
                  Container(
                    width: 30,
                    height: 30,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.line),
                    ),
                    child: Text('؟', style: ui(size: 15, weight: FontWeight.w700, color: AppColors.accent)),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Text('اكتشف صلتك بأي فرد في الشجرة بضغطة واحدة.',
                        style: ui(size: 13, weight: FontWeight.w500, height: 1.5)),
                  ),
                ]),
              ),
            ]),
          ),
        ),
      ]),
    );
  }
}
