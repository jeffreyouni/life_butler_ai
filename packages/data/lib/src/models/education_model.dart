import 'package:core/core.dart';
import 'package:meta/meta.dart';

@immutable
class EducationModel extends BaseModel {
  const EducationModel({
    required super.id,
    required super.userId,
    required super.createdAt,
    required super.updatedAt,
    super.deletedAt,
    required this.schoolName,
    this.degree,
    this.major,
    required this.startDate,
    this.endDate,
    this.notes,
  });

  final String schoolName;
  final String? degree;
  final String? major;
  final DateTime startDate;
  final DateTime? endDate;
  final String? notes;

  @override
  String get objectType => 'education';

  @override
  String get searchableContent {
    final buffer = StringBuffer();
    
    // Education information with semantic labels
    buffer.writeln('Education Experience:');
    buffer.writeln('School: $schoolName');
    if (degree != null) {
      buffer.writeln('Degree: $degree');
    }
    if (major != null) {
      buffer.writeln('Major/Field: $major');
    }
    buffer.writeln('Start Date: ${startDate.toIso8601String().split('T')[0]}');
    if (endDate != null) {
      buffer.writeln('End Date: ${endDate!.toIso8601String().split('T')[0]}');
    }
    
    if (notes != null && notes!.isNotEmpty) {
      buffer.writeln('Additional Notes:');
      buffer.writeln(notes);
    }
    
    return buffer.toString().trim();
  }

  @override
  String get displayTitle => '$schoolName${degree != null ? ' - $degree' : ''}';

  @override
  List<String> get tags {
    final educationTags = <String>['education'];
    if (degree != null) {
      educationTags.add(degree!);
    }
    if (major != null) {
      educationTags.add(major!);
    }
    return educationTags;
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'school_name': schoolName,
      'degree': degree,
      'major': major,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'deleted_at': deletedAt?.toIso8601String(),
    };
  }

  factory EducationModel.fromMap(Map<String, dynamic> map) {
    return EducationModel(
      id: map['id'],
      userId: map['user_id'],
      schoolName: map['school_name'],
      degree: map['degree'],
      major: map['major'],
      startDate: DateTime.parse(map['start_date']),
      endDate: map['end_date'] != null ? DateTime.parse(map['end_date']) : null,
      notes: map['notes'],
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
      deletedAt: map['deleted_at'] != null ? DateTime.parse(map['deleted_at']) : null,
    );
  }

  EducationModel copyWith({
    String? schoolName,
    String? degree,
    String? major,
    DateTime? startDate,
    DateTime? endDate,
    String? notes,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return EducationModel(
      id: id,
      userId: userId,
      schoolName: schoolName ?? this.schoolName,
      degree: degree ?? this.degree,
      major: major ?? this.major,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      notes: notes ?? this.notes,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }
}
