import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/widgets.dart';
import '../../tree/models/member.dart';
import '../../tree/models/relationship.dart';
import '../../tree/providers/tree_provider.dart';
import '../widgets/kinship_chain.dart';

class RelationshipFinderScreen extends ConsumerStatefulWidget {
  const RelationshipFinderScreen({super.key});

  @override
  ConsumerState<RelationshipFinderScreen> createState() => _State();
}

class _State extends ConsumerState<RelationshipFinderScreen> {
  Member? _a;
  Member? _b;

  String _initial(Member m) => m.firstName.isNotEmpty ? m.firstName.characters.first : '؟';

  Future<void> _pick(bool isA) async {
    final members = await ref.read(membersProvider.future);
    if (!mounted) return;
    final picked = await showModalBottomSheet<Member>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _MemberPicker(members: members, initial: _initial),
    );
    if (picked != null) setState(() => isA ? _a = picked : _b = picked);
  }

  /// BFS path A→B as [(memberId, edgeFromPrev)].
  List<(String, RelationshipType?)>? _path(
      Map<String, List<(String, RelationshipType)>> adj, String from, String to) {
    if (from == to) return [(from, null)];
    final visited = {from};
    final queue = <List<(String, RelationshipType?)>>[
      [(from, null)]
    ];
    while (queue.isNotEmpty) {
      final p = queue.removeAt(0);
      final cur = p.last.$1;
      for (final (next, type) in adj[cur] ?? const <(String, RelationshipType)>[]) {
        if (visited.contains(next)) continue;
        final np = [...p, (next, type)];
        if (next == to) return np;
        visited.add(next);
        queue.add(np);
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final adj = ref.watch(adjacencyProvider).valueOrNull ?? const <String, List<(String, RelationshipType)>>{};
    final byId = {
      for (final m in (ref.watch(membersProvider).valueOrNull ?? const <Member>[])) m.id: m
    };

    List<(String, RelationshipType?)>? path;
    if (_a != null && _b != null) path = _path(adj, _a!.id, _b!.id);

    return AppScreen(
      tab: 'link',
      title: 'مكتشف الصلات',
      sub: 'اكتب اسمين، واعرف صلة القرابة بينهما',
      child: ListView(children: [
        const SizedBox(height: 4),
        _PickField(label: 'الشخص الأول', member: _a, initial: _a == null ? null : _initial(_a!), onTap: () => _pick(true)),
        const SizedBox(height: 10),
        Row(children: [
          Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.line),
            ),
            child: Icon(AppIcons.of('link'), size: 16, color: AppColors.accent),
          ),
          const SizedBox(width: 8),
          const Expanded(child: Divider(color: AppColors.line)),
        ]),
        const SizedBox(height: 10),
        _PickField(label: 'الشخص الثاني', member: _b, initial: _b == null ? null : _initial(_b!), onTap: () => _pick(false)),
        const SizedBox(height: 24),

        if (_a != null && _b != null) ...[
          const SectionTitle('الصلة'),
          if (path == null)
            AppCard(
              child: Row(children: [
                Icon(Icons.info_outline_rounded, color: AppColors.accent),
                const SizedBox(width: 12),
                Expanded(child: Text('لا توجد صلة معروفة بين هذين الفردين.', style: ui(size: 14))),
              ]),
            )
          else
            AppCard(pad: 16, child: KinshipChain(path: path, byId: byId)),
        ],
      ]),
    );
  }
}

class _PickField extends StatelessWidget {
  final String label;
  final Member? member;
  final String? initial;
  final VoidCallback onTap;
  const _PickField({required this.label, this.member, this.initial, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: member != null ? AppColors.primary : AppColors.line,
              width: member != null ? 1.5 : 1),
        ),
        child: member == null
            ? Row(children: [
                Container(
                  width: 46,
                  height: 46,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(color: AppColors.accentSoft, shape: BoxShape.circle),
                  child: Icon(AppIcons.of('user'), color: AppColors.primary),
                ),
                const SizedBox(width: 12),
                Text(label, style: ui(size: 15, weight: FontWeight.w500, color: AppColors.muted)),
                const Spacer(),
                Icon(AppIcons.of('chevron'), color: AppColors.faint),
              ])
            : Row(children: [
                Avatar(char: initial, size: 46),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(member!.fullName, maxLines: 1, overflow: TextOverflow.ellipsis, style: ui(size: 15, weight: FontWeight.w600)),
                    Text(member!.city, style: ui(size: 12, color: AppColors.muted)),
                  ]),
                ),
                Icon(Icons.edit_outlined, size: 18, color: AppColors.primary),
              ]),
      ),
    );
  }
}

class _MemberPicker extends StatefulWidget {
  final List<Member> members;
  final String Function(Member) initial;
  const _MemberPicker({required this.members, required this.initial});

  @override
  State<_MemberPicker> createState() => _MemberPickerState();
}

class _MemberPickerState extends State<_MemberPicker> {
  final _searchCtrl = TextEditingController();
  String _q = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = widget.members.where((m) {
      if (_q.isEmpty) return true;
      return m.fullName.contains(_q) || m.city.contains(_q);
    }).toList();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        minChildSize: 0.4,
        builder: (_, ctrl) => Column(children: [
          Container(margin: const EdgeInsets.only(top: 12, bottom: 8), width: 36, height: 4, decoration: BoxDecoration(color: AppColors.line, borderRadius: BorderRadius.circular(2))),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SearchField(hint: 'ابحث بالاسم…', controller: _searchCtrl, onChanged: (v) => setState(() => _q = v)),
          ),
          Expanded(
            child: ListView.builder(
              controller: ctrl,
              itemCount: filtered.length,
              itemBuilder: (_, i) {
                final m = filtered[i];
                return MemberRow(
                  char: widget.initial(m),
                  name: m.fullName,
                  rel: m.city,
                  onTap: () => Navigator.pop(context, m),
                );
              },
            ),
          ),
        ]),
      ),
    );
  }
}
