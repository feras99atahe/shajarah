import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../models/member.dart';
import '../models/relationship.dart';
import '../models/family.dart' as family_model;

// ---------------------------------------------------------------------------
// Family
// ---------------------------------------------------------------------------

final currentFamilyProvider = FutureProvider<family_model.Family?>((ref) async {
  final familyId = await ref.watch(userFamilyIdProvider.future);
  if (familyId == null) return null;
  final supabase = ref.watch(supabaseProvider);
  final data = await supabase
      .from('families')
      .select()
      .eq('id', familyId)
      .maybeSingle();
  if (data == null) return null;
  return family_model.Family.fromJson(data);
});

// ---------------------------------------------------------------------------
// Members
// ---------------------------------------------------------------------------

final membersProvider = FutureProvider<List<Member>>((ref) async {
  final familyId = await ref.watch(userFamilyIdProvider.future);
  if (familyId == null) return [];
  final supabase = ref.watch(supabaseProvider);
  final data = await supabase
      .from('members')
      .select()
      .eq('family_id', familyId)
      .order('created_at');
  return (data as List).map((e) => Member.fromJson(e)).toList();
});

final memberByIdProvider =
    FutureProvider.family<Member?, String>((ref, id) async {
  final members = await ref.watch(membersProvider.future);
  try {
    return members.firstWhere((m) => m.id == id);
  } catch (_) {
    return null;
  }
});

// ---------------------------------------------------------------------------
// Relationships
// ---------------------------------------------------------------------------

final relationshipsProvider = FutureProvider<List<Relationship>>((ref) async {
  final familyId = await ref.watch(userFamilyIdProvider.future);
  if (familyId == null) return [];
  final supabase = ref.watch(supabaseProvider);
  // Get all member IDs for this family
  final memberData = await supabase
      .from('members')
      .select('id')
      .eq('family_id', familyId);
  final memberIds = (memberData as List).map((e) => e['id'] as String).toList();
  if (memberIds.isEmpty) return [];
  final data = await supabase
      .from('relationships')
      .select()
      .inFilter('member_id', memberIds);
  return (data as List).map((e) => Relationship.fromJson(e)).toList();
});

// Returns map: memberId -> list of (relatedMemberId, type)
final adjacencyProvider =
    FutureProvider<Map<String, List<(String, RelationshipType)>>>((ref) async {
  final rels = await ref.watch(relationshipsProvider.future);
  final map = <String, List<(String, RelationshipType)>>{};
  for (final r in rels) {
    map.putIfAbsent(r.memberId, () => []).add((r.relatedMemberId, r.type));
    // Add inverse
    map
        .putIfAbsent(r.relatedMemberId, () => [])
        .add((r.memberId, r.type.inverse));
  }
  return map;
});

// ---------------------------------------------------------------------------
// Member relationships for a given member
// ---------------------------------------------------------------------------

final memberRelationshipsProvider =
    FutureProvider.family<MemberRelationships, String>((ref, memberId) async {
  final adjacency = await ref.watch(adjacencyProvider.future);
  final members = await ref.watch(membersProvider.future);
  final memberMap = {for (final m in members) m.id: m};

  final connected = adjacency[memberId] ?? [];

  List<Member> parents = [];
  List<Member> children = [];
  List<Member> spouses = [];
  List<Member> siblings = [];

  for (final (relId, type) in connected) {
    final member = memberMap[relId];
    if (member == null) continue;
    switch (type) {
      case RelationshipType.parent:
        parents.add(member);
      case RelationshipType.child:
        children.add(member);
      case RelationshipType.spouse:
        spouses.add(member);
      case RelationshipType.sibling:
        siblings.add(member);
    }
  }

  return MemberRelationships(
    parents: parents,
    children: children,
    spouses: spouses,
    siblings: siblings,
  );
});

class MemberRelationships {
  final List<Member> parents;
  final List<Member> children;
  final List<Member> spouses;
  final List<Member> siblings;

  const MemberRelationships({
    required this.parents,
    required this.children,
    required this.spouses,
    required this.siblings,
  });
}

// ---------------------------------------------------------------------------
// Tree Notifier — CRUD
// ---------------------------------------------------------------------------

class TreeNotifier extends AsyncNotifier<void> {
  SupabaseClient get _db => ref.read(supabaseProvider);

  @override
  Future<void> build() async {}

  Future<Member> addMember({
    required String familyId,
    required String fullName,
    String? fullNameAr,
    required String gender,
    DateTime? birthDate,
    DateTime? deathDate,
    String? birthPlace,
    String? phone,
    String? notes,
  }) async {
    state = const AsyncLoading();
    final userId = ref.read(currentUserProvider)?.id;
    final data = await _db.from('members').insert({
      'family_id': familyId,
      'full_name': fullName,
      'full_name_ar': fullNameAr,
      'gender': gender,
      'birth_date': birthDate?.toIso8601String().split('T')[0],
      'death_date': deathDate?.toIso8601String().split('T')[0],
      'birth_place': birthPlace,
      'phone': phone,
      'notes': notes,
      'created_by': userId,
    }).select().single();
    ref.invalidate(membersProvider);
    state = const AsyncData(null);
    return Member.fromJson(data);
  }

  Future<void> updateMember(String memberId, Map<String, dynamic> updates) async {
    await _db.from('members').update(updates).eq('id', memberId);
    ref.invalidate(membersProvider);
  }

  Future<void> deleteMember(String memberId) async {
    await _db.from('members').delete().eq('id', memberId);
    ref.invalidate(membersProvider);
    ref.invalidate(relationshipsProvider);
  }

  Future<void> addRelationship({
    required String memberId,
    required String relatedMemberId,
    required RelationshipType type,
  }) async {
    // Insert forward relationship
    await _db.from('relationships').insert({
      'member_id': memberId,
      'related_member_id': relatedMemberId,
      'relationship_type': type.value,
    });
    // Insert inverse
    await _db.from('relationships').insert({
      'member_id': relatedMemberId,
      'related_member_id': memberId,
      'relationship_type': type.inverse.value,
    });
    ref.invalidate(relationshipsProvider);
  }

  Future<void> removeRelationship({
    required String memberId,
    required String relatedMemberId,
  }) async {
    await _db
        .from('relationships')
        .delete()
        .eq('member_id', memberId)
        .eq('related_member_id', relatedMemberId);
    await _db
        .from('relationships')
        .delete()
        .eq('member_id', relatedMemberId)
        .eq('related_member_id', memberId);
    ref.invalidate(relationshipsProvider);
  }

  Future<void> uploadPhoto(String memberId, String localPath) async {
    final supabase = ref.read(supabaseProvider);
    final fileName = 'members/$memberId.jpg';
    await supabase.storage.from('photos').upload(fileName, null as dynamic);
    final url = supabase.storage.from('photos').getPublicUrl(fileName);
    await updateMember(memberId, {'photo_url': url});
  }
}

final treeNotifierProvider =
    AsyncNotifierProvider<TreeNotifier, void>(TreeNotifier.new);
