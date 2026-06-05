import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';

class ClaimMatch {
  final String id, familyId, familyLabel, firstName, fatherName, grandfatherName, familyName, city, gender;
  final String? clanName;
  final bool claimed;
  const ClaimMatch({
    required this.id, required this.familyId, required this.familyLabel,
    required this.firstName, required this.fatherName, required this.grandfatherName,
    required this.familyName, this.clanName, required this.city, required this.gender,
    required this.claimed,
  });
  String get fullName => '$firstName $fatherName $grandfatherName $familyName';
  factory ClaimMatch.fromJson(Map<String, dynamic> j) => ClaimMatch(
        id: j['id'] as String,
        familyId: j['family_id'] as String,
        familyLabel: j['family_label'] as String? ?? '',
        firstName: j['first_name'] as String? ?? '',
        fatherName: j['father_name'] as String? ?? '',
        grandfatherName: j['grandfather_name'] as String? ?? '',
        familyName: j['family_name'] as String? ?? '',
        clanName: j['clan_name'] as String?,
        city: j['city'] as String? ?? '',
        gender: j['gender'] as String? ?? 'male',
        claimed: j['claimed'] as bool? ?? false,
      );
}

class PendingClaim {
  final String claimId, memberId, memberLabel, claimantEmail;
  const PendingClaim({required this.claimId, required this.memberId, required this.memberLabel, required this.claimantEmail});
  factory PendingClaim.fromJson(Map<String, dynamic> j) => PendingClaim(
        claimId: j['claim_id'] as String,
        memberId: j['member_id'] as String,
        memberLabel: j['member_label'] as String? ?? '',
        claimantEmail: j['claimant_email'] as String? ?? '',
      );
}

class MyClaim {
  final String status, memberLabel, familyLabel;
  const MyClaim({required this.status, required this.memberLabel, required this.familyLabel});
  factory MyClaim.fromJson(Map<String, dynamic> j) => MyClaim(
        status: j['status'] as String? ?? 'pending',
        memberLabel: j['member_label'] as String? ?? '',
        familyLabel: j['family_label'] as String? ?? '',
      );
}

final myClaimProvider = FutureProvider<MyClaim?>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;
  final data = await ref.watch(supabaseProvider).rpc('my_claim_status');
  final list = data as List;
  if (list.isEmpty) return null;
  return MyClaim.fromJson(list.first as Map<String, dynamic>);
});

final pendingClaimsProvider = FutureProvider<List<PendingClaim>>((ref) async {
  final data = await ref.watch(supabaseProvider).rpc('pending_claims');
  return (data as List).map((e) => PendingClaim.fromJson(e as Map<String, dynamic>)).toList();
});

class ClaimNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<List<ClaimMatch>> findMatches(
      String first, String father, String grand, String family, String city) async {
    final data = await ref.read(supabaseProvider).rpc('find_member_for_claim', params: {
      'p_first': first, 'p_father': father, 'p_grand': grand,
      'p_family': family, 'p_city': city,
    });
    return (data as List).map((e) => ClaimMatch.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> requestClaim(String memberId) async {
    await ref.read(supabaseProvider).rpc('request_claim', params: {'p_member_id': memberId});
    ref.invalidate(myClaimProvider);
  }

  Future<void> approve(String claimId) async {
    await ref.read(supabaseProvider).rpc('approve_claim', params: {'p_claim_id': claimId});
    ref.invalidate(pendingClaimsProvider);
  }

  Future<void> reject(String claimId) async {
    await ref.read(supabaseProvider).rpc('reject_claim', params: {'p_claim_id': claimId});
    ref.invalidate(pendingClaimsProvider);
  }
}

final claimNotifierProvider = AsyncNotifierProvider<ClaimNotifier, void>(ClaimNotifier.new);
