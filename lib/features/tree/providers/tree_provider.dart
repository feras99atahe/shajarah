import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
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
  final data = await ref.watch(supabaseProvider)
      .from('families').select().eq('id', familyId).maybeSingle();
  if (data == null) return null;
  return family_model.Family.fromJson(data);
});

// ---------------------------------------------------------------------------
// Members
// ---------------------------------------------------------------------------

final membersProvider = FutureProvider<List<Member>>((ref) async {
  final familyId = await ref.watch(userFamilyIdProvider.future);
  if (familyId == null) return [];
  final data = await ref.watch(supabaseProvider)
      .from('members').select().eq('family_id', familyId).order('created_at');
  return (data as List).map((e) => Member.fromJson(e)).toList();
});

final memberByIdProvider = FutureProvider.family<Member?, String>((ref, id) async {
  final members = await ref.watch(membersProvider.future);
  try {
    return members.firstWhere((m) => m.id == id);
  } catch (_) {
    return null;
  }
});

// ---------------------------------------------------------------------------
// Cross-family directory search (by city + clan + family name)
// ---------------------------------------------------------------------------

class PublicMember {
  final String id, familyId, firstName, fatherName, grandfatherName, familyName, city, gender;
  final String? clanName;
  const PublicMember({
    required this.id,
    required this.familyId,
    required this.firstName,
    required this.fatherName,
    required this.grandfatherName,
    required this.familyName,
    required this.city,
    required this.gender,
    this.clanName,
  });

  String get fullName => '$firstName $fatherName $grandfatherName $familyName';
  bool get isMale => gender == 'male';

  factory PublicMember.fromJson(Map<String, dynamic> j) => PublicMember(
        id: j['id'] as String,
        familyId: j['family_id'] as String,
        firstName: j['first_name'] as String? ?? '',
        fatherName: j['father_name'] as String? ?? '',
        grandfatherName: j['grandfather_name'] as String? ?? '',
        familyName: j['family_name'] as String? ?? '',
        clanName: j['clan_name'] as String?,
        city: j['city'] as String? ?? '',
        gender: j['gender'] as String? ?? 'male',
      );
}

/// Searches members across ALL families by city + clan + family name.
final globalSearchProvider =
    FutureProvider.family<List<PublicMember>, (String, String, String)>((ref, q) async {
  final (city, clan, family) = q;
  if (city.trim().isEmpty && clan.trim().isEmpty && family.trim().isEmpty) return [];
  final data = await ref.read(supabaseProvider).rpc('search_members_global', params: {
    'p_city': city.trim().isEmpty ? null : city.trim(),
    'p_clan': clan.trim().isEmpty ? null : clan.trim(),
    'p_family_name': family.trim().isEmpty ? null : family.trim(),
  });
  return (data as List).map((e) => PublicMember.fromJson(e as Map<String, dynamic>)).toList();
});

// ---------------------------------------------------------------------------
// Privacy — viewer's linked tree member
// ---------------------------------------------------------------------------

final linkedMemberIdProvider = FutureProvider<String?>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;
  final data = await ref.watch(supabaseProvider)
      .from('user_profiles')
      .select('linked_member_id')
      .eq('id', user.id)
      .maybeSingle();
  return data?['linked_member_id'] as String?;
});

/// Returns true if the viewer's linked member has any graph path to [targetId].
final isConnectedToProvider =
    FutureProvider.family<bool, String>((ref, targetId) async {
  final linkedId = await ref.watch(linkedMemberIdProvider.future);
  if (linkedId == null) return false;
  if (linkedId == targetId) return true;
  final adjacency = await ref.watch(adjacencyProvider.future);
  final visited = <String>{linkedId};
  final queue = [linkedId];
  while (queue.isNotEmpty) {
    final cur = queue.removeAt(0);
    for (final (nId, _) in adjacency[cur] ?? const <(String, RelationshipType)>[]) {
      if (nId == targetId) return true;
      if (visited.add(nId)) queue.add(nId);
    }
  }
  return false;
});

// ---------------------------------------------------------------------------
// Relationships
// ---------------------------------------------------------------------------

final relationshipsProvider = FutureProvider<List<Relationship>>((ref) async {
  final familyId = await ref.watch(userFamilyIdProvider.future);
  if (familyId == null) return [];
  final memberData = await ref.watch(supabaseProvider)
      .from('members').select('id').eq('family_id', familyId);
  final ids = (memberData as List).map((e) => e['id'] as String).toList();
  if (ids.isEmpty) return [];
  final data = await ref.watch(supabaseProvider)
      .from('relationships').select().inFilter('member_id', ids);
  return (data as List).map((e) => Relationship.fromJson(e)).toList();
});

final adjacencyProvider =
    FutureProvider<Map<String, List<(String, RelationshipType)>>>((ref) async {
  final rels = await ref.watch(relationshipsProvider.future);
  final map = <String, List<(String, RelationshipType)>>{};
  for (final r in rels) {
    map.putIfAbsent(r.memberId, () => []).add((r.relatedMemberId, r.type));
    map.putIfAbsent(r.relatedMemberId, () => []).add((r.memberId, r.type.inverse));
  }
  return map;
});

final memberRelationshipsProvider =
    FutureProvider.family<MemberRelationships, String>((ref, memberId) async {
  final adjacency = await ref.watch(adjacencyProvider.future);
  final members = await ref.watch(membersProvider.future);
  final memberMap = {for (final m in members) m.id: m};
  final connected = adjacency[memberId] ?? [];

  final parents = <Member>[];
  final children = <Member>[];
  final spouses = <Member>[];
  final siblings = <Member>[];

  final seen = <String>{};
  for (final (relId, type) in connected) {
    if (!seen.add(relId)) continue;
    final m = memberMap[relId];
    if (m == null) continue;
    switch (type) {
      case RelationshipType.parent:   parents.add(m);
      case RelationshipType.child:    children.add(m);
      case RelationshipType.spouse:   spouses.add(m);
      case RelationshipType.sibling:  siblings.add(m);
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
// TreeNotifier — CRUD
// ---------------------------------------------------------------------------

class TreeNotifier extends AsyncNotifier<void> {
  SupabaseClient get _db => ref.read(supabaseProvider);

  @override
  Future<void> build() async {}

  Future<Member> addMember({
    required String familyId,
    required String firstName,
    required String fatherName,
    required String grandfatherName,
    required String familyName,
    String? clanName,
    String? motherFirstName,
    String? motherFatherName,
    String? motherGrandfatherName,
    String? motherFamilyName,
    required String city,
    required String gender,
    DateTime? birthDate,
    DateTime? deathDate,
    String? placeOfBirth,
    bool showBirthDate = false,
    String? photoUrl,
    String? notes,
  }) async {
    final userId = ref.read(currentUserProvider)?.id;
    final data = await _db.from('members').insert({
      'family_id': familyId,
      'first_name': firstName,
      'father_name': fatherName,
      'grandfather_name': grandfatherName,
      'family_name': familyName,
      if (clanName != null && clanName.isNotEmpty) 'clan_name': clanName,
      if (photoUrl != null && photoUrl.isNotEmpty) 'photo_url': photoUrl,
      if (motherFirstName != null) 'mother_first_name': motherFirstName,
      if (motherFatherName != null) 'mother_father_name': motherFatherName,
      if (motherGrandfatherName != null)
        'mother_grandfather_name': motherGrandfatherName,
      if (motherFamilyName != null) 'mother_family_name': motherFamilyName,
      'city': city,
      'gender': gender,
      'birth_date': birthDate?.toIso8601String().split('T')[0],
      'death_date': deathDate?.toIso8601String().split('T')[0],
      'place_of_birth': placeOfBirth,
      'show_birth_date': showBirthDate,
      'notes': notes,
      'created_by': userId,
    }).select().single();
    ref.invalidate(membersProvider);
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

  Future<List<Member>> bulkAddMembers(List<Map<String, dynamic>> rows) async {
    final userId = ref.read(currentUserProvider)?.id;
    final payload = rows.map((r) => {...r, 'created_by': userId}).toList();
    final data = await _db.from('members').insert(payload).select();
    ref.invalidate(membersProvider);
    return (data as List).map((e) => Member.fromJson(e)).toList();
  }

  Future<void> addRelationship({
    required String memberId,
    required String relatedMemberId,
    required RelationshipType type,
  }) async {
    await _db.from('relationships').insert({
      'member_id': memberId,
      'related_member_id': relatedMemberId,
      'relationship_type': type.value,
    });
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
    await _db.from('relationships').delete()
        .eq('member_id', memberId).eq('related_member_id', relatedMemberId);
    await _db.from('relationships').delete()
        .eq('member_id', relatedMemberId).eq('related_member_id', memberId);
    ref.invalidate(relationshipsProvider);
  }

  /// Scans all members and auto-creates relationships from name data.
  /// Returns the number of new relationship rows created.
  Future<int> autoDetectRelationships() async {
    final familyId = await ref.read(userFamilyIdProvider.future);
    if (familyId == null) return 0;
    final result = await _db.rpc(
      'auto_detect_relationships',
      params: {'p_family_id': familyId},
    );
    ref.invalidate(relationshipsProvider);
    ref.invalidate(adjacencyProvider);
    return (result as int?) ?? 0;
  }

  /// Links the current user's profile to a tree member.
  Future<void> linkUserToMember(String memberId) async {
    final userId = ref.read(currentUserProvider)?.id;
    if (userId == null) return;
    await _db.from('user_profiles')
        .update({'linked_member_id': memberId}).eq('id', userId);
    ref.invalidate(linkedMemberIdProvider);
  }

  /// Pick an image from the gallery and upload it to the `avatars` bucket.
  /// Returns the public URL, or null if cancelled.
  Future<String?> pickAndUploadPhoto() async {
    final file = await ImagePicker().pickImage(
        source: ImageSource.gallery, maxWidth: 800, imageQuality: 80);
    if (file == null) return null;
    final bytes = await file.readAsBytes();
    final path = 'members/${const Uuid().v4()}.jpg';
    await _db.storage.from('avatars').uploadBinary(
          path,
          bytes,
          fileOptions: const FileOptions(upsert: true, contentType: 'image/jpeg'),
        );
    return _db.storage.from('avatars').getPublicUrl(path);
  }
}

final treeNotifierProvider =
    AsyncNotifierProvider<TreeNotifier, void>(TreeNotifier.new);
