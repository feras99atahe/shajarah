import 'package:flutter/material.dart';
import '../../../core/widgets/widgets.dart';
import '../models/member.dart';
import '../models/relationship.dart';
import '../../relationship/kinship.dart';

/// Builds a generational tree centered on [meId] from members + adjacency,
/// labelling every node with its Arabic kinship term relative to "you".
class FamilyTreeView extends StatelessWidget {
  final String? meId;
  final List<Member> members;
  final Map<String, List<(String, RelationshipType)>> adjacency;
  final void Function(String memberId)? onTapMember;

  const FamilyTreeView({
    super.key,
    required this.meId,
    required this.members,
    required this.adjacency,
    this.onTapMember,
  });

  @override
  Widget build(BuildContext context) {
    if (members.isEmpty) return const SizedBox.shrink();
    final byId = {for (final m in members) m.id: m};
    final root = (meId != null && byId.containsKey(meId)) ? meId! : members.first.id;

    // BFS from root: assign generation level + kinship path.
    final level = <String, int>{root: 0};
    final path = <String, List<KinHop>>{root: const []};
    final queue = <String>[root];
    while (queue.isNotEmpty) {
      final cur = queue.removeAt(0);
      for (final (next, type) in adjacency[cur] ?? const <(String, RelationshipType)>[]) {
        if (level.containsKey(next) || !byId.containsKey(next)) continue;
        final delta = switch (type) {
          RelationshipType.parent => -1,
          RelationshipType.child => 1,
          _ => 0,
        };
        level[next] = level[cur]! + delta;
        path[next] = [...path[cur]!, KinHop(edge: type, gender: byId[next]!.gender)];
        queue.add(next);
      }
    }

    // Disconnected members → drop to the bottom generation.
    final maxLvl = level.values.isEmpty ? 0 : level.values.reduce((a, b) => a > b ? a : b);
    for (final m in members) {
      level.putIfAbsent(m.id, () => maxLvl + 1);
    }

    // Group by level.
    final byLevel = <int, List<String>>{};
    for (final e in level.entries) {
      byLevel.putIfAbsent(e.value, () => []).add(e.key);
    }
    final levels = byLevel.keys.toList()..sort();

    TreeNode toNode(String id) {
      final m = byId[id]!;
      final hops = path[id] ?? const <KinHop>[];
      final isMe = id == root;
      final lineage = hops.isNotEmpty &&
          (hops.every((h) => h.edge == RelationshipType.parent) ||
              hops.every((h) => h.edge == RelationshipType.child));
      final rel = isMe
          ? 'أنت'
          : (hops.isEmpty ? null : Kinship.relationLabel(hops));
      return TreeNode(
        char: m.firstName.isNotEmpty ? m.firstName.characters.first : '؟',
        photoUrl: m.photoUrl,
        name: m.firstName,
        rel: rel,
        you: isMe,
        line: lineage && !isMe,
        onTap: onTapMember == null ? null : () => onTapMember!(id),
      );
    }

    final rows = <Widget>[];
    for (var i = 0; i < levels.length; i++) {
      final ids = byLevel[levels[i]]!;
      rows.add(TreeRow(nodes: ids.map(toNode).toList()));
      if (i < levels.length - 1) {
        rows.add(Connector(cols: byLevel[levels[i + 1]]!.length.clamp(1, 4)));
      }
    }

    return Column(mainAxisSize: MainAxisSize.min, children: rows);
  }
}
