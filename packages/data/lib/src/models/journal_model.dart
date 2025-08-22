import 'package:core/core.dart';
import 'package:meta/meta.dart';

@immutable
class JournalModel extends BaseModel {
  const JournalModel({
    required super.id,
    required super.userId,
    required super.createdAt,
    required super.updatedAt,
    super.deletedAt,
    required this.contentMd,
    this.moodInt,
    this.topics = const [],
  });

  final String contentMd;
  final int? moodInt;
  final List<String> topics;

  @override
  String get objectType => 'journals';

  @override
  String get searchableContent {
    final buffer = StringBuffer();
    
    // Journal entry with semantic labels
    buffer.writeln('Journal Entry:');
    buffer.writeln('Date: ${createdAt.toIso8601String().split('T')[0]}');
    
    if (moodInt != null) {
      final moodLabels = {1: 'Very Bad', 2: 'Bad', 3: 'Neutral', 4: 'Good', 5: 'Excellent'};
      buffer.writeln('Mood: ${moodLabels[moodInt]} ($moodInt/5)');
    }
    
    if (topics.isNotEmpty) {
      buffer.writeln('Topics: ${topics.join(', ')}');
    }
    
    buffer.writeln('Content:');
    buffer.writeln(contentMd);
    
    return buffer.toString().trim();
  }

  @override
  String get displayTitle => 'Journal Entry - ${createdAt.day}/${createdAt.month}/${createdAt.year}';

  @override
  List<String> get tags {
    final journalTags = <String>['journal', 'diary'];
    journalTags.addAll(topics);
    if (moodInt != null) {
      journalTags.add('mood_$moodInt');
    }
    return journalTags;
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'content_md': contentMd,
      'mood_int': moodInt,
      'topics_json': topics,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'deleted_at': deletedAt?.toIso8601String(),
    };
  }

  factory JournalModel.fromMap(Map<String, dynamic> map) {
    return JournalModel(
      id: map['id'],
      userId: map['user_id'],
      contentMd: map['content_md'],
      moodInt: map['mood_int'],
      topics: List<String>.from(map['topics_json'] ?? []),
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
      deletedAt: map['deleted_at'] != null ? DateTime.parse(map['deleted_at']) : null,
    );
  }

  JournalModel copyWith({
    String? contentMd,
    int? moodInt,
    List<String>? topics,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return JournalModel(
      id: id,
      userId: userId,
      contentMd: contentMd ?? this.contentMd,
      moodInt: moodInt ?? this.moodInt,
      topics: topics ?? this.topics,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }
}
