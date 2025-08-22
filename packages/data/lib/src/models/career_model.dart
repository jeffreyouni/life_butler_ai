import 'package:core/core.dart';
import 'package:meta/meta.dart';

@immutable
class CareerModel extends BaseModel {
  const CareerModel({
    required super.id,
    required super.userId,
    required super.createdAt,
    required super.updatedAt,
    super.deletedAt,
    required this.company,
    required this.role,
    required this.startDate,
    this.endDate,
    this.achievements = const [],
    this.notes,
  });

  final String company;
  final String role;
  final DateTime startDate;
  final DateTime? endDate;
  final List<String> achievements;
  final String? notes;

  @override
  String get objectType => 'career';

  @override
  String get searchableContent {
    final buffer = StringBuffer();
    
    // Career information with semantic labels
    buffer.writeln('Career Experience:');
    buffer.writeln('Company: $company');
    buffer.writeln('Position: $role');
    buffer.writeln('Start Date: ${startDate.toIso8601String().split('T')[0]}');
    if (endDate != null) {
      buffer.writeln('End Date: ${endDate!.toIso8601String().split('T')[0]}');
    }
    
    if (achievements.isNotEmpty) {
      buffer.writeln('Achievements:');
      for (final achievement in achievements) {
        buffer.writeln('- $achievement');
      }
    }
    
    if (notes != null && notes!.isNotEmpty) {
      buffer.writeln('Additional Notes:');
      buffer.writeln(notes);
    }
    
    return buffer.toString().trim();
  }

  @override
  String get displayTitle => '$role at $company';

  @override
  List<String> get tags {
    final careerTags = <String>['career', 'work'];
    careerTags.add(company);
    careerTags.add(role);
    careerTags.addAll(achievements);
    return careerTags;
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'company': company,
      'role': role,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'achievements_json': achievements,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'deleted_at': deletedAt?.toIso8601String(),
    };
  }

  factory CareerModel.fromMap(Map<String, dynamic> map) {
    return CareerModel(
      id: map['id'],
      userId: map['user_id'],
      company: map['company'],
      role: map['role'],
      startDate: DateTime.parse(map['start_date']),
      endDate: map['end_date'] != null ? DateTime.parse(map['end_date']) : null,
      achievements: List<String>.from(map['achievements_json'] ?? []),
      notes: map['notes'],
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
      deletedAt: map['deleted_at'] != null ? DateTime.parse(map['deleted_at']) : null,
    );
  }

  CareerModel copyWith({
    String? company,
    String? role,
    DateTime? startDate,
    DateTime? endDate,
    List<String>? achievements,
    String? notes,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return CareerModel(
      id: id,
      userId: userId,
      company: company ?? this.company,
      role: role ?? this.role,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      achievements: achievements ?? this.achievements,
      notes: notes ?? this.notes,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }
}
