import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/widgets.dart';
import '../../tree/models/member.dart';
import '../../tree/providers/tree_provider.dart';

class SmartLinkScreen extends ConsumerWidget {
  final String memberId;
  const SmartLinkScreen({super.key, required this.memberId});

  String _initial(Member m) => m.firstName.isNotEmpty ? m.firstName.characters.first : '؟';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final relsAsync = ref.watch(memberRelationshipsProvider(memberId));

    return OnboardingShell(
      step: 2,
      footer: Column(mainAxisSize: MainAxisSize.min, children: [
        PrimaryButton('نعم، هذه عائلتي', onPressed: () => context.go('/tree-reveal')),
        const SizedBox(height: 11),
        GhostButton('تابع إلى الشجرة', onPressed: () => context.go('/tree-reveal')),
      ]),
      child: relsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => Center(child: Text('$e')),
        data: (rels) {
          final father = rels.parents.isNotEmpty ? rels.parents.first : null;
          final siblings = rels.siblings;
          final title = father != null
              ? 'وجدنا والدك في الشجرة'
              : (siblings.isNotEmpty ? 'وجدنا إخوتك في الشجرة' : 'تم ربطك بعائلتك');

          return ListView(children: [
            const SizedBox(height: 4),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                    color: AppColors.accentSoft, borderRadius: BorderRadius.circular(99)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Leaf(size: 13, color: AppColors.accent),
                  const SizedBox(width: 7),
                  Text('ربط تلقائي',
                      style: ui(size: 12.5, weight: FontWeight.w700, color: AppColors.accent)),
                ]),
              ),
            ),
            const SizedBox(height: 14),
            Text(title, style: brand(size: 25, weight: FontWeight.w600, height: 1.3)),
            const SizedBox(height: 6),
            Text('طابقنا اسمك الرباعي مع أفراد موجودين في عائلتك ومدينتك.',
                style: ui(size: 14, color: AppColors.muted, height: 1.6)),
            const SizedBox(height: 18),

            if (father != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.primary, width: 1.5),
                ),
                child: Row(children: [
                  Avatar(char: _initial(father), line: true, size: 50),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(father.fullName, style: brand(size: 17, weight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Text('والدك · ${father.city}', style: ui(size: 12.5, color: AppColors.muted)),
                    ]),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                        color: AppColors.accentSoft, borderRadius: BorderRadius.circular(8)),
                    child: Text('الأب',
                        style: ui(size: 12, weight: FontWeight.w700, color: AppColors.primary)),
                  ),
                ]),
              ),
              const SizedBox(height: 14),
            ],

            if (siblings.isNotEmpty) ...[
              Text('وإخوة يشاركونك الأب',
                  style: ui(size: 12.5, weight: FontWeight.w600, color: AppColors.muted)),
              const SizedBox(height: 9),
              Row(
                children: siblings.take(3).map((s) {
                  return Expanded(
                    child: Container(
                      margin: const EdgeInsetsDirectional.only(end: 10),
                      padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 8),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.line),
                      ),
                      child: Column(children: [
                        Avatar(char: _initial(s), size: 40),
                        const SizedBox(height: 8),
                        Text(s.firstName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: ui(size: 13, weight: FontWeight.w600)),
                      ]),
                    ),
                  );
                }).toList(),
              ),
            ],

            if (father == null && siblings.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.line),
                ),
                child: Text('أنت أول فرد في هذه الشجرة — ابدأ بإضافة والدك وإخوتك.',
                    style: ui(size: 14, color: AppColors.muted, height: 1.6)),
              ),
          ]);
        },
      ),
    );
  }
}
