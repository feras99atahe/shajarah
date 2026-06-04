import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';
import '../../tree/providers/tree_provider.dart';

class FamilyUser {
  final String id;
  final String? fullName;
  final String? fullNameAr;
  final String role;
  final DateTime createdAt;

  const FamilyUser({
    required this.id,
    this.fullName,
    this.fullNameAr,
    required this.role,
    required this.createdAt,
  });

  factory FamilyUser.fromJson(Map<String, dynamic> j) => FamilyUser(
        id: j['id'] as String,
        fullName: j['full_name'] as String?,
        fullNameAr: j['full_name_ar'] as String?,
        role: j['role'] as String? ?? 'viewer',
        createdAt: DateTime.parse(j['created_at'] as String),
      );
}

class AdminStats {
  final int memberCount;
  final int userCount;
  final int aliveCount;
  final int deceasedCount;

  const AdminStats({
    required this.memberCount,
    required this.userCount,
    required this.aliveCount,
    required this.deceasedCount,
  });
}

final familyUsersProvider = FutureProvider<List<FamilyUser>>((ref) async {
  final familyId = await ref.watch(userFamilyIdProvider.future);
  if (familyId == null) return [];
  final supabase = ref.watch(supabaseProvider);
  final data = await supabase
      .from('user_profiles')
      .select('id, full_name, full_name_ar, role, created_at')
      .eq('family_id', familyId)
      .order('created_at');
  return (data as List)
      .map((e) => FamilyUser.fromJson(e as Map<String, dynamic>))
      .toList();
});

final adminStatsProvider = FutureProvider<AdminStats>((ref) async {
  final members = await ref.watch(membersProvider.future);
  final users = await ref.watch(familyUsersProvider.future);
  return AdminStats(
    memberCount: members.length,
    userCount: users.length,
    aliveCount: members.where((m) => !m.isDeceased).length,
    deceasedCount: members.where((m) => m.isDeceased).length,
  );
});

class AdminNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> setUserRole(String userId, String role) async {
    await ref.read(supabaseProvider).rpc('set_user_role', params: {
      'p_user_id': userId,
      'p_role': role,
    });
    ref.invalidate(familyUsersProvider);
  }

  Future<void> removeUser(String userId) async {
    await ref.read(supabaseProvider).rpc('remove_family_member_user', params: {
      'p_user_id': userId,
    });
    ref.invalidate(familyUsersProvider);
  }

  Future<void> updateFamily({
    required String familyId,
    required String name,
    String? nameAr,
    String? description,
  }) async {
    await ref.read(supabaseProvider).rpc('update_family', params: {
      'p_family_id': familyId,
      'p_name': name,
      'p_name_ar': nameAr,
      'p_description': description,
    });
    ref.invalidate(currentFamilyProvider);
  }
}

final adminNotifierProvider =
    AsyncNotifierProvider<AdminNotifier, void>(AdminNotifier.new);
