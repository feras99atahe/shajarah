import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_avatar.dart';
import '../../../shared/widgets/app_button.dart';
import '../../tree/models/member.dart';
import '../../tree/models/relationship.dart';
import '../../tree/providers/tree_provider.dart';

class RelationshipFinderScreen extends ConsumerStatefulWidget {
  const RelationshipFinderScreen({super.key});

  @override
  ConsumerState<RelationshipFinderScreen> createState() =>
      _RelationshipFinderScreenState();
}

class _RelationshipFinderScreenState
    extends ConsumerState<RelationshipFinderScreen> {
  Member? _memberA;
  Member? _memberB;
  List<_PathStep>? _result;
  bool _isSearching = false;

  void _pickMember(bool isA) async {
    final members = await ref.read(membersProvider.future);
    if (!mounted) return;
    final picked = await showModalBottomSheet<Member>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _MemberPicker(members: members),
    );
    if (picked == null) return;
    setState(() {
      if (isA) {
        _memberA = picked;
      } else {
        _memberB = picked;
      }
      _result = null;
    });
  }

  Future<void> _findRelationship() async {
    if (_memberA == null || _memberB == null) return;
    setState(() {
      _isSearching = true;
      _result = null;
    });
    try {
      final adjacency = await ref.read(adjacencyProvider.future);
      final path = _bfsPath(adjacency, _memberA!.id, _memberB!.id);
      final members = await ref.read(membersProvider.future);
      final memberMap = {for (final m in members) m.id: m};
      setState(() {
        if (path == null) {
          _result = [];
        } else {
          _result = path.map((step) {
            final m = memberMap[step.memberId];
            return _PathStep(
              member: m!,
              relationshipType: step.relationshipType,
            );
          }).toList();
        }
      });
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  // BFS to find shortest relationship path
  List<_RawStep>? _bfsPath(
    Map<String, List<(String, RelationshipType)>> adjacency,
    String fromId,
    String toId,
  ) {
    if (fromId == toId) return [];

    final visited = <String>{fromId};
    final queue = <List<_RawStep>>[
      [_RawStep(memberId: fromId, relationshipType: null)],
    ];

    while (queue.isNotEmpty) {
      final path = queue.removeAt(0);
      final currentId = path.last.memberId;

      for (final entry in adjacency[currentId] ?? <(String, RelationshipType)>[]) {
        final nextId = entry.$1;
        final relType = entry.$2;
        if (visited.contains(nextId)) continue;
        final newPath = [
          ...path,
          _RawStep(memberId: nextId, relationshipType: relType),
        ];
        if (nextId == toId) return newPath;
        visited.add(nextId);
        queue.add(newPath);
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Find Relationship'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Discover how two family members are related',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ).animate().fadeIn(),
            const Gap(28),
            // Member A
            _MemberSelector(
              label: 'First Person',
              member: _memberA,
              onTap: () => _pickMember(true),
            ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.2),
            const Gap(12),
            const Center(
              child: Icon(Icons.swap_vert_rounded,
                  color: AppColors.textTertiary, size: 28),
            ),
            const Gap(12),
            // Member B
            _MemberSelector(
              label: 'Second Person',
              member: _memberB,
              onTap: () => _pickMember(false),
            ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2),
            const Gap(28),
            AppButton(
              label: 'Find Relationship',
              onPressed:
                  _memberA != null && _memberB != null ? _findRelationship : null,
              isLoading: _isSearching,
              icon: Icons.hub_rounded,
            ).animate().fadeIn(delay: 300.ms),
            const Gap(32),
            // Result
            if (_result != null)
              _ResultSection(
                memberA: _memberA!,
                memberB: _memberB!,
                path: _result!,
              ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.3),
          ],
        ),
      ),
    );
  }
}

class _RawStep {
  final String memberId;
  final RelationshipType? relationshipType;
  const _RawStep({required this.memberId, required this.relationshipType});
}

class _PathStep {
  final Member member;
  final RelationshipType? relationshipType;
  const _PathStep({required this.member, required this.relationshipType});
}

// ---------------------------------------------------------------------------
// Member selector widget
// ---------------------------------------------------------------------------
class _MemberSelector extends StatelessWidget {
  final String label;
  final Member? member;
  final VoidCallback onTap;

  const _MemberSelector({
    required this.label,
    this.member,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: member != null ? AppColors.primary : AppColors.border,
            width: member != null ? 1.5 : 1,
          ),
        ),
        child: member == null
            ? Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.person_add_rounded,
                        color: AppColors.primary),
                  ),
                  const Gap(12),
                  Text(
                    label,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                  const Spacer(),
                  const Icon(Icons.chevron_right_rounded,
                      color: AppColors.textTertiary),
                ],
              )
            : Row(
                children: [
                  AppAvatar(
                    photoUrl: member!.photoUrl,
                    name: member!.fullName,
                    gender: member!.gender,
                    size: 48,
                    isDeceased: member!.isDeceased,
                  ),
                  const Gap(12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          member!.fullName,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        if (member!.fullNameAr != null)
                          Text(
                            member!.fullNameAr!,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                      ],
                    ),
                  ),
                  const Icon(Icons.edit_outlined,
                      color: AppColors.primary, size: 18),
                ],
              ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Result display
// ---------------------------------------------------------------------------
class _ResultSection extends StatelessWidget {
  final Member memberA;
  final Member memberB;
  final List<_PathStep> path;

  const _ResultSection({
    required this.memberA,
    required this.memberB,
    required this.path,
  });

  String _relLabel(RelationshipType? type) {
    switch (type) {
      case RelationshipType.parent:
        return 'is parent of';
      case RelationshipType.child:
        return 'is child of';
      case RelationshipType.spouse:
        return 'is spouse of';
      case RelationshipType.sibling:
        return 'is sibling of';
      case null:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (path.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.warningLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.warning.withOpacity(0.4)),
        ),
        child: Row(
          children: [
            const Icon(Icons.info_outline, color: AppColors.warning),
            const Gap(12),
            Expanded(
              child: Text(
                'No relationship found between these two members.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      );
    }

    final hops = path.length - 1;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Relationship Path',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const Gap(4),
        Text(
          '$hops step${hops == 1 ? '' : 's'} apart',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textTertiary,
              ),
        ),
        const Gap(16),
        ...List.generate(path.length, (i) {
          final step = path[i];
          final isLast = i == path.length - 1;
          return Column(
            children: [
              _StepTile(member: step.member, isFirst: i == 0, isLast: isLast),
              if (!isLast)
                Padding(
                  padding: const EdgeInsets.only(left: 36),
                  child: Row(
                    children: [
                      Container(
                        width: 2,
                        height: 28,
                        color: AppColors.primary.withOpacity(0.3),
                      ),
                      const Gap(12),
                      Text(
                        _relLabel(path[i + 1].relationshipType),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                    ],
                  ),
                ),
            ],
          );
        }),
      ],
    );
  }
}

class _StepTile extends StatelessWidget {
  final Member member;
  final bool isFirst;
  final bool isLast;

  const _StepTile({
    required this.member,
    this.isFirst = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isFirst || isLast ? AppColors.primaryContainer : AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isFirst || isLast ? AppColors.primary : AppColors.border,
        ),
      ),
      child: Row(
        children: [
          AppAvatar(
            photoUrl: member.photoUrl,
            name: member.fullName,
            gender: member.gender,
            size: 40,
            isDeceased: member.isDeceased,
          ),
          const Gap(12),
          Expanded(
            child: Text(
              member.fullName,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          if (isFirst)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'A',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          if (isLast)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.accent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'B',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Member picker bottom sheet
// ---------------------------------------------------------------------------
class _MemberPicker extends ConsumerStatefulWidget {
  final List<Member> members;
  const _MemberPicker({required this.members});

  @override
  ConsumerState<_MemberPicker> createState() => _MemberPickerState();
}

class _MemberPickerState extends ConsumerState<_MemberPicker> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final filtered = widget.members.where((m) {
      if (_query.isEmpty) return true;
      return m.fullName.toLowerCase().contains(_query.toLowerCase()) ||
          (m.fullNameAr?.contains(_query) ?? false);
    }).toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      expand: false,
      builder: (context, scrollCtrl) {
        return Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: TextField(
                autofocus: true,
                onChanged: (v) => setState(() => _query = v),
                decoration: const InputDecoration(
                  hintText: 'Search...',
                  prefixIcon: Icon(Icons.search_rounded),
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: scrollCtrl,
                itemCount: filtered.length,
                itemBuilder: (context, i) {
                  final m = filtered[i];
                  return ListTile(
                    leading: AppAvatar(
                      photoUrl: m.photoUrl,
                      name: m.fullName,
                      gender: m.gender,
                      size: 40,
                    ),
                    title: Text(m.fullName),
                    subtitle: m.fullNameAr != null ? Text(m.fullNameAr!) : null,
                    onTap: () => Navigator.of(context).pop(m),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
