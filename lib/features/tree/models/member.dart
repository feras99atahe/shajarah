import 'package:equatable/equatable.dart';

class Member extends Equatable {
  final String id;
  final String familyId;
  final String fullName;
  final String? fullNameAr;
  final String gender; // 'male' | 'female'
  final DateTime? birthDate;
  final DateTime? deathDate;
  final String? birthPlace;
  final String? phone;
  final String? photoUrl;
  final String? notes;
  final DateTime createdAt;

  const Member({
    required this.id,
    required this.familyId,
    required this.fullName,
    this.fullNameAr,
    required this.gender,
    this.birthDate,
    this.deathDate,
    this.birthPlace,
    this.phone,
    this.photoUrl,
    this.notes,
    required this.createdAt,
  });

  bool get isMale => gender == 'male';
  bool get isDeceased => deathDate != null;

  int? get age {
    if (birthDate == null) return null;
    final end = deathDate ?? DateTime.now();
    int age = end.year - birthDate!.year;
    if (end.month < birthDate!.month ||
        (end.month == birthDate!.month && end.day < birthDate!.day)) {
      age--;
    }
    return age;
  }

  String displayName(bool isArabic) {
    if (isArabic && fullNameAr != null && fullNameAr!.isNotEmpty) {
      return fullNameAr!;
    }
    return fullName;
  }

  factory Member.fromJson(Map<String, dynamic> json) => Member(
        id: json['id'] as String,
        familyId: json['family_id'] as String,
        fullName: json['full_name'] as String,
        fullNameAr: json['full_name_ar'] as String?,
        gender: json['gender'] as String? ?? 'male',
        birthDate: json['birth_date'] != null
            ? DateTime.parse(json['birth_date'] as String)
            : null,
        deathDate: json['death_date'] != null
            ? DateTime.parse(json['death_date'] as String)
            : null,
        birthPlace: json['birth_place'] as String?,
        phone: json['phone'] as String?,
        photoUrl: json['photo_url'] as String?,
        notes: json['notes'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'family_id': familyId,
        'full_name': fullName,
        'full_name_ar': fullNameAr,
        'gender': gender,
        'birth_date': birthDate?.toIso8601String().split('T')[0],
        'death_date': deathDate?.toIso8601String().split('T')[0],
        'birth_place': birthPlace,
        'phone': phone,
        'photo_url': photoUrl,
        'notes': notes,
        'created_at': createdAt.toIso8601String(),
      };

  Member copyWith({
    String? id,
    String? familyId,
    String? fullName,
    String? fullNameAr,
    String? gender,
    DateTime? birthDate,
    DateTime? deathDate,
    String? birthPlace,
    String? phone,
    String? photoUrl,
    String? notes,
    DateTime? createdAt,
  }) =>
      Member(
        id: id ?? this.id,
        familyId: familyId ?? this.familyId,
        fullName: fullName ?? this.fullName,
        fullNameAr: fullNameAr ?? this.fullNameAr,
        gender: gender ?? this.gender,
        birthDate: birthDate ?? this.birthDate,
        deathDate: deathDate ?? this.deathDate,
        birthPlace: birthPlace ?? this.birthPlace,
        phone: phone ?? this.phone,
        photoUrl: photoUrl ?? this.photoUrl,
        notes: notes ?? this.notes,
        createdAt: createdAt ?? this.createdAt,
      );

  @override
  List<Object?> get props => [id, familyId, fullName, gender, createdAt];
}
