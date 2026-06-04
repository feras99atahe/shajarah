import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/relationship_labels.dart';
import '../../../shared/widgets/app_avatar.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/member.dart';
import '../models/relationship.dart';
import '../providers/tree_provider.dart';

class MemberDetailScreen extends ConsumerWidget {
  final String memberId;
  const MemberDetailScreen({super.key, required this.memberId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final memberAsync = ref.watch(memberByIdProvider(memberId));
    final relsAsync   = ref.watch(memberRelationshipsProvider(memberId));
    final connectedAsync = ref.watch(isConnectedToProvider(memberId));
    final roleAsync   = ref.watch(userRoleProvider);

    return Scaffold(
      body: memberAsync.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (member) {
          if (member == null) {
            return const Center(child: Text('Member not found'));
          }
          final isAdmin = roleAsync.valueOrNull == 'admin' ||
              roleAsync.valueOrNull == 'editor';
          final isConnected = connectedAsync.valueOrNull ?? false;
          // Show private fields if admin/editor, OR if viewer is connected
          final canSeePrivate = isAdmin || isConnected;

          return _DetailBody(
            member: member,
            relsAsync: relsAsync,
            canSeePrivate: canSeePrivate,
          );
        },
      ),
    );
  }
}

class _DetailBody extends ConsumerWidget {
  final Member member;
  final AsyncValue<MemberRelationships> relsAsync;
  final bool canSeePrivate;

  const _DetailBody({
    required this.member,
    required this.relsAsync,
    required this.canSeePrivate,
  });

  Color get _headerColor {
    if (member.isDeceased) return AppColors.deceasedLight;
    return member.isMale ? AppColors.maleLight : AppColors.femaleLight;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CustomScrollView(
      slivers: [
        // ── Hero header ───────────────────────────────────────────────────
        SliverAppBar(
          expandedHeight: 300,
          pinned: true,
          backgroundColor: AppColors.surface,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            onPressed: () => context.pop(),
          ),
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              color: _headerColor,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Gap(60),
                  AppAvatar(
                    photoUrl: member.photoUrl,
                    name: member.shortName,
                    gender: member.gender,
                    size: 90,
                    isDeceased: member.isDeceased,
                  ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
                  const Gap(12),
                  // Full four-part paternal name (always visible)
                  Text(
                    member.fullName,
                    style: Theme.of(context).textTheme.headlineMedium,
                    textAlign: TextAlign.center,
                  ).animate().fadeIn(delay: 100.ms),
                  const Gap(4),
                  // City always visible
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.location_city_outlined,
                          size: 14, color: AppColors.textSecondary),
                      const Gap(4),
                      Text(
                        member.city,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                    ],
                  ).animate().fadeIn(delay: 140.ms),
                  const Gap(8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _Badge(
                        label: member.isMale ? 'Male' : 'Female',
                        color: member.isMale ? AppColors.male : AppColors.female,
                      ),
                      if (member.isDeceased) ...[
                        const Gap(8),
                        _Badge(label: 'رحمه الله', color: AppColors.deceased),
                      ],
                      if (canSeePrivate &&
                          member.showBirthDate &&
                          member.age != null) ...[
                        const Gap(8),
                        _Badge(
                          label: '${member.age} yrs',
                          color: AppColors.textTertiary,
                        ),
                      ],
                    ],
                  ).animate().fadeIn(delay: 180.ms),
                ],
              ),
            ),
          ),
        ),

        // ── Content ───────────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // Paternal lineage (always visible)
                _InfoCard(
                  title: 'Paternal Lineage',
                  children: [
                    _InfoRow(icon: Icons.person_outline_rounded,
                        label: 'First name', value: member.firstName),
                    _InfoRow(icon: Icons.person_outline_rounded,
                        label: "Father's name", value: member.fatherName),
                    _InfoRow(icon: Icons.person_outline_rounded,
                        label: "Grandfather's name", value: member.grandfatherName),
                    _InfoRow(icon: Icons.family_restroom_rounded,
                        label: 'Family / Tribe', value: member.familyName),
                  ],
                ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2),
                const Gap(16),

                // Maternal name — private
                if (canSeePrivate && member.hasMotherName) ...[
                  _InfoCard(
                    title: 'Maternal Lineage',
                    badge: _PrivacyBadge(connected: canSeePrivate),
                    children: [
                      _InfoRow(
                        icon: Icons.person_outline_rounded,
                        label: "Mother's full name",
                        value: member.motherFullName,
                      ),
                    ],
                  ).animate().fadeIn(delay: 230.ms).slideY(begin: 0.2),
                  const Gap(16),
                ] else if (!canSeePrivate && member.hasMotherName) ...[
                  _LockedCard(label: "Mother's name is hidden").animate().fadeIn(delay: 230.ms),
                  const Gap(16),
                ],

                // Dates & details — birth date respects privacy toggle
                if (_hasVisibleDetails(member, canSeePrivate)) ...[
                  _InfoCard(
                    title: 'Details',
                    children: [
                      if (canSeePrivate && member.showBirthDate && member.birthDate != null)
                        _InfoRow(
                          icon: Icons.cake_outlined,
                          label: 'Born',
                          value: _formatDate(member.birthDate!),
                        ),
                      if (member.deathDate != null)
                        _InfoRow(
                          icon: Icons.hourglass_bottom_rounded,
                          label: 'Passed',
                          value: _formatDate(member.deathDate!),
                        ),
                      if (member.placeOfBirth != null)
                        _InfoRow(
                          icon: Icons.location_on_outlined,
                          label: 'Place of birth',
                          value: member.placeOfBirth!,
                        ),
                    ],
                  ).animate().fadeIn(delay: 260.ms).slideY(begin: 0.2),
                  const Gap(16),
                ],

                // Relationships
                relsAsync.when(
                  loading: () => const Center(
                      child: CircularProgressIndicator(color: AppColors.primary)),
                  error: (e, _) => Text(e.toString()),
                  data: (rels) => _RelationshipsCard(member: member, rels: rels)
                      .animate().fadeIn(delay: 300.ms).slideY(begin: 0.2),
                ),
                const Gap(16),

                if (member.notes != null)
                  _InfoCard(
                    title: 'Notes',
                    children: [
                      Text(member.notes!,
                          style: Theme.of(context).textTheme.bodyMedium),
                    ],
                  ).animate().fadeIn(delay: 340.ms).slideY(begin: 0.2),

                const Gap(80),
              ],
            ),
          ),
        ),
      ],
    );
  }

  bool _hasVisibleDetails(Member m, bool canSee) {
    if (canSee && m.showBirthDate && m.birthDate != null) return true;
    if (m.deathDate != null) return true;
    if (m.placeOfBirth != null) return true;
    return false;
  }

  String _formatDate(DateTime d) => '${d.day}/${d.month}/${d.year}';
}

// ── Relationships card ─────────────────────────────────────────────────────

class _RelationshipsCard extends ConsumerWidget {
  final Member member;
  final MemberRelationships rels;
  const _RelationshipsCard({required this.member, required this.rels});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final adjacencyAsync = ref.watch(adjacencyProvider);
    final membersAsync   = ref.watch(membersProvider);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('RELATIONSHIPS',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.textTertiary, letterSpacing: 1.2)),
              TextButton.icon(
                onPressed: () => context.push('/add-relationship/${member.id}'),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add'),
                style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4)),
              ),
            ],
          ),
          const Gap(8),
          if (rels.parents.isEmpty && rels.spouses.isEmpty &&
              rels.siblings.isEmpty && rels.children.isEmpty)
            Text('No relationships added yet',
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: AppColors.textTertiary))
          else ...[
            // Build member map + adjacency for kinship labels
            adjacencyAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
              data: (adj) => membersAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
                data: (allMembers) {
                  final memberMap = {for (final m in allMembers) m.id: m};
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final entry in [
                        (RelationshipType.parent, rels.parents),
                        (RelationshipType.spouse, rels.spouses),
                        (RelationshipType.sibling, rels.siblings),
                        (RelationshipType.child, rels.children),
                      ])
                        if ((entry.$2 as List<Member>).isNotEmpty)
                          _RelGroup(
                            title: relationshipGroupLabel(entry.$1, false),
                            members: entry.$2 as List<Member>,
                            viewerId: member.id,
                            adjacency: adj,
                            memberMap: memberMap,
                          ),
                    ],
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _RelGroup extends StatelessWidget {
  final String title;
  final List<Member> members;
  final String viewerId;
  final Map<String, List<(String, RelationshipType)>> adjacency;
  final Map<String, Member> memberMap;

  const _RelGroup({
    required this.title, required this.members, required this.viewerId,
    required this.adjacency, required this.memberMap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.labelMedium),
          const Gap(6),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: members.map((m) {
              final label = kinshipLabel(viewerId, m.id, adjacency, memberMap);
              return ActionChip(
                avatar: CircleAvatar(
                  backgroundColor:
                      m.isMale ? AppColors.maleLight : AppColors.femaleLight,
                  child: Text(m.firstName[0],
                      style: TextStyle(fontSize: 12,
                          color: m.isMale ? AppColors.male : AppColors.female)),
                ),
                label: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(m.shortName,
                        style: const TextStyle(fontSize: 13,
                            fontWeight: FontWeight.w600)),
                    Text(label,
                        style: const TextStyle(
                            fontSize: 10, color: AppColors.textTertiary)),
                  ],
                ),
                onPressed: () => context.push('/member/${m.id}'),
                backgroundColor: AppColors.surfaceVariant,
                side: const BorderSide(color: AppColors.border),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// ── Helper widgets ─────────────────────────────────────────────────────────

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Text(label,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
      );
}

class _PrivacyBadge extends StatelessWidget {
  final bool connected;
  const _PrivacyBadge({required this.connected});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: AppColors.successLight,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.verified_user_outlined,
              size: 12, color: AppColors.success),
          const Gap(4),
          const Text('Visible — connected',
              style: TextStyle(fontSize: 10, color: AppColors.success,
                  fontWeight: FontWeight.w600)),
        ]),
      );
}

class _LockedCard extends StatelessWidget {
  final String label;
  const _LockedCard({required this.label});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(children: [
          const Icon(Icons.lock_outline_rounded,
              size: 18, color: AppColors.textTertiary),
          const Gap(10),
          Text(label,
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: AppColors.textTertiary)),
        ]),
      );
}

class _InfoCard extends StatelessWidget {
  final String title;
  final List<Widget> children;
  final Widget? badge;
  const _InfoCard({required this.title, required this.children, this.badge});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text(title.toUpperCase(),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.textTertiary, letterSpacing: 1.2)),
            if (badge != null) ...[const Gap(8), badge!],
          ]),
          const Gap(12),
          ...children,
        ]),
      );
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const Gap(10),
          Text('$label: ',
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: AppColors.textTertiary)),
          Expanded(
            child: Text(value,
                style: Theme.of(context).textTheme.bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w500)),
          ),
        ]),
      );
}
