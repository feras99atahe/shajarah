import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/widgets.dart';
import '../../relationship/kinship.dart';
import '../../tree/models/member.dart';
import '../../tree/models/relationship.dart';
import '../../tree/providers/tree_provider.dart';

class MembersScreen extends ConsumerStatefulWidget {
  const MembersScreen({super.key});

  @override
  ConsumerState<MembersScreen> createState() => _MembersScreenState();
}

class _MembersScreenState extends ConsumerState<MembersScreen> {
  int _scope = 0; // 0 = my family, 1 = other families
  // local
  final _searchCtrl = TextEditingController();
  String _q = '';
  int _filter = 0;
  // global
  final _city = TextEditingController();
  final _clan = TextEditingController();
  final _family = TextEditingController();
  (String, String, String)? _globalQuery;

  @override
  void dispose() {
    for (final c in [_searchCtrl, _city, _clan, _family]) c.dispose();
    super.dispose();
  }

  String _initial(String name) => name.isNotEmpty ? name.characters.first : '؟';

  @override
  Widget build(BuildContext context) {
    return AppScreen(
      tab: 'people',
      title: 'الأعضاء',
      trailing: _scope == 0
          ? RoundButton('plus', onAccent: true, onTap: () => context.push('/add-member'))
          : null,
      child: Column(children: [
        const SizedBox(height: 2),
        // scope toggle
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(color: AppColors.surfaceAlt, borderRadius: BorderRadius.circular(13)),
          child: Row(children: [
            _seg('عائلتي', 0),
            _seg('عائلات أخرى', 1),
          ]),
        ),
        const SizedBox(height: 12),
        Expanded(child: _scope == 0 ? _local() : _global()),
      ]),
    );
  }

  Widget _seg(String label, int i) {
    final on = _scope == i;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _scope = i),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: on ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(label, style: ui(size: 13.5, weight: on ? FontWeight.w700 : FontWeight.w600, color: on ? AppColors.primaryInk : AppColors.muted)),
        ),
      ),
    );
  }

  // ── My family ───────────────────────────────────────────────────────────
  Widget _local() {
    final membersAsync = ref.watch(membersProvider);
    final adj = ref.watch(adjacencyProvider).valueOrNull ?? const <String, List<(String, RelationshipType)>>{};
    final meId = ref.watch(linkedMemberIdProvider).valueOrNull;

    return membersAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      error: (e, _) => Center(child: Text('$e')),
      data: (members) {
        final byId = {for (final m in members) m.id: m};
        final rels = _relations(meId, adj, byId);
        var list = members.where((m) {
          if (_filter == 1 && m.isDeceased) return false;
          if (_filter == 2 && !m.isDeceased) return false;
          if (_q.isNotEmpty && !m.fullName.contains(_q) && !m.city.contains(_q)) return false;
          return true;
        }).toList()
          ..sort((a, b) => a.firstName.compareTo(b.firstName));

        return Column(children: [
          SearchField(hint: 'ابحث بالاسم أو القبيلة…', controller: _searchCtrl, onChanged: (v) => setState(() => _q = v)),
          const SizedBox(height: 10),
          SizedBox(
            height: 34,
            child: ListView(scrollDirection: Axis.horizontal, children: [
              AppChip('الكل', on: _filter == 0, onTap: () => setState(() => _filter = 0)),
              const SizedBox(width: 8),
              AppChip('الأحياء', on: _filter == 1, onTap: () => setState(() => _filter = 1)),
              const SizedBox(width: 8),
              AppChip('المتوفّون', on: _filter == 2, onTap: () => setState(() => _filter = 2)),
            ]),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: list.isEmpty
                ? Center(child: Text('لا نتائج', style: ui(color: AppColors.muted)))
                : ListView.builder(
                    itemCount: list.length,
                    itemBuilder: (_, i) {
                      final m = list[i];
                      final rel = rels[m.id];
                      return MemberRow(
                        char: _initial(m.firstName),
                        photoUrl: m.photoUrl,
                        name: m.fullName,
                        rel: [if (rel != null) rel, m.city].join(' · '),
                        you: rel == 'أنت',
                        line: rel != null && rel != 'أنت',
                        last: i == list.length - 1,
                        onTap: () => context.push('/profile/${m.id}'),
                      );
                    },
                  ),
          ),
        ]);
      },
    );
  }

  // ── Other families (directory by city + clan + family) ──────────────────
  Widget _global() {
    return Column(children: [
      Text('ابحث عن أقاربك في عائلات أخرى بالمدينة والقبيلة واسم العائلة.',
          style: ui(size: 12.5, color: AppColors.muted, height: 1.5)),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(child: AppField(label: 'المدينة', controller: _city)),
        const SizedBox(width: 10),
        Expanded(child: AppField(label: 'القبيلة', controller: _clan)),
      ]),
      const SizedBox(height: 10),
      AppField(label: 'العائلة (اللقب)', controller: _family),
      const SizedBox(height: 12),
      PrimaryButton('بحث', onPressed: () {
        setState(() => _globalQuery = (_city.text.trim(), _clan.text.trim(), _family.text.trim()));
      }),
      const SizedBox(height: 14),
      Expanded(child: _globalResults()),
    ]);
  }

  Widget _globalResults() {
    if (_globalQuery == null) {
      return Center(child: Text('أدخل معيارًا واحدًا على الأقل ثم اضغط بحث', style: ui(size: 13, color: AppColors.faint), textAlign: TextAlign.center));
    }
    final async = ref.watch(globalSearchProvider(_globalQuery!));
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      error: (e, _) => Center(child: Text('$e')),
      data: (results) {
        if (results.isEmpty) {
          return Center(child: Text('لا توجد نتائج مطابقة', style: ui(color: AppColors.muted)));
        }
        return ListView.builder(
          itemCount: results.length,
          itemBuilder: (_, i) {
            final r = results[i];
            return MemberRow(
              char: _initial(r.firstName),
              name: r.fullName,
              rel: [r.city, if (r.clanName != null) r.clanName!].join(' · '),
              last: i == results.length - 1,
              onTap: () => _showPublic(r),
            );
          },
        );
      },
    );
  }

  void _showPublic(PublicMember r) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 36),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 36, height: 4, margin: const EdgeInsets.only(bottom: 18), decoration: BoxDecoration(color: AppColors.line, borderRadius: BorderRadius.circular(2))),
            Avatar(char: _initial(r.firstName), size: 72),
            const SizedBox(height: 12),
            Text(r.fullName, textAlign: TextAlign.center, style: brand(size: 19, weight: FontWeight.w600)),
            const SizedBox(height: 7),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(AppIcons.of('pin'), size: 14, color: AppColors.muted),
              const SizedBox(width: 3),
              Text(r.clanName == null ? r.city : '${r.city} · ${r.clanName}', style: ui(size: 12.5, color: AppColors.muted)),
            ]),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: AppColors.surfaceAlt, borderRadius: BorderRadius.circular(14)),
              child: Row(children: [
                Icon(AppIcons.of('lock'), size: 18, color: AppColors.faint),
                const SizedBox(width: 10),
                Expanded(child: Text('اسم الأم والتفاصيل الخاصة مخفية — لا توجد صلة موثّقة بينك وبين هذا الفرد.', style: ui(size: 12.5, color: AppColors.muted, height: 1.6))),
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  /// One BFS from me → kinship label for every reachable member.
  Map<String, String> _relations(
      String? meId, Map<String, List<(String, RelationshipType)>> adj, Map<String, Member> byId) {
    final out = <String, String>{};
    if (meId == null || !byId.containsKey(meId)) return out;
    out[meId] = 'أنت';
    final visited = {meId};
    final queue = <List<KinHop>>[[]];
    final ids = <String>[meId];
    while (queue.isNotEmpty) {
      final hops = queue.removeAt(0);
      final cur = ids.removeAt(0);
      for (final (next, type) in adj[cur] ?? const <(String, RelationshipType)>[]) {
        if (visited.contains(next) || !byId.containsKey(next)) continue;
        final nh = [...hops, KinHop(edge: type, gender: byId[next]!.gender)];
        out[next] = Kinship.relationLabel(nh);
        visited.add(next);
        queue.add(nh);
        ids.add(next);
      }
    }
    return out;
  }
}
