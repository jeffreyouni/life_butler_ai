
import 'dart:typed_data';

class EmbeddingModel {
  final String id;
  final String objectType;
  final String objectId;
  final String chunkText;
  final Uint8List vectorBlob;
  final DateTime createdAt;

  const EmbeddingModel({
    required this.id,
    required this.objectType,
    required this.objectId,
    required this.chunkText,
    required this.vectorBlob,
    required this.createdAt,
  });

  factory EmbeddingModel.fromJson(Map<String, dynamic> json) {
    return EmbeddingModel(
      id: json['id'] as String,
      objectType: json['object_type'] as String,
      objectId: json['object_id'] as String,
      chunkText: json['chunk_text'] as String,
      vectorBlob: Uint8List.fromList((json['vector_blob'] as List).cast<int>()),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  factory EmbeddingModel.fromDrift(dynamic row) {
    return EmbeddingModel(
      id: row.id,
      objectType: row.objectType,
      objectId: row.objectId,
      chunkText: row.chunkText,
      vectorBlob: row.vectorBlob,
      createdAt: row.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'object_type': objectType,
      'object_id': objectId,
      'chunk_text': chunkText,
      'vector_blob': vectorBlob.toList(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  EmbeddingModel copyWith({
    String? id,
    String? objectType,
    String? objectId,
    String? chunkText,
    Uint8List? vectorBlob,
    DateTime? createdAt,
  }) {
    return EmbeddingModel(
      id: id ?? this.id,
      objectType: objectType ?? this.objectType,
      objectId: objectId ?? this.objectId,
      chunkText: chunkText ?? this.chunkText,
      vectorBlob: vectorBlob ?? this.vectorBlob,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is EmbeddingModel &&
        other.id == id &&
        other.objectType == objectType &&
        other.objectId == objectId &&
        other.chunkText == chunkText &&
        other.vectorBlob.toString() == vectorBlob.toString() &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        objectType.hashCode ^
        objectId.hashCode ^
        chunkText.hashCode ^
        vectorBlob.hashCode ^
        createdAt.hashCode;
  }

  @override
  String toString() {
    return 'EmbeddingModel(id: $id, objectType: $objectType, '
        'objectId: $objectId, chunkText: $chunkText, '
        'vectorBlob: ${vectorBlob.length} bytes, createdAt: $createdAt)';
  }
}
