import 'package:equatable/equatable.dart';

class Family extends Equatable {
  final String id;
  final String name;
  final String? nameAr;
  final String? description;
  final String? createdBy;
  final DateTime createdAt;

  const Family({
    required this.id,
    required this.name,
    this.nameAr,
    this.description,
    this.createdBy,
    required this.createdAt,
  });

  String displayName(bool isArabic) {
    if (isArabic && nameAr != null && nameAr!.isNotEmpty) return nameAr!;
    return name;
  }

  factory Family.fromJson(Map<String, dynamic> json) => Family(
        id: json['id'] as String,
        name: json['name'] as String,
        nameAr: json['name_ar'] as String?,
        description: json['description'] as String?,
        createdBy: json['created_by'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'name_ar': nameAr,
        'description': description,
        'created_by': createdBy,
        'created_at': createdAt.toIso8601String(),
      };

  @override
  List<Object?> get props => [id, name, createdAt];
}
