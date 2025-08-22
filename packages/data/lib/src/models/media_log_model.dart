import 'package:core/core.dart';
import 'package:meta/meta.dart';

@immutable
class MediaLogModel extends BaseModel {
  const MediaLogModel({
    required super.id,
    required super.userId,
    required super.createdAt,
    required super.updatedAt,
    super.deletedAt,
    required this.title,
    required this.mediaType,
    required this.time,
    this.progress,
    this.rating,
    this.notes,
  });

  final String title;
  final String mediaType;
  final DateTime time;
  final String? progress;
  final int? rating;
  final String? notes;

  @override
  String get objectType => 'media_logs';

  @override
  String get searchableContent {
    final buffer = StringBuffer();
    
    // Media log with semantic labels
    buffer.writeln('Media Log:');
    buffer.writeln('Title: $title');
    buffer.writeln('Type: $mediaType');
    buffer.writeln('Date: ${time.toIso8601String().split('T')[0]}');
    
    if (progress != null && progress!.isNotEmpty) {
      buffer.writeln('Progress: $progress');
    }
    
    if (rating != null) {
      buffer.writeln('Rating: $rating/10');
    }
    
    if (notes != null && notes!.isNotEmpty) {
      buffer.writeln('Notes: $notes');
    }
    
    return buffer.toString().trim();
  }

  @override
  String get displayTitle => '$title ($mediaType)';

  @override
  List<String> get tags {
    final mediaTags = <String>['media', mediaType];
    if (rating != null) {
      mediaTags.add('rating_$rating');
    }
    return mediaTags;
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'media_type': mediaType,
      'progress': progress,
      'rating': rating,
      'time': time.toIso8601String(),
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'deleted_at': deletedAt?.toIso8601String(),
    };
  }

  factory MediaLogModel.fromMap(Map<String, dynamic> map) {
    return MediaLogModel(
      id: map['id'],
      userId: map['user_id'],
      title: map['title'],
      mediaType: map['media_type'],
      time: DateTime.parse(map['time']),
      progress: map['progress'],
      rating: map['rating'],
      notes: map['notes'],
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
      deletedAt: map['deleted_at'] != null ? DateTime.parse(map['deleted_at']) : null,
    );
  }

  MediaLogModel copyWith({
    String? title,
    String? mediaType,
    DateTime? time,
    String? progress,
    int? rating,
    String? notes,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return MediaLogModel(
      id: id,
      userId: userId,
      title: title ?? this.title,
      mediaType: mediaType ?? this.mediaType,
      time: time ?? this.time,
      progress: progress ?? this.progress,
      rating: rating ?? this.rating,
      notes: notes ?? this.notes,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }
}
