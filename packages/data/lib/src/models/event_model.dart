import 'package:core/core.dart';
import 'package:meta/meta.dart';

@immutable
class EventModel extends BaseModel {
  const EventModel({
    required super.id,
    required super.userId,
    required super.createdAt,
    required super.updatedAt,
    super.deletedAt,
    required this.title,
    this.description,
    this.tags = const [],
    required this.date,
    this.location,
    this.attachments = const [],
  });

  final String title;
  final String? description;
  final List<String> tags;
  final DateTime date;
  final String? location;
  final List<String> attachments;

  @override
  String get objectType => 'events';

  @override
  String get searchableContent {
    final buffer = StringBuffer();
    
    // Event information with semantic labels
    buffer.writeln('Event:');
    buffer.writeln('Title: $title');
    buffer.writeln('Date: ${date.toIso8601String().split('T')[0]}');
    
    if (description != null && description!.isNotEmpty) {
      buffer.writeln('Description: $description');
    }
    
    if (location != null && location!.isNotEmpty) {
      buffer.writeln('Location: $location');
    }
    
    if (tags.isNotEmpty) {
      buffer.writeln('Tags: ${tags.join(', ')}');
    }
    
    if (attachments.isNotEmpty) {
      buffer.writeln('Attachments: ${attachments.length} files');
    }
    
    return buffer.toString().trim();
  }

  @override
  String get displayTitle => title;

  @override
  List<String> get allTags => this.tags;

  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'description': description,
      'tags_json': tags,
      'date': date.toIso8601String(),
      'location': location,
      'attachments_json': attachments,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'deleted_at': deletedAt?.toIso8601String(),
    };
  }

  factory EventModel.fromMap(Map<String, dynamic> map) {
    return EventModel(
      id: map['id'],
      userId: map['user_id'],
      title: map['title'],
      description: map['description'],
      tags: List<String>.from(map['tags_json'] ?? []),
      date: DateTime.parse(map['date']),
      location: map['location'],
      attachments: List<String>.from(map['attachments_json'] ?? []),
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
      deletedAt: map['deleted_at'] != null ? DateTime.parse(map['deleted_at']) : null,
    );
  }

  EventModel copyWith({
    String? title,
    String? description,
    List<String>? tags,
    DateTime? date,
    String? location,
    List<String>? attachments,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return EventModel(
      id: id,
      userId: userId,
      title: title ?? this.title,
      description: description ?? this.description,
      tags: tags ?? this.tags,
      date: date ?? this.date,
      location: location ?? this.location,
      attachments: attachments ?? this.attachments,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }
}
