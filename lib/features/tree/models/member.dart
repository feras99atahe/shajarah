import 'package:equatable/equatable.dart';

class Member extends Equatable {
  final String id;
  final String familyId;

  // Paternal four-part name — always publicly visible
  final String firstName;
  final String fatherName;
  final String grandfatherName;
  final String familyName;

  // Maternal four-part name — hidden until verified tree connection
  final String? motherFirstName;
  final String? motherFatherName;
  final String? motherGrandfatherName;
  final String? motherFamilyName;

  // Geographic scope
  final String city;

  // Passport fields
  final String gender;
  final DateTime? birthDate;
  final DateTime? deathDate;
  final String? placeOfBirth;

  // Privacy
  final bool showBirthDate;

  final String? photoUrl;
  final String? notes;
  final DateTime createdAt;

  const Member({
    required this.id,
    required this.familyId,
    required this.firstName,
    required this.fatherName,
    required this.grandfatherName,
    required this.familyName,
    this.motherFirstName,
    this.motherFatherName,
    this.motherGrandfatherName,
    this.motherFamilyName,
    required this.city,
    required this.gender,
    this.birthDate,
    this.deathDate,
    this.placeOfBirth,
    this.showBirthDate = false,
    this.photoUrl,
    this.notes,
    required this.createdAt,
  });

  // ── Computed ───────────────────────────────────────────────────────────────

  /// Full paternal four-part name.
  String get fullName =>
      '$firstName $fatherName $grandfatherName $familyName';

  /// Short display name used in tree nodes (first + family).
  String get shortName => '$firstName $familyName';

  /// Mother's full four-part name (may be empty if not entered).
  String get motherFullName => [
        motherFirstName,
        motherFatherName,
        motherGrandfatherName,
        motherFamilyName,
      ].where((p) => p != null && p.isNotEmpty).join(' ');

  bool get hasMotherName =>
      motherFirstName != null && motherFirstName!.isNotEmpty;

  bool get isMale => gender == 'male';
  bool get isDeceased => deathDate != null;

  int? get age {
    if (birthDate == null) return null;
    final end = deathDate ?? DateTime.now();
    int a = end.year - birthDate!.year;
    if (end.month < birthDate!.month ||
        (end.month == birthDate!.month && end.day < birthDate!.day)) a--;
    return a;
  }

  // ── Serialization ──────────────────────────────────────────────────────────

  factory Member.fromJson(Map<String, dynamic> j) => Member(
        id: j['id'] as String,
        familyId: j['family_id'] as String,
        firstName: j['first_name'] as String? ?? '',
        fatherName: j['father_name'] as String? ?? '',
        grandfatherName: j['grandfather_name'] as String? ?? '',
        familyName: j['family_name'] as String? ?? '',
        motherFirstName: j['mother_first_name'] as String?,
        motherFatherName: j['mother_father_name'] as String?,
        motherGrandfatherName: j['mother_grandfather_name'] as String?,
        motherFamilyName: j['mother_family_name'] as String?,
        city: j['city'] as String? ?? '',
        gender: j['gender'] as String? ?? 'male',
        birthDate: j['birth_date'] != null
            ? DateTime.parse(j['birth_date'] as String)
            : null,
        deathDate: j['death_date'] != null
            ? DateTime.parse(j['death_date'] as String)
            : null,
        placeOfBirth: j['place_of_birth'] as String?,
        showBirthDate: j['show_birth_date'] as bool? ?? false,
        photoUrl: j['photo_url'] as String?,
        notes: j['notes'] as String?,
        createdAt: DateTime.parse(j['created_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'family_id': familyId,
        'first_name': firstName,
        'father_name': fatherName,
        'grandfather_name': grandfatherName,
        'family_name': familyName,
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
        'photo_url': photoUrl,
        'notes': notes,
        'created_at': createdAt.toIso8601String(),
      };

  Member copyWith({
    String? firstName,
    String? fatherName,
    String? grandfatherName,
    String? familyName,
    String? motherFirstName,
    String? motherFatherName,
    String? motherGrandfatherName,
    String? motherFamilyName,
    String? city,
    String? gender,
    DateTime? birthDate,
    DateTime? deathDate,
    String? placeOfBirth,
    bool? showBirthDate,
    String? photoUrl,
    String? notes,
  }) =>
      Member(
        id: id,
        familyId: familyId,
        firstName: firstName ?? this.firstName,
        fatherName: fatherName ?? this.fatherName,
        grandfatherName: grandfatherName ?? this.grandfatherName,
        familyName: familyName ?? this.familyName,
        motherFirstName: motherFirstName ?? this.motherFirstName,
        motherFatherName: motherFatherName ?? this.motherFatherName,
        motherGrandfatherName:
            motherGrandfatherName ?? this.motherGrandfatherName,
        motherFamilyName: motherFamilyName ?? this.motherFamilyName,
        city: city ?? this.city,
        gender: gender ?? this.gender,
        birthDate: birthDate ?? this.birthDate,
        deathDate: deathDate ?? this.deathDate,
        placeOfBirth: placeOfBirth ?? this.placeOfBirth,
        showBirthDate: showBirthDate ?? this.showBirthDate,
        photoUrl: photoUrl ?? this.photoUrl,
        notes: notes ?? this.notes,
        createdAt: createdAt,
      );

  @override
  List<Object?> get props => [id, familyId, firstName, fatherName, gender, createdAt];
}
