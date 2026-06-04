import '../tree/models/relationship.dart';

/// Arabic kinship resolver.
///
/// Turns a BFS relationship path into proper Arabic kinship terms — the
/// "نورة هي عمّتك" headline and the per-link labels (والدك، أخته) shown in the
/// Relationship Finder.
///
/// A [KinHop] describes one edge of the path: how THIS person relates to the
/// PREVIOUS one, plus this person's gender ('male' | 'female').
///
/// NOTE ON DIRECTION: this assumes `edge` reads "next is <edge> of previous"
/// (parent ⇒ next is the previous person's parent). If your adjacency is built
/// the other way, pass `edge.inverse` when constructing hops — one-line flip.
class KinHop {
  final RelationshipType edge;
  final String gender;
  const KinHop({required this.edge, required this.gender});
}

class Kinship {
  Kinship._();

  static bool _m(String g) => g == 'male';

  /// 2nd-person term ("your X") for the first hop relative to YOU.
  static String secondPerson(RelationshipType edge, String g) {
    switch (edge) {
      case RelationshipType.parent:
        return _m(g) ? 'أبوك' : 'أمّك';
      case RelationshipType.child:
        return _m(g) ? 'ابنك' : 'ابنتك';
      case RelationshipType.sibling:
        return _m(g) ? 'أخوك' : 'أختك';
      case RelationshipType.spouse:
        return _m(g) ? 'زوجك' : 'زوجتك';
    }
  }

  /// 3rd-person term ("his/her X") for later hops; [prevMale] = previous
  /// person's gender.
  static String thirdPerson(RelationshipType edge, String g, bool prevMale) {
    final p = prevMale ? 'ه' : 'ها';
    switch (edge) {
      case RelationshipType.parent:
        return (_m(g) ? 'والد' : 'والدت') + p;
      case RelationshipType.child:
        return (_m(g) ? 'ابن' : 'ابنت') + p;
      case RelationshipType.sibling:
        return (_m(g) ? 'أخو' : 'أخت') + p;
      case RelationshipType.spouse:
        return (_m(g) ? 'زوج' : 'زوجت') + p;
    }
  }

  /// Per-link label for the chain UI. [index] 0 = first hop (relative to you).
  static String linkLabel(List<KinHop> hops, int index) {
    final h = hops[index];
    if (index == 0) return secondPerson(h.edge, h.gender);
    final prevMale = _m(hops[index - 1].gender);
    return thirdPerson(h.edge, h.gender, prevMale);
  }

  /// The headline term: target relative to YOU (e.g. عمّتك، جدّك، ابن عمّك).
  /// Precise for common patterns; composes a readable fallback otherwise.
  static String relationLabel(List<KinHop> hops) {
    if (hops.isEmpty) return 'الشخص نفسه';
    final edges = hops.map((h) => h.edge).toList();
    final tg = hops.last.gender; // target gender
    final male = _m(tg);

    // 1 hop
    if (hops.length == 1) return secondPerson(edges[0], tg);

    // 2 hops
    if (hops.length == 2) {
      final e0 = edges[0], e1 = edges[1];
      final p0Male = _m(hops[0].gender);
      // grandparent: parent → parent
      if (e0 == RelationshipType.parent && e1 == RelationshipType.parent) {
        return male ? 'جدّك' : 'جدّتك';
      }
      // grandchild: child → child
      if (e0 == RelationshipType.child && e1 == RelationshipType.child) {
        return male ? 'حفيدك' : 'حفيدتك';
      }
      // uncle/aunt: parent → sibling (paternal if parent male, else maternal)
      if (e0 == RelationshipType.parent && e1 == RelationshipType.sibling) {
        if (p0Male) return male ? 'عمّك' : 'عمّتك';
        return male ? 'خالك' : 'خالتك';
      }
      // nephew/niece: sibling → child
      if (e0 == RelationshipType.sibling && e1 == RelationshipType.child) {
        final sibMale = p0Male;
        return (male ? 'ابن ' : 'بنت ') + (sibMale ? 'أخيك' : 'أختك');
      }
      // sibling via parent (half/■ full): parent → child ⇒ sibling
      if (e0 == RelationshipType.parent && e1 == RelationshipType.child) {
        return male ? 'أخوك' : 'أختك';
      }
    }

    // 3 hops — cousin: parent → sibling → child
    if (hops.length == 3 &&
        edges[0] == RelationshipType.parent &&
        edges[1] == RelationshipType.sibling &&
        edges[2] == RelationshipType.child) {
      final parentMale = _m(hops[0].gender);
      final uncle = parentMale ? 'عمّك' : 'خالك';
      return (male ? 'ابن ' : 'بنت ') + uncle;
    }

    // Fallback: compose 3rd-person chain, e.g. "والد والدك"
    final buf = StringBuffer(secondPerson(edges[0], hops[0].gender));
    for (var i = 1; i < hops.length; i++) {
      final prevMale = _m(hops[i - 1].gender);
      buf.write(' ${thirdPerson(edges[i], hops[i].gender, prevMale)}');
    }
    return buf.toString();
  }

  /// Degree of kinship in Arabic-Indic digits.
  static String degree(int hops) {
    const d = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    return hops
        .toString()
        .split('')
        .map((c) => d[int.parse(c)])
        .join();
  }
}
