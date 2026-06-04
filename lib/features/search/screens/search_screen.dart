import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_avatar.dart';
import '../../tree/models/member.dart';
import '../../tree/providers/tree_provider.dart';

final _searchQueryProvider = StateProvider<String>((ref) => '');

final _searchResultsProvider = Provider<List<Member>>((ref) {
  final q = ref.watch(_searchQueryProvider).trim().toLowerCase();
  return ref.watch(membersProvider).when(
    data: (members) {
      if (q.isEmpty) return members;
      return members.where((m) {
        // Search across all four paternal name parts + city + place of birth
        return m.firstName.toLowerCase().contains(q) ||
            m.fatherName.toLowerCase().contains(q) ||
            m.grandfatherName.toLowerCase().contains(q) ||
            m.familyName.toLowerCase().contains(q) ||
            m.fullName.toLowerCase().contains(q) ||
            m.city.toLowerCase().contains(q) ||
            (m.placeOfBirth?.toLowerCase().contains(q) ?? false);
      }).toList();
    },
    loading: () => [],
    error: (_, __) => [],
  );
});

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _ctrl  = TextEditingController();
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _focus.requestFocus());
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final results = ref.watch(_searchResultsProvider);
    final query   = ref.watch(_searchQueryProvider);

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _ctrl,
          focusNode: _focus,
          onChanged: (v) =>
              ref.read(_searchQueryProvider.notifier).state = v,
          decoration: InputDecoration(
            hintText: 'Search by name, city, place of birth…',
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            hintStyle: Theme.of(context)
                .textTheme
                .bodyLarge
                ?.copyWith(color: AppColors.textTertiary),
          ),
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
        actions: [
          if (query.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.close_rounded),
              onPressed: () {
                _ctrl.clear();
                ref.read(_searchQueryProvider.notifier).state = '';
              },
            ),
        ],
      ),
      body: results.isEmpty
          ? _EmptySearch(hasQuery: query.isNotEmpty)
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: results.length,
              itemBuilder: (context, i) {
                final m = results[i];
                return _MemberTile(member: m)
                    .animate()
                    .fadeIn(delay: (i * 30).ms)
                    .slideX(begin: 0.1);
              },
            ),
    );
  }
}

class _MemberTile extends StatelessWidget {
  final Member member;
  const _MemberTile({required this.member});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      leading: AppAvatar(
        photoUrl: member.photoUrl,
        name: member.shortName,
        gender: member.gender,
        size: 48,
        isDeceased: member.isDeceased,
      ),
      title: Text(member.fullName,
          style: Theme.of(context).textTheme.titleMedium),
      subtitle: Row(
        children: [
          const Icon(Icons.location_city_outlined,
              size: 12, color: AppColors.textTertiary),
          const Gap(4),
          Text(member.city,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppColors.textTertiary)),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: member.isMale ? AppColors.maleLight : AppColors.femaleLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              member.isMale ? '♂' : '♀',
              style: TextStyle(
                color: member.isMale ? AppColors.male : AppColors.female,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const Gap(4),
          const Icon(Icons.chevron_right_rounded, color: AppColors.textTertiary),
        ],
      ),
      onTap: () => context.push('/member/${member.id}'),
    );
  }
}

class _EmptySearch extends StatelessWidget {
  final bool hasQuery;
  const _EmptySearch({required this.hasQuery});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(hasQuery ? '🔍' : '👥',
                  style: const TextStyle(fontSize: 56))
              .animate()
              .scale(duration: 400.ms, curve: Curves.easeOutBack),
          const Gap(16),
          Text(
            hasQuery ? 'No members found' : 'Search your family tree',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const Gap(8),
          Text(
            hasQuery
                ? 'Try a different name or city'
                : 'Search by first name, family name, city, or place of birth',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
