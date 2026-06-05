import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/widgets.dart';
import '../../auth/providers/auth_provider.dart';
import '../../relationship/kinship.dart';
import '../../relationship/widgets/kinship_chain.dart';
import '../models/member.dart';
import '../models/relationship.dart';
import '../providers/tree_provider.dart';

class ProfileScreen extends ConsumerWidget {
  final String memberId;
  const ProfileScreen({super.key, required this.memberId});

  String _initial(Member m) => m.firstName.isNotEmpty ? m.firstName.characters.first : '؟';

  /// BFS shortest path me→target as [(memberId, edgeFromPrev)] (first edge null).
  List<(String, RelationshipType?)>? _pathToMe(
      String? meId, String targetId, Map<String, List<(String, RelationshipType)>> adj,
      Map<String, Member> byId) {
    if (meId == null || !byId.containsKey(meId)) return null;
    if (meId == targetId) return [(meId, null)];
    final visited = {meId};
    final queue = <List<(String, RelationshipType?)>>[
      [(meId, null)]
    ];
    while (queue.isNotEmpty) {
      final p = queue.removeAt(0);
      for (final (next, type) in adj[p.last.$1] ?? const <(String, RelationshipType)>[]) {
        if (visited.contains(next) || !byId.containsKey(next)) continue;
        final np = [...p, (next, type)];
        if (next == targetId) return np;
        visited.add(next);
        queue.add(np);
      }
    }
    return null;
  }

  String? _label(List<(String, RelationshipType?)> path, Map<String, Member> byId) {
    if (path.length == 1) return 'أنت';
    final hops = <KinHop>[
      for (var i = 1; i < path.length; i++)
        KinHop(edge: path[i].$2!, gender: byId[path[i].$1]?.gender ?? 'male')
    ];
    return Kinship.relationLabel(hops);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final memberAsync = ref.watch(memberByIdProvider(memberId));
    final relsAsync = ref.watch(memberRelationshipsProvider(memberId));
    final connected = ref.watch(isConnectedToProvider(memberId)).valueOrNull ?? false;
    final role = ref.watch(userRoleProvider).valueOrNull;
    final meId = ref.watch(linkedMemberIdProvider).valueOrNull;
    final adj = ref.watch(adjacencyProvider).valueOrNull ?? const <String, List<(String, RelationshipType)>>{};
    final allMembers = ref.watch(membersProvider).valueOrNull ?? const <Member>[];
    final byId = {for (final m in allMembers) m.id: m};

    final canSeePrivate = connected || role == 'admin' || role == 'editor';

    return AppScreen(
      title: 'الملف الشخصي',
      leading: RoundButton('back', onTap: () => context.pop()),
      trailing: RoundButton('dots', onTap: () {}),
      child: memberAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => Center(child: Text('$e')),
        data: (m) {
          if (m == null) return const Center(child: Text('غير موجود'));
          final path = _pathToMe(meId, m.id, adj, byId);
          final rel = path == null ? null : _label(path, byId);
          return ListView(children: [
            const SizedBox(height: 4),
            // identity
            Column(children: [
              Avatar(char: _initial(m), photoUrl: m.photoUrl, line: true, size: 84),
              const SizedBox(height: 10),
              Text(m.fullName, textAlign: TextAlign.center, style: brand(size: 20, weight: FontWeight.w600)),
              const SizedBox(height: 7),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                if (rel != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                        color: AppColors.accentSoft, borderRadius: BorderRadius.circular(8)),
                    child: Text(rel, style: ui(size: 12.5, weight: FontWeight.w700, color: AppColors.accent)),
                  ),
                  const SizedBox(width: 6),
                ],
                Icon(AppIcons.of('pin'), size: 14, color: AppColors.muted),
                const SizedBox(width: 3),
                Text(m.hasClan ? '${m.city} · ${m.clanName}' : m.city,
                    style: ui(size: 12.5, color: AppColors.muted)),
              ]),
            ]),
            const SizedBox(height: 16),

            // how you relate — the path of people
            if (path != null && path.length > 1) ...[
              const SectionTitle('كيف تربطك به'),
              AppCard(pad: 16, child: KinshipChain(path: path, byId: byId)),
              const SizedBox(height: 14),
            ],

            // protected fields
            AppCard(
              pad: 4,
              child: Column(children: [
                SettingRow(
                  icon: 'calendar',
                  title: 'تاريخ الميلاد',
                  sub: (canSeePrivate && m.showBirthDate && m.birthDate != null)
                      ? _fmt(m.birthDate!)
                      : 'مخفي حسب تفضيل صاحب الملف',
                  trailing: (canSeePrivate && m.showBirthDate)
                      ? Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(AppIcons.of('eye'), size: 14, color: AppColors.primary),
                          const SizedBox(width: 4),
                          Text('ظاهر لك', style: ui(size: 11, weight: FontWeight.w600, color: AppColors.primary)),
                        ])
                      : Icon(AppIcons.of('lock'), size: 16, color: AppColors.faint),
                ),
                SettingRow(
                  icon: 'lock',
                  title: 'اسم الأم',
                  sub: 'يُكشف للأقارب الموثّقين فقط',
                  last: true,
                  trailing: (canSeePrivate && m.hasMotherName)
                      ? Flexible(
                          child: Text(m.motherFullName,
                              textAlign: TextAlign.left,
                              style: ui(size: 12.5, weight: FontWeight.w600)))
                      : Text('مخفي', style: ui(size: 12.5, color: AppColors.faint)),
                ),
              ]),
            ),
            const SizedBox(height: 14),

            // relations
            relsAsync.maybeWhen(
              data: (rels) {
                final tiles = <Widget>[];
                for (final p in rels.parents) {
                  tiles.add(_MiniRel(char: _initial(p), label: p.isMale ? 'الأب' : 'الأم', onTap: () => context.push('/profile/${p.id}')));
                }
                if (rels.children.isNotEmpty) {
                  tiles.add(_MiniRel(char: _initial(rels.children.first), label: '${rels.children.length} أبناء', onTap: () => context.push('/profile/${rels.children.first.id}')));
                }
                for (final s in rels.siblings.take(2)) {
                  tiles.add(_MiniRel(char: _initial(s), label: s.isMale ? 'أخ' : 'أخت', onTap: () => context.push('/profile/${s.id}')));
                }
                if (tiles.isEmpty) return const SizedBox.shrink();
                return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const SectionTitle('الصلات المباشرة'),
                  Row(children: [
                    for (var i = 0; i < tiles.take(4).length; i++) ...[
                      if (i > 0) const SizedBox(width: 9),
                      Expanded(child: tiles[i]),
                    ],
                  ]),
                ]);
              },
              orElse: () => const SizedBox.shrink(),
            ),
            const SizedBox(height: 24),

            PrimaryButton('عرض في الشجرة', onPressed: () => context.go('/tree')),
            const SizedBox(height: 10),
            GhostButton('اكتشف صلتي به', onPressed: () => context.push('/relationship')),
            const SizedBox(height: 30),
          ]);
        },
      ),
    );
  }

  static String _fmt(DateTime d) => '${d.day}/${d.month}/${d.year}';
}

class _MiniRel extends StatelessWidget {
  final String char;
  final String label;
  final VoidCallback? onTap;
  const _MiniRel({required this.char, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.line),
          ),
          child: Column(children: [
            Avatar(char: char, size: 38),
            const SizedBox(height: 6),
            Text(label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: ui(size: 11.5, weight: FontWeight.w600, color: AppColors.muted)),
          ]),
        ),
      );
}
