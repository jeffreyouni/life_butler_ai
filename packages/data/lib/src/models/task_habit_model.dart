import 'package:core/core.dart';
import 'package:meta/meta.dart';

@immutable
class TaskHabitModel extends BaseModel {
  const TaskHabitModel({
    required super.id,
    required super.userId,
    required super.createdAt,
    required super.updatedAt,
    super.deletedAt,
    required this.title,
    required this.type,
    this.schedule = const {},
    this.status = 'pending',
    this.notes,
  });

  final String title;
  final String type; // 'task' or 'habit'
  final Map<String, dynamic> schedule;
  final String status;
  final String? notes;

  @override
  String get objectType => 'tasks_habits';

  @override
  String get searchableContent {
    final buffer = StringBuffer();
    
    // Task/Habit with semantic labels
    buffer.writeln('${type == 'task' ? 'Task' : 'Habit'}:');
    buffer.writeln('Title: $title');
    buffer.writeln('Status: $status');
    
    if (schedule.isNotEmpty) {
      buffer.writeln('Schedule: ${schedule.toString()}');
    }
    
    if (notes != null && notes!.isNotEmpty) {
      buffer.writeln('Notes: $notes');
    }
    
    return buffer.toString().trim();
  }

  @override
  String get displayTitle => '$title ($type)';

  @override
  List<String> get tags {
    final taskTags = <String>[type, status];
    if (type == 'task') {
      taskTags.add('task');
    } else {
      taskTags.add('habit');
    }
    return taskTags;
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'type': type,
      'schedule_json': schedule,
      'status': status,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'deleted_at': deletedAt?.toIso8601String(),
    };
  }

  factory TaskHabitModel.fromMap(Map<String, dynamic> map) {
    return TaskHabitModel(
      id: map['id'],
      userId: map['user_id'],
      title: map['title'],
      type: map['type'],
      schedule: Map<String, dynamic>.from(map['schedule_json'] ?? {}),
      status: map['status'] ?? 'pending',
      notes: map['notes'],
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
      deletedAt: map['deleted_at'] != null ? DateTime.parse(map['deleted_at']) : null,
    );
  }

  TaskHabitModel copyWith({
    String? title,
    String? type,
    Map<String, dynamic>? schedule,
    String? status,
    String? notes,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return TaskHabitModel(
      id: id,
      userId: userId,
      title: title ?? this.title,
      type: type ?? this.type,
      schedule: schedule ?? this.schedule,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }
}
