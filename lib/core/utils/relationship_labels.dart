import '../../features/tree/models/member.dart';
import '../../features/tree/models/relationship.dart';

/// Computes the kinship label from [fromId]'s perspective looking at [toId].
///
/// Checks 1-hop direct relationships, then 2-hop extended family.
/// Anything beyond 2 hops (or unrecognised paths) returns "Relative".
String kinshipLabel(
  String fromId,
  String toId,
  Map<String, List<(String, RelationshipType)>> adjacency,
  Map<String, Member> memberMap, {
  bool arabic = false,
}) {
  if (fromId == toId) return arabic ? 'أنت' : 'You';
  final target = memberMap[toId];
  if (target == null) return arabic ? 'صلة قرابة' : 'Relative';

  // ── 1-hop ─────────────────────────────────────────────────────────────────
  for (final (nId, type) in adjacency[fromId] ??
      const <(String, RelationshipType)>[]) {
    if (nId != toId) continue;
    return _direct(type, target.isMale, arabic);
  }

  // ── 2-hop ─────────────────────────────────────────────────────────────────
  for (final (midId, type1) in adjacency[fromId] ??
      const <(String, RelationshipType)>[]) {
    if (midId == toId) continue;
    final mid = memberMap[midId];
    for (final (nId, type2) in adjacency[midId] ??
        const <(String, RelationshipType)>[]) {
      if (nId != toId || nId == fromId) continue;
      final label = _twoHop(type1, type2, mid?.isMale ?? true, target.isMale, arabic);
      if (label != null) return label;
    }
  }

  return arabic ? 'صلة قرابة' : 'Relative';
}

String _direct(RelationshipType type, bool targetMale, bool ar) {
  switch (type) {
    case RelationshipType.parent:
      return targetMale ? (ar ? 'الأب' : 'Father') : (ar ? 'الأم' : 'Mother');
    case RelationshipType.child:
      return targetMale ? (ar ? 'الابن' : 'Son') : (ar ? 'البنت' : 'Daughter');
    case RelationshipType.sibling:
      return targetMale ? (ar ? 'الأخ' : 'Brother') : (ar ? 'الأخت' : 'Sister');
    case RelationshipType.spouse:
      return targetMale ? (ar ? 'الزوج' : 'Husband') : (ar ? 'الزوجة' : 'Wife');
  }
}

String? _twoHop(
  RelationshipType type1,
  RelationshipType type2,
  bool midMale,
  bool targetMale,
  bool ar,
) {
  // viewer → parent(mid) → parent(target) = grandparent
  if (type1 == RelationshipType.parent && type2 == RelationshipType.parent) {
    if (targetMale) {
      return midMale ? (ar ? 'جد الأب' : 'Paternal Grandfather')
                     : (ar ? 'جد الأم' : 'Maternal Grandfather');
    } else {
      return midMale ? (ar ? 'جدة الأب' : 'Paternal Grandmother')
                     : (ar ? 'جدة الأم' : 'Maternal Grandmother');
    }
  }

  // viewer → parent(mid) → sibling(target) = uncle / aunt
  if (type1 == RelationshipType.parent && type2 == RelationshipType.sibling) {
    if (midMale) {
      return targetMale ? (ar ? 'العم' : 'Paternal Uncle')
                        : (ar ? 'العمة' : 'Paternal Aunt');
    } else {
      return targetMale ? (ar ? 'الخال' : 'Maternal Uncle')
                        : (ar ? 'الخالة' : 'Maternal Aunt');
    }
  }

  // viewer → child(mid) → child(target) = grandchild
  if (type1 == RelationshipType.child && type2 == RelationshipType.child) {
    return targetMale ? (ar ? 'الحفيد' : 'Grandson')
                      : (ar ? 'الحفيدة' : 'Granddaughter');
  }

  // viewer → sibling(mid) → child(target) = nephew / niece
  if (type1 == RelationshipType.sibling && type2 == RelationshipType.child) {
    return targetMale ? (ar ? 'ابن الأخ/الأخت' : 'Nephew')
                      : (ar ? 'بنت الأخ/الأخت' : 'Niece');
  }

  // viewer → child(mid) → parent(target) = co-parent (other parent of my child)
  // — not a standard label, return null to fall through to "Relative"

  return null;
}

/// Bilingual label for a [RelationshipType] category header.
String relationshipGroupLabel(RelationshipType type, bool arabic) {
  switch (type) {
    case RelationshipType.parent:
      return arabic ? 'الوالدان' : 'Parents';
    case RelationshipType.child:
      return arabic ? 'الأبناء' : 'Children';
    case RelationshipType.sibling:
      return arabic ? 'الأشقاء' : 'Siblings';
    case RelationshipType.spouse:
      return arabic ? 'الزوج / الزوجة' : 'Spouse';
  }
}
