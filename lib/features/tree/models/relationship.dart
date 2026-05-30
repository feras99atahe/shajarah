import 'package:equatable/equatable.dart';

enum RelationshipType { parent, child, spouse, sibling }

extension RelationshipTypeExt on RelationshipType {
  String get value {
    switch (this) {
      case RelationshipType.parent:
        return 'parent';
      case RelationshipType.child:
        return 'child';
      case RelationshipType.spouse:
        return 'spouse';
      case RelationshipType.sibling:
        return 'sibling';
    }
  }

  static RelationshipType fromString(String value) {
    switch (value) {
      case 'parent':
        return RelationshipType.parent;
      case 'child':
        return RelationshipType.child;
      case 'spouse':
        return RelationshipType.spouse;
      case 'sibling':
        return RelationshipType.sibling;
      default:
        return RelationshipType.parent;
    }
  }

  RelationshipType get inverse {
    switch (this) {
      case RelationshipType.parent:
        return RelationshipType.child;
      case RelationshipType.child:
        return RelationshipType.parent;
      case RelationshipType.spouse:
        return RelationshipType.spouse;
      case RelationshipType.sibling:
        return RelationshipType.sibling;
    }
  }
}

class Relationship extends Equatable {
  final String id;
  final String memberId;
  final String relatedMemberId;
  final RelationshipType type;
  final DateTime createdAt;

  const Relationship({
    required this.id,
    required this.memberId,
    required this.relatedMemberId,
    required this.type,
    required this.createdAt,
  });

  factory Relationship.fromJson(Map<String, dynamic> json) => Relationship(
        id: json['id'] as String,
        memberId: json['member_id'] as String,
        relatedMemberId: json['related_member_id'] as String,
        type: RelationshipTypeExt.fromString(
            json['relationship_type'] as String),
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'member_id': memberId,
        'related_member_id': relatedMemberId,
        'relationship_type': type.value,
        'created_at': createdAt.toIso8601String(),
      };

  @override
  List<Object?> get props => [id, memberId, relatedMemberId, type];
}
