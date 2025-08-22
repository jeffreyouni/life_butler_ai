import 'package:core/core.dart';
import 'package:meta/meta.dart';

@immutable
class RelationModel extends BaseModel {
  const RelationModel({
    required super.id,
    required super.userId,
    required super.createdAt,
    required super.updatedAt,
    super.deletedAt,
    required this.personName,
    this.relationType,
    this.notes,
    this.importantDates = const {},
  });

  final String personName;
  final String? relationType;
  final String? notes;
  final Map<String, dynamic> importantDates;

  @override
  String get objectType => 'relations';

  @override
  String get searchableContent {
    final buffer = StringBuffer();
    
    // Relationship with semantic labels
    buffer.writeln('Relationship:');
    buffer.writeln('Person: $personName');
    
    if (relationType != null && relationType!.isNotEmpty) {
      buffer.writeln('Relationship Type: $relationType');
    }
    
    if (importantDates.isNotEmpty) {
      buffer.writeln('Important Dates:');
      for (final entry in importantDates.entries) {
        buffer.writeln('- ${entry.key}: ${entry.value}');
      }
    }
    
    if (notes != null && notes!.isNotEmpty) {
      buffer.writeln('Notes: $notes');
    }
    
    return buffer.toString().trim();
  }

  @override
  String get displayTitle => '$personName${relationType != null ? ' ($relationType)' : ''}';

  @override
  List<String> get tags {
    final relationTags = <String>['relationship', 'people'];
    if (relationType != null) {
      relationTags.add(relationType!);
    }
    return relationTags;
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'person_name': personName,
      'relation_type': relationType,
      'notes': notes,
      'important_dates_json': importantDates,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'deleted_at': deletedAt?.toIso8601String(),
    };
  }

  factory RelationModel.fromMap(Map<String, dynamic> map) {
    return RelationModel(
      id: map['id'],
      userId: map['user_id'],
      personName: map['person_name'],
      relationType: map['relation_type'],
      notes: map['notes'],
      importantDates: Map<String, dynamic>.from(map['important_dates_json'] ?? {}),
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
      deletedAt: map['deleted_at'] != null ? DateTime.parse(map['deleted_at']) : null,
    );
  }

  RelationModel copyWith({
    String? personName,
    String? relationType,
    String? notes,
    Map<String, dynamic>? importantDates,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return RelationModel(
      id: id,
      userId: userId,
      personName: personName ?? this.personName,
      relationType: relationType ?? this.relationType,
      notes: notes ?? this.notes,
      importantDates: importantDates ?? this.importantDates,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }
}
