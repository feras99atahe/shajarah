import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../models/member.dart';
import '../models/relationship.dart';
import '../providers/tree_provider.dart';
import '../widgets/member_node_widget.dart';
import '../widgets/tree_painter.dart';

const _nodeW = 110.0;
const _nodeH = 140.0;
const _hGap = 24.0;
const _vGap = 80.0;

class TreeScreen extends ConsumerStatefulWidget {
  const TreeScreen({super.key});

  @override
  ConsumerState<TreeScreen> createState() => _TreeScreenState();
}

class _TreeScreenState extends ConsumerState<TreeScreen> {
  final _transformCtrl = TransformationController();
  int _currentTab = 0;

  @override
  void dispose() {
    _transformCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final membersAsync = ref.watch(membersProvider);
    final relsAsync = ref.watch(relationshipsProvider);
    final familyAsync = ref.watch(currentFamilyProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _Header(familyAsync: familyAsync),
          Expanded(
            child: membersAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
              error: (e, _) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline,
                        color: AppColors.error, size: 40),
                    const Gap(12),
                    Text(e.toString()),
                    TextButton(
                      onPressed: () => ref.invalidate(membersProvider),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
              data: (members) {
                if (members.isEmpty) {
                  return _EmptyTree(
                    onAddMember: () => context.push('/add-member'),
                  );
                }
                return relsAsync.when(
                  loading: () => const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                  error: (e, _) => Center(child: Text(e.toString())),
                  data: (rels) => _TreeCanvas(
                    members: members,
                    relationships: rels,
                    controller: _transformCtrl,
                  ),
                );
              },
            ),
          ),
          _BottomBar(
            currentTab: _currentTab,
            onTabChanged: (i) => setState(() => _currentTab = i),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/add-member'),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.person_add_rounded, color: Colors.white),
      ).animate().scale(delay: 500.ms, curve: Curves.elasticOut),
    );
  }
}

// ---------------------------------------------------------------------------
// Header
// ---------------------------------------------------------------------------
class _Header extends ConsumerWidget {
  final AsyncValue<dynamic> familyAsync;
  const _Header({required this.familyAsync});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      color: AppColors.surface,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        left: 20,
        right: 20,
        bottom: 12,
      ),
      child: Row(
        children: [
          const Text('🌳', style: TextStyle(fontSize: 28)),
          const Gap(10),
          Expanded(
            child: familyAsync.when(
              data: (family) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    family?.name ?? 'My Family',
                    style: Theme.of(context).textTheme.titleLarge,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (family?.nameAr != null)
                    Text(
                      family!.nameAr!,
                      style: GoogleFonts.cairo(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                ],
              ),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const Text('Family Tree'),
            ),
          ),
          // Reset zoom
          IconButton(
            icon: const Icon(Icons.center_focus_strong_rounded),
            color: AppColors.textSecondary,
            onPressed: () {},
            tooltip: 'Reset view',
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            color: AppColors.textSecondary,
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Tree canvas with pan/zoom
// ---------------------------------------------------------------------------
class _TreeCanvas extends StatefulWidget {
  final List<Member> members;
  final List<Relationship> relationships;
  final TransformationController controller;

  const _TreeCanvas({
    required this.members,
    required this.relationships,
    required this.controller,
  });

  @override
  State<_TreeCanvas> createState() => _TreeCanvasState();
}

class _TreeCanvasState extends State<_TreeCanvas> {
  late Map<String, Offset> _positions;
  late double _canvasW;
  late double _canvasH;

  @override
  void initState() {
    super.initState();
    _layout();
  }

  @override
  void didUpdateWidget(_TreeCanvas old) {
    super.didUpdateWidget(old);
    if (old.members != widget.members ||
        old.relationships != widget.relationships) {
      _layout();
    }
  }

  void _layout() {
    // Build adjacency for parent->child
    final children = <String, List<String>>{};
    final parents = <String, List<String>>{};
    for (final r in widget.relationships) {
      if (r.type == RelationshipType.child) {
        children.putIfAbsent(r.memberId, () => []).add(r.relatedMemberId);
      }
      if (r.type == RelationshipType.parent) {
        parents.putIfAbsent(r.memberId, () => []).add(r.relatedMemberId);
      }
    }

    // Find roots (members with no parents)
    final roots = widget.members
        .where((m) => (parents[m.id] ?? []).isEmpty)
        .map((m) => m.id)
        .toList();

    if (roots.isEmpty && widget.members.isNotEmpty) {
      roots.add(widget.members.first.id);
    }

    // BFS level assignment
    final levels = <String, int>{};
    final queue = <String>[...roots];
    for (final r in roots) levels[r] = 0;
    while (queue.isNotEmpty) {
      final id = queue.removeAt(0);
      final level = levels[id]!;
      for (final childId in children[id] ?? []) {
        if (!levels.containsKey(childId)) {
          levels[childId] = level + 1;
          queue.add(childId);
        }
      }
    }
    // Assign any disconnected members to level 0
    for (final m in widget.members) {
      levels.putIfAbsent(m.id, () => 0);
    }

    // Group by level
    final byLevel = <int, List<String>>{};
    for (final entry in levels.entries) {
      byLevel.putIfAbsent(entry.value, () => []).add(entry.key);
    }

    // Calculate positions
    final maxLevel = byLevel.keys.fold(0, (a, b) => a > b ? a : b);
    _canvasH = (maxLevel + 1) * (_nodeH + _vGap) + 40;

    double maxRow = 0;
    for (final row in byLevel.values) {
      if (row.length > maxRow) maxRow = row.length.toDouble();
    }
    _canvasW = maxRow * (_nodeW + _hGap) + 40;

    _positions = {};
    for (final entry in byLevel.entries) {
      final level = entry.key;
      final ids = entry.value;
      final rowWidth = ids.length * (_nodeW + _hGap) - _hGap;
      final startX = (_canvasW - rowWidth) / 2;
      for (int i = 0; i < ids.length; i++) {
        _positions[ids[i]] = Offset(
          startX + i * (_nodeW + _hGap) + _nodeW / 2,
          20 + level * (_nodeH + _vGap) + _nodeH / 2,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return InteractiveViewer(
      transformationController: widget.controller,
      minScale: 0.3,
      maxScale: 3.0,
      constrained: false,
      child: SizedBox(
        width: _canvasW.clamp(400, 4000),
        height: _canvasH.clamp(400, 4000),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Connection lines
            Positioned.fill(
              child: CustomPaint(
                painter: TreePainter(
                  positions: _positions,
                  relationships: widget.relationships,
                  members: widget.members,
                ),
              ),
            ),
            // Member nodes
            ...widget.members.map((member) {
              final pos = _positions[member.id];
              if (pos == null) return const SizedBox.shrink();
              return Positioned(
                left: pos.dx - _nodeW / 2,
                top: pos.dy - _nodeH / 2,
                width: _nodeW,
                height: _nodeH,
                child: MemberNodeWidget(
                  member: member,
                ).animate().fadeIn(duration: 400.ms).scale(
                      begin: const Offset(0.7, 0.7),
                      duration: 400.ms,
                      curve: Curves.easeOutBack,
                    ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Empty state
// ---------------------------------------------------------------------------
class _EmptyTree extends StatelessWidget {
  final VoidCallback onAddMember;
  const _EmptyTree({required this.onAddMember});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🌱', style: TextStyle(fontSize: 64))
              .animate()
              .scale(duration: 600.ms, curve: Curves.elasticOut),
          const Gap(20),
          Text(
            'Your tree is empty',
            style: Theme.of(context).textTheme.headlineMedium,
          ).animate().fadeIn(delay: 200.ms),
          const Gap(8),
          Text(
            'Add the first member to start\nbuilding your family tree',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ).animate().fadeIn(delay: 300.ms),
          const Gap(32),
          ElevatedButton.icon(
            onPressed: onAddMember,
            icon: const Icon(Icons.person_add_rounded),
            label: const Text('Add First Member'),
          ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.3),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Bottom nav
// ---------------------------------------------------------------------------
class _BottomBar extends StatelessWidget {
  final int currentTab;
  final ValueChanged<int> onTabChanged;
  const _BottomBar({required this.currentTab, required this.onTabChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          _NavItem(
            icon: Icons.account_tree_rounded,
            label: 'Tree',
            selected: currentTab == 0,
            onTap: () {
              onTabChanged(0);
            },
          ),
          _NavItem(
            icon: Icons.search_rounded,
            label: 'Search',
            selected: currentTab == 1,
            onTap: () {
              onTabChanged(1);
              context.push('/search');
            },
          ),
          _NavItem(
            icon: Icons.hub_rounded,
            label: 'Relations',
            selected: currentTab == 2,
            onTap: () {
              onTabChanged(2);
              context.push('/relationship');
            },
          ),
          _NavItem(
            icon: Icons.person_outline_rounded,
            label: 'Members',
            selected: currentTab == 3,
            onTap: () {
              onTabChanged(3);
              context.push('/members');
            },
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: selected ? AppColors.primary : AppColors.textTertiary,
                size: 22,
              ),
              const Gap(4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight:
                      selected ? FontWeight.w600 : FontWeight.w400,
                  color: selected ? AppColors.primary : AppColors.textTertiary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
