import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_avatar.dart';
import '../../tree/models/member.dart';
import '../../tree/models/relationship.dart';
import '../../tree/providers/tree_provider.dart';
import '../kinship.dart';

/// DROP-IN REPLACEMENT for
/// lib/features/relationship/screens/relationship_finder_screen.dart
///
/// Identical BFS + provider logic. Only the result is restyled into the
/// mockup's horizontal kinship chain with proper Arabic terms (عمّتك، جدّك …).
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

  // BFS to find shortest relationship path (unchanged)
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
      for (final entry
          in adjacency[currentId] ?? <(String, RelationshipType)>[]) {
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
      appBar: AppBar(title: const Text('مكتشف الصلات')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'اكتب اسمين، واعرف صلة القرابة بينهما',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AppColors.textSecondary),
            ).animate().fadeIn(),
            const Gap(24),
            _MemberSelector(
              label: 'الشخص الأول',
              member: _memberA,
              onTap: () => _pickMember(true),
            ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.2),
            const Gap(10),
            const Center(
              child: Icon(Icons.swap_vert_rounded,
                  color: AppColors.textTertiary, size: 26),
            ),
            const Gap(10),
            _MemberSelector(
              label: 'الشخص الثاني',
              member: _memberB,
              onTap: () => _pickMember(false),
            ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2),
            const Gap(24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _memberA != null && _memberB != null
                    ? _findRelationship
                    : null,
                icon: _isSearching
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.5, color: Colors.white),
                      )
                    : const Icon(Icons.hub_rounded, size: 20),
                label: const Text('اكتشف الصلة'),
              ),
            ).animate().fadeIn(delay: 300.ms),
            const Gap(28),
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

// ── Member selector (restyled, Arabic) ────────────────────────────────────
class _MemberSelector extends StatelessWidget {
  final String label;
  final Member? member;
  final VoidCallback onTap;
  const _MemberSelector(
      {required this.label, this.member, required this.onTap});

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
            color: member != null ? AppColors.primary : AppColors.border,
            width: member != null ? 1.5 : 1,
          ),
        ),
        child: member == null
            ? Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: const BoxDecoration(
                      color: AppColors.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child:
                        const Icon(Icons.person_add_rounded, color: AppColors.primary),
                  ),
                  const Gap(12),
                  Text(label,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(color: AppColors.textSecondary)),
                  const Spacer(),
                  const Icon(Icons.chevron_left_rounded,
                      color: AppColors.textTertiary),
                ],
              )
            : Row(
                children: [
                  AppAvatar(
                    photoUrl: member!.photoUrl,
                    name: member!.fullName,
                    gender: member!.gender,
                    size: 46,
                    isDeceased: member!.isDeceased,
                  ),
                  const Gap(12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(member!.displayName(true),
                            style: Theme.of(context).textTheme.titleMedium),
                        if (member!.fullNameAr != null)
                          Text(member!.fullName,
                              style: Theme.of(context).textTheme.bodySmall),
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

// ── Result: headline + horizontal kinship chain ───────────────────────────
class _ResultSection extends StatelessWidget {
  final Member memberA;
  final Member memberB;
  final List<_PathStep> path;
  const _ResultSection(
      {required this.memberA, required this.memberB, required this.path});

  @override
  Widget build(BuildContext context) {
    if (path.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(18),
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
              child: Text('لا توجد صلة معروفة بين هذين الفردين.',
                  style: Theme.of(context).textTheme.bodyMedium),
            ),
          ],
        ),
      );
    }

    // hops relative to A (skip the start node)
    final hops = [
      for (var i = 1; i < path.length; i++)
        KinHop(edge: path[i].relationshipType!, gender: path[i].member.gender)
    ];
    final term = Kinship.relationLabel(hops);
    final targetMale = memberB.gender == 'male';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('الصلة',
            style: GoogleFonts.ibmPlexSansArabic(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary)),
        const Gap(10),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              // headline: "<name> هو/هي <term>"
              Text.rich(
                TextSpan(children: [
                  TextSpan(
                    text: '${memberB.displayName(true)} ${targetMale ? 'هو' : 'هي'} ',
                    style: GoogleFonts.ibmPlexSansArabic(
                        fontSize: 14, color: AppColors.textSecondary),
                  ),
                  TextSpan(
                    text: term,
                    style: GoogleFonts.reemKufi(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary),
                  ),
                ]),
                textAlign: TextAlign.center,
              ),
              const Gap(16),
              // chain
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                reverse: true, // RTL: start from the right
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (var i = 0; i < path.length; i++) ...[
                      _ChainNode(
                        member: path[i].member,
                        isFirst: i == 0,
                        isLast: i == path.length - 1,
                      ),
                      if (i < path.length - 1)
                        _ChainLink(label: Kinship.linkLabel(hops, i)),
                    ],
                  ],
                ),
              ),
              const Gap(14),
              const Divider(height: 1),
              const Gap(10),
              Text(
                'درجة القرابة ${Kinship.degree(path.length - 1)}',
                style: GoogleFonts.ibmPlexSansArabic(
                    fontSize: 12.5, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ChainNode extends StatelessWidget {
  final Member member;
  final bool isFirst;
  final bool isLast;
  const _ChainNode(
      {required this.member, this.isFirst = false, this.isLast = false});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 64,
      child: Column(
        children: [
          AppAvatar(
            photoUrl: member.photoUrl,
            name: member.displayName(true),
            gender: member.gender,
            size: 46,
            isDeceased: member.isDeceased,
            isSelf: isFirst,
            isLineage: isLast,
          ),
          const Gap(6),
          Text(
            isFirst ? 'أنت' : member.displayName(true).split(' ').first,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: GoogleFonts.ibmPlexSansArabic(
              fontSize: 11.5,
              fontWeight: isFirst ? FontWeight.w700 : FontWeight.w600,
              color: isFirst ? AppColors.textPrimary : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChainLink extends StatelessWidget {
  final String label;
  const _ChainLink({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Column(
        children: [
          Text(label,
              style: GoogleFonts.ibmPlexSansArabic(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppColors.accent)),
          const Icon(Icons.chevron_left_rounded,
              size: 18, color: AppColors.textTertiary),
        ],
      ),
    );
  }
}

// ── Member picker (Arabic) ────────────────────────────────────────────────
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
                  hintText: 'ابحث بالاسم…',
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
                      name: m.displayName(true),
                      gender: m.gender,
                      size: 40,
                    ),
                    title: Text(m.displayName(true)),
                    subtitle: m.fullNameAr != null ? Text(m.fullName) : null,
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
