import 'package:flutter/material.dart';
import '../../../core/widgets/widgets.dart';
import '../../tree/models/member.dart';
import '../../tree/models/relationship.dart';
import '../kinship.dart';

/// Renders the path of people between "you" (path[0]) and the target (path.last):
/// a headline term, a horizontal chain of avatars + link labels, and the degree.
class KinshipChain extends StatelessWidget {
  /// Each entry is (memberId, edgeFromPrevious). First entry's edge is null.
  final List<(String, RelationshipType?)> path;
  final Map<String, Member> byId;
  final bool showHeadline;
  const KinshipChain({
    super.key,
    required this.path,
    required this.byId,
    this.showHeadline = true,
  });

  String _initial(Member? m) => (m != null && m.firstName.isNotEmpty) ? m.firstName.characters.first : '؟';

  @override
  Widget build(BuildContext context) {
    final hops = <KinHop>[];
    for (var i = 1; i < path.length; i++) {
      final m = byId[path[i].$1];
      hops.add(KinHop(edge: path[i].$2!, gender: m?.gender ?? 'male'));
    }
    final term = Kinship.relationLabel(hops);
    final target = byId[path.last.$1];
    final targetMale = target?.isMale ?? true;

    final chain = <Widget>[];
    for (var i = 0; i < path.length; i++) {
      final m = byId[path[i].$1];
      chain.add(_Step(char: _initial(m), name: i == 0 ? 'أنت' : (m?.firstName ?? ''), you: i == 0));
      if (i < path.length - 1) chain.add(_Link(label: Kinship.linkLabel(hops, i)));
    }

    return Column(children: [
      if (showHeadline && target != null) ...[
        Text.rich(
          TextSpan(children: [
            TextSpan(text: '${target.firstName} ${targetMale ? 'هو' : 'هي'} ', style: ui(size: 14, color: AppColors.muted)),
            TextSpan(text: term, style: brand(size: 24, weight: FontWeight.w700, color: AppColors.primary)),
          ]),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
      ],
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        reverse: true,
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: chain),
      ),
      const SizedBox(height: 14),
      const Divider(height: 1),
      const SizedBox(height: 10),
      Text('درجة القرابة ${Kinship.degree(path.length - 1)}', style: ui(size: 12.5, color: AppColors.muted)),
    ]);
  }
}

class _Step extends StatelessWidget {
  final String char;
  final String name;
  final bool you;
  const _Step({required this.char, required this.name, this.you = false});

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 64,
        child: Column(children: [
          Avatar(char: char, you: you, line: !you, size: 46),
          const SizedBox(height: 5),
          Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: ui(size: 11.5, weight: FontWeight.w600, color: you ? AppColors.ink : AppColors.muted)),
        ]),
      );
}

class _Link extends StatelessWidget {
  final String label;
  const _Link({required this.label});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Column(children: [
          Text(label, style: ui(size: 10, weight: FontWeight.w700, color: AppColors.accent)),
          Icon(AppIcons.of('back'), size: 18, color: AppColors.faint),
        ]),
      );
}
