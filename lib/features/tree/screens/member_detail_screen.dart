import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_avatar.dart';
import '../models/member.dart';
import '../providers/tree_provider.dart';

class MemberDetailScreen extends ConsumerWidget {
  final String memberId;
  const MemberDetailScreen({super.key, required this.memberId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final memberAsync = ref.watch(memberByIdProvider(memberId));
    final relsAsync = ref.watch(memberRelationshipsProvider(memberId));

    return Scaffold(
      body: memberAsync.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (member) {
          if (member == null) {
            return const Center(child: Text('Member not found'));
          }
          return _MemberDetailBody(member: member, relsAsync: relsAsync);
        },
      ),
    );
  }
}

class _MemberDetailBody extends ConsumerWidget {
  final Member member;
  final AsyncValue<MemberRelationships> relsAsync;

  const _MemberDetailBody({
    required this.member,
    required this.relsAsync,
  });

  Color get _headerColor {
    if (member.isDeceased) return AppColors.deceasedLight;
    return member.isMale ? AppColors.maleLight : AppColors.femaleLight;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CustomScrollView(
      slivers: [
        // Header
        SliverAppBar(
          expandedHeight: 260,
          pinned: true,
          backgroundColor: AppColors.surface,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            onPressed: () => context.pop(),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => context.push('/edit-member/${member.id}'),
            ),
          ],
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              color: _headerColor,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Gap(60),
                  AppAvatar(
                    photoUrl: member.photoUrl,
                    name: member.fullName,
                    gender: member.gender,
                    size: 90,
                    isDeceased: member.isDeceased,
                  ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
                  const Gap(12),
                  Text(
                    member.fullName,
                    style: Theme.of(context).textTheme.headlineMedium,
                    textAlign: TextAlign.center,
                  ).animate().fadeIn(delay: 100.ms),
                  if (member.fullNameAr != null) ...[
                    const Gap(4),
                    Text(
                      member.fullNameAr!,
                      style: GoogleFonts.cairo(
                        fontSize: 18,
                        color: AppColors.textSecondary,
                      ),
                    ).animate().fadeIn(delay: 150.ms),
                  ],
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
                        _Badge(
                          label: 'Deceased',
                          color: AppColors.deceased,
                        ),
                      ],
                      if (member.age != null) ...[
                        const Gap(8),
                        _Badge(
                          label: '${member.age} yrs',
                          color: AppColors.textTertiary,
                        ),
                      ],
                    ],
                  ).animate().fadeIn(delay: 200.ms),
                ],
              ),
            ),
          ),
        ),
        // Info cards
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Dates & details
                if (member.birthDate != null ||
                    member.birthPlace != null ||
                    member.phone != null) ...[
                  _InfoCard(
                    title: 'Details',
                    children: [
                      if (member.birthDate != null)
                        _InfoRow(
                          icon: Icons.cake_outlined,
                          label: 'Born',
                          value:
                              '${member.birthDate!.day}/${member.birthDate!.month}/${member.birthDate!.year}',
                        ),
                      if (member.deathDate != null)
                        _InfoRow(
                          icon: Icons.hourglass_bottom_rounded,
                          label: 'Passed',
                          value:
                              '${member.deathDate!.day}/${member.deathDate!.month}/${member.deathDate!.year}',
                        ),
                      if (member.birthPlace != null)
                        _InfoRow(
                          icon: Icons.location_on_outlined,
                          label: 'From',
                          value: member.birthPlace!,
                        ),
                      if (member.phone != null)
                        _InfoRow(
                          icon: Icons.phone_outlined,
                          label: 'Phone',
                          value: member.phone!,
                        ),
                    ],
                  ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2),
                  const Gap(16),
                ],
                // Relationships
                relsAsync.when(
                  loading: () => const Center(
                      child:
                          CircularProgressIndicator(color: AppColors.primary)),
                  error: (e, _) => Text(e.toString()),
                  data: (rels) => _RelationshipsCard(
                    member: member,
                    rels: rels,
                  ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2),
                ),
                const Gap(16),
                if (member.notes != null)
                  _InfoCard(
                    title: 'Notes',
                    children: [
                      Text(
                        member.notes!,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2),
                const Gap(80),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _InfoCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
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
          Text(
            title.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.textTertiary,
                  letterSpacing: 1.2,
                ),
          ),
          const Gap(12),
          ...children,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const Gap(10),
          Text(
            '$label: ',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textTertiary,
                ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RelationshipsCard extends ConsumerWidget {
  final Member member;
  final MemberRelationships rels;
  const _RelationshipsCard({required this.member, required this.rels});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
              Text(
                'RELATIONSHIPS',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.textTertiary,
                      letterSpacing: 1.2,
                    ),
              ),
              TextButton.icon(
                onPressed: () =>
                    context.push('/add-relationship/${member.id}'),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add'),
                style: TextButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                ),
              ),
            ],
          ),
          const Gap(8),
          if (rels.parents.isNotEmpty)
            _RelGroup('Parents', rels.parents),
          if (rels.spouses.isNotEmpty)
            _RelGroup('Spouse', rels.spouses),
          if (rels.siblings.isNotEmpty)
            _RelGroup('Siblings', rels.siblings),
          if (rels.children.isNotEmpty)
            _RelGroup('Children', rels.children),
          if (rels.parents.isEmpty &&
              rels.spouses.isEmpty &&
              rels.siblings.isEmpty &&
              rels.children.isEmpty)
            Text(
              'No relationships added yet',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textTertiary,
                  ),
            ),
        ],
      ),
    );
  }
}

class _RelGroup extends StatelessWidget {
  final String title;
  final List<Member> members;
  const _RelGroup(this.title, this.members);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.labelMedium,
          ),
          const Gap(6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: members
                .map(
                  (m) => ActionChip(
                    avatar: CircleAvatar(
                      backgroundColor:
                          m.isMale ? AppColors.maleLight : AppColors.femaleLight,
                      child: Text(
                        m.fullName[0],
                        style: TextStyle(
                          fontSize: 12,
                          color: m.isMale ? AppColors.male : AppColors.female,
                        ),
                      ),
                    ),
                    label: Text(m.fullName),
                    onPressed: () => context.push('/member/${m.id}'),
                    backgroundColor: AppColors.surfaceVariant,
                    side: const BorderSide(color: AppColors.border),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}
