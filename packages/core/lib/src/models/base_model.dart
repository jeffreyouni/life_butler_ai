import 'package:meta/meta.dart';

/// Base model with common fields for all domain objects
@immutable
abstract class BaseModel {
  const BaseModel({
    required this.id,
    required this.userId,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  final String id;
  final String userId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  /// Whether this model is soft-deleted
  bool get isDeleted => deletedAt != null;

  /// Convert to map for serialization
  Map<String, dynamic> toMap();

  /// Object type identifier for embeddings and KG
  String get objectType;

  /// Get searchable text content for RAG
  String get searchableContent;

  /// Get display title for UI
  String get displayTitle;

  /// Get tags for filtering
  List<String> get tags;
}
