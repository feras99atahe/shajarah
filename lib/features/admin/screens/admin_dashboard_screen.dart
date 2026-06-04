import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_avatar.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../auth/providers/auth_provider.dart';
import '../../tree/models/family.dart' as family_model;
import '../../tree/providers/tree_provider.dart';
import '../providers/admin_provider.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roleAsync = ref.watch(userRoleProvider);
    return roleAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      ),
      error: (e, _) => Scaffold(body: Center(child: Text(e.toString()))),
      data: (role) {
        if (role != 'admin') {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Admin'),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded),
                onPressed: () => context.pop(),
              ),
            ),
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.lock_outline_rounded,
                      size: 64, color: AppColors.textTertiary),
                  const Gap(16),
                  Text('Access Denied',
                      style: Theme.of(context).textTheme.headlineSmall),
                  const Gap(8),
                  Text(
                    'Admin privileges required',
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: AppColors.textTertiary),
                  ),
                ],
              ),
            ),
          );
        }
        return const _AdminTabs();
      },
    );
  }
}

// ── Tabs shell ──────────────────────────────────────────────────────────────

class _AdminTabs extends StatelessWidget {
  const _AdminTabs();

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Admin Dashboard'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            onPressed: () => context.pop(),
          ),
          bottom: const TabBar(
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textTertiary,
            indicatorColor: AppColors.primary,
            tabs: [
              Tab(icon: Icon(Icons.dashboard_outlined), text: 'Overview'),
              Tab(icon: Icon(Icons.people_outline_rounded), text: 'Users'),
              Tab(icon: Icon(Icons.family_restroom_rounded), text: 'Members'),
              Tab(icon: Icon(Icons.tune_rounded), text: 'Family'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _OverviewTab(),
            _UsersTab(),
            _MembersTab(),
            _FamilySettingsTab(),
          ],
        ),
      ),
    );
  }
}

// ── Overview ────────────────────────────────────────────────────────────────

class _OverviewTab extends ConsumerWidget {
  const _OverviewTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(adminStatsProvider);
    final membersAsync = ref.watch(membersProvider);

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Gap(4),
        statsAsync.when(
          loading: () => const Center(
              child: CircularProgressIndicator(color: AppColors.primary)),
          error: (e, _) => Text(e.toString()),
          data: (stats) => GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.35,
            children: [
              _StatCard(
                label: 'Tree Members',
                value: stats.memberCount,
                icon: Icons.account_tree_rounded,
                color: AppColors.primary,
              ).animate().fadeIn().slideY(begin: 0.2),
              _StatCard(
                label: 'App Users',
                value: stats.userCount,
                icon: Icons.people_rounded,
                color: AppColors.accent,
              ).animate().fadeIn(delay: 50.ms).slideY(begin: 0.2),
              _StatCard(
                label: 'Alive',
                value: stats.aliveCount,
                icon: Icons.favorite_rounded,
                color: AppColors.success,
              ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.2),
              _StatCard(
                label: 'Deceased',
                value: stats.deceasedCount,
                icon: Icons.star_rounded,
                color: AppColors.deceased,
              ).animate().fadeIn(delay: 150.ms).slideY(begin: 0.2),
            ],
          ),
        ),
        const Gap(20),
        _DetectRelationshipsButton()
            .animate().fadeIn(delay: 200.ms).slideY(begin: 0.2),
        const Gap(28),
        Text(
          'RECENTLY ADDED',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.textTertiary,
                letterSpacing: 1.2,
              ),
        ),
        const Gap(10),
        membersAsync.when(
          loading: () => const Center(
              child: CircularProgressIndicator(color: AppColors.primary)),
          error: (e, _) => Text(e.toString()),
          data: (members) {
            if (members.isEmpty) {
              return Padding(
                padding: const EdgeInsets.only(top: 24),
                child: Center(
                  child: Text(
                    'No members yet',
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: AppColors.textTertiary),
                  ),
                ),
              );
            }
            final recent = [...members]
              ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
            final slice = recent.take(5).toList();
            return Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  for (var i = 0; i < slice.length; i++) ...[
                    if (i > 0) const Divider(height: 1, indent: 68),
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 4),
                      leading: AppAvatar(
                        photoUrl: slice[i].photoUrl,
                        name: slice[i].fullName,
                        gender: slice[i].gender,
                        size: 42,
                        isDeceased: slice[i].isDeceased,
                      ),
                      title: Text(
                        slice[i].fullName,
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        _timeAgo(slice[i].createdAt),
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: AppColors.textTertiary),
                      ),
                      trailing: const Icon(Icons.chevron_right_rounded,
                          color: AppColors.textTertiary),
                      onTap: () => context.push('/member/${slice[i].id}'),
                    ).animate().fadeIn(delay: (i * 30).ms),
                  ],
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  String _timeAgo(DateTime dt) {
    final d = DateTime.now().difference(dt);
    if (d.inDays > 0) return '${d.inDays}d ago';
    if (d.inHours > 0) return '${d.inHours}h ago';
    if (d.inMinutes > 0) return '${d.inMinutes}m ago';
    return 'just now';
  }
}

// ── Users ────────────────────────────────────────────────────────────────────

class _UsersTab extends ConsumerWidget {
  const _UsersTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(familyUsersProvider);
    final currentUser = ref.watch(currentUserProvider);

    return usersAsync.when(
      loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary)),
      error: (e, _) => Center(child: Text(e.toString())),
      data: (users) {
        if (users.isEmpty) {
          return Center(
            child: Text(
              'No users',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AppColors.textTertiary),
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: users.length,
          separatorBuilder: (_, __) => const Divider(height: 1, indent: 72),
          itemBuilder: (context, i) {
            final user = users[i];
            final isSelf = user.id == currentUser?.id;
            return ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              leading: CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.primaryContainer,
                child: Text(
                  (user.fullName?.isNotEmpty == true
                          ? user.fullName![0]
                          : '?')
                      .toUpperCase(),
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),
              ),
              title: Row(
                children: [
                  Flexible(
                    child: Text(
                      user.fullName ?? 'Unknown',
                      style: Theme.of(context)
                          .textTheme
                          .bodyLarge
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                  if (isSelf) ...[
                    const Gap(6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'You',
                        style: TextStyle(
                            fontSize: 11,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ],
              ),
              subtitle: Text(
                'Joined ${_timeAgo(user.createdAt)}',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: AppColors.textTertiary),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _RoleChip(role: user.role),
                  if (!isSelf) ...[
                    const Gap(4),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert_rounded,
                          color: AppColors.textTertiary, size: 20),
                      onSelected: (value) =>
                          _handleAction(context, ref, user, value),
                      itemBuilder: (_) => [
                        const PopupMenuItem(
                            value: 'admin', child: Text('Make Admin')),
                        const PopupMenuItem(
                            value: 'editor', child: Text('Make Editor')),
                        const PopupMenuItem(
                            value: 'viewer', child: Text('Make Viewer')),
                        const PopupMenuDivider(),
                        PopupMenuItem(
                          value: 'remove',
                          child: Text(
                            'Remove from family',
                            style: TextStyle(color: AppColors.error),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ).animate().fadeIn(delay: (i * 30).ms).slideX(begin: 0.05);
          },
        );
      },
    );
  }

  String _timeAgo(DateTime dt) {
    final d = DateTime.now().difference(dt);
    if (d.inDays > 0) return '${d.inDays}d ago';
    if (d.inHours > 0) return '${d.inHours}h ago';
    return 'recently';
  }

  Future<void> _handleAction(
    BuildContext context,
    WidgetRef ref,
    FamilyUser user,
    String action,
  ) async {
    if (action == 'remove') {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Remove User'),
          content: Text(
              'Remove ${user.fullName ?? 'this user'} from the family?'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style:
                  ElevatedButton.styleFrom(backgroundColor: AppColors.error),
              child: const Text('Remove'),
            ),
          ],
        ),
      );
      if (confirm != true || !context.mounted) return;
    }
    try {
      if (action == 'remove') {
        await ref.read(adminNotifierProvider.notifier).removeUser(user.id);
      } else {
        await ref
            .read(adminNotifierProvider.notifier)
            .setUserRole(user.id, action);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString()),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }
}

// ── Members ──────────────────────────────────────────────────────────────────

class _MembersTab extends ConsumerStatefulWidget {
  const _MembersTab();

  @override
  ConsumerState<_MembersTab> createState() => _MembersTabState();
}

class _MembersTabState extends ConsumerState<_MembersTab> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final membersAsync = ref.watch(membersProvider);

    return membersAsync.when(
      loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary)),
      error: (e, _) => Center(child: Text(e.toString())),
      data: (members) {
        final filtered = _query.isEmpty
            ? members
            : members
                .where((m) =>
                    m.fullName
                        .toLowerCase()
                        .contains(_query.toLowerCase()) ||
                    (m.city.toLowerCase().contains(_query)))
                .toList();

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchCtrl,
                      onChanged: (v) => setState(() => _query = v),
                      decoration: InputDecoration(
                        hintText: 'Search members…',
                        prefixIcon: const Icon(Icons.search_rounded,
                            color: AppColors.textTertiary),
                        suffixIcon: _query.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded),
                                onPressed: () {
                                  _searchCtrl.clear();
                                  setState(() => _query = '');
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: AppColors.surface,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 0),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: AppColors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: AppColors.border),
                        ),
                      ),
                    ),
                  ),
                  const Gap(8),
                  OutlinedButton.icon(
                    onPressed: () => context.push('/admin/bulk-add'),
                    icon: const Icon(Icons.playlist_add_rounded, size: 18),
                    label: const Text('Bulk Add'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 46),
                      padding:
                          const EdgeInsets.symmetric(horizontal: 12),
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '${filtered.length} member${filtered.length != 1 ? 's' : ''}',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: AppColors.textTertiary),
                ),
              ),
            ),
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Text(
                        'No results',
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: AppColors.textTertiary),
                      ),
                    )
                  : ListView.separated(
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) =>
                          const Divider(height: 1, indent: 76),
                      itemBuilder: (context, i) {
                        final m = filtered[i];
                        return Dismissible(
                          key: ValueKey(m.id),
                          direction: DismissDirection.endToStart,
                          confirmDismiss: (_) =>
                              _confirmDelete(context, m.fullName),
                          onDismissed: (_) async {
                            try {
                              await ref
                                  .read(treeNotifierProvider.notifier)
                                  .deleteMember(m.id);
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context)
                                    .showSnackBar(SnackBar(
                                  content: Text(e.toString()),
                                  backgroundColor: AppColors.error,
                                  behavior: SnackBarBehavior.floating,
                                ));
                              }
                            }
                          },
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            color: AppColors.errorLight,
                            child: const Icon(Icons.delete_outline_rounded,
                                color: AppColors.error),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 4),
                            leading: AppAvatar(
                              photoUrl: m.photoUrl,
                              name: m.fullName,
                              gender: m.gender,
                              size: 44,
                              isDeceased: m.isDeceased,
                              onTap: () => context.push('/member/${m.id}'),
                            ),
                            title: Text(
                              m.fullName,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: m.isDeceased
                                        ? AppColors.textTertiary
                                        : AppColors.textPrimary,
                                  ),
                            ),
                            subtitle: true
                                ? Text(m.city,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall)
                                : null,
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (m.age != null)
                                  Text(
                                    '${m.age} yrs',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                            color: AppColors.textTertiary),
                                  ),
                                const Gap(4),
                                const Icon(Icons.chevron_right_rounded,
                                    color: AppColors.textTertiary),
                              ],
                            ),
                            onTap: () => context.push('/member/${m.id}'),
                          )
                              .animate()
                              .fadeIn(delay: (i * 15).ms)
                              .slideX(begin: 0.05),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Future<bool> _confirmDelete(BuildContext context, String name) async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Delete Member'),
            content: Text(
                'Delete $name? This will also remove all their relationships.'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;
  }
}

// ── Family Settings ───────────────────────────────────────────────────────────

class _FamilySettingsTab extends ConsumerStatefulWidget {
  const _FamilySettingsTab();

  @override
  ConsumerState<_FamilySettingsTab> createState() => _FamilySettingsTabState();
}

class _FamilySettingsTabState extends ConsumerState<_FamilySettingsTab> {
  final _nameCtrl = TextEditingController();
  final _nameArCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _initialized = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _nameArCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  void _initFrom(family_model.Family family) {
    if (_initialized) return;
    _nameCtrl.text = family.name;
    _nameArCtrl.text = family.nameAr ?? '';
    _descCtrl.text = family.description ?? '';
    _initialized = true;
  }

  Future<void> _save(String familyId) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await ref.read(adminNotifierProvider.notifier).updateFamily(
            familyId: familyId,
            name: _nameCtrl.text.trim(),
            nameAr: _nameArCtrl.text.trim().isEmpty
                ? null
                : _nameArCtrl.text.trim(),
            description: _descCtrl.text.trim().isEmpty
                ? null
                : _descCtrl.text.trim(),
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Family settings saved'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString()),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final familyAsync = ref.watch(currentFamilyProvider);

    return familyAsync.when(
      loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary)),
      error: (e, _) => Center(child: Text(e.toString())),
      data: (family) {
        if (family == null) {
          return Center(
            child: Text(
              'No family found',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AppColors.textTertiary),
            ),
          );
        }
        _initFrom(family);
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'FAMILY INFO',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.textTertiary,
                        letterSpacing: 1.2,
                      ),
                ),
                const Gap(12),
                AppTextField(
                  label: 'Family name',
                  controller: _nameCtrl,
                  validator: (v) =>
                      v != null && v.trim().isNotEmpty ? null : 'Required',
                ).animate().fadeIn(delay: 50.ms).slideY(begin: 0.2),
                const Gap(12),
                AppTextField(
                  label: 'اسم العائلة (Arabic)',
                  controller: _nameArCtrl,
                  textDirection: TextDirection.rtl,
                ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.2),
                const Gap(12),
                AppTextField(
                  label: 'Description',
                  controller: _descCtrl,
                  maxLines: 3,
                ).animate().fadeIn(delay: 150.ms).slideY(begin: 0.2),
                const Gap(32),
                AppButton(
                  label: 'Save Changes',
                  onPressed: () => _save(family.id),
                  isLoading: _isLoading,
                ).animate().fadeIn(delay: 200.ms),
                const Gap(32),
                Text(
                  'DETAILS',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.textTertiary,
                        letterSpacing: 1.2,
                      ),
                ),
                const Gap(10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _DetailRow(
                        label: 'Family ID',
                        value: family.id,
                        mono: true,
                      ),
                      const Divider(height: 20),
                      _DetailRow(
                        label: 'Created',
                        value:
                            '${family.createdAt.day}/${family.createdAt.month}/${family.createdAt.year}',
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 250.ms),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── Shared widgets ───────────────────────────────────────────────────────────

// ── Detect Relationships button ───────────────────────────────────────────────

class _DetectRelationshipsButton extends ConsumerStatefulWidget {
  const _DetectRelationshipsButton();

  @override
  ConsumerState<_DetectRelationshipsButton> createState() =>
      _DetectRelationshipsButtonState();
}

class _DetectRelationshipsButtonState
    extends ConsumerState<_DetectRelationshipsButton> {
  bool _running = false;

  Future<void> _run() async {
    setState(() => _running = true);
    try {
      final count = await ref
          .read(treeNotifierProvider.notifier)
          .autoDetectRelationships();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(count > 0
              ? '$count new relationship${count == 1 ? '' : 's'} detected and linked'
              : 'No new relationships found — tree is up to date'),
          backgroundColor:
              count > 0 ? AppColors.success : AppColors.textTertiary,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString()),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } finally {
      if (mounted) setState(() => _running = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: AppColors.primaryContainer,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.hub_rounded,
                color: AppColors.primary, size: 22),
          ),
          const Gap(12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Auto-Detect Relationships',
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.w600)),
                Text(
                  'Scan all members and link by paternal & maternal names',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: AppColors.textTertiary),
                ),
              ],
            ),
          ),
          const Gap(12),
          FilledButton(
            onPressed: _running ? null : _run,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              minimumSize: const Size(0, 36),
              padding: const EdgeInsets.symmetric(horizontal: 14),
            ),
            child: _running
                ? const SizedBox(
                    width: 16, height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Text('Run'),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final int value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value.toString(),
                style: GoogleFonts.reemKufi(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  height: 1,
                ),
              ),
              Text(
                label,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: AppColors.textTertiary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RoleChip extends StatelessWidget {
  final String role;
  const _RoleChip({required this.role});

  @override
  Widget build(BuildContext context) {
    final (color, bg, label) = switch (role) {
      'admin' => (AppColors.error, AppColors.errorLight, 'Admin'),
      'editor' => (AppColors.accent, AppColors.accentLight, 'Editor'),
      _ => (AppColors.textSecondary, AppColors.surfaceVariant, 'Viewer'),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
            fontSize: 12, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool mono;

  const _DetailRow({required this.label, required this.value, this.mono = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context)
              .textTheme
              .labelSmall
              ?.copyWith(color: AppColors.textTertiary, letterSpacing: 1),
        ),
        const Gap(4),
        SelectableText(
          value,
          style: mono
              ? TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  color: AppColors.textSecondary,
                )
              : Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}
