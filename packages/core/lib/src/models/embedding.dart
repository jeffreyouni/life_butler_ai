import 'dart:math' as dart_math;
import 'package:meta/meta.dart';

@immutable
class Embedding {
  const Embedding({
    required this.id,
    required this.objectType,
    required this.objectId,
    required this.chunkText,
    required this.vector,
    required this.createdAt,
  });

  final String id;
  final String objectType;
  final String objectId;
  final String chunkText;
  final List<double> vector;
  final DateTime createdAt;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'object_type': objectType,
      'object_id': objectId,
      'chunk_text': chunkText,
      'vector_blob': vector,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Embedding.fromMap(Map<String, dynamic> map) {
    return Embedding(
      id: map['id'],
      objectType: map['object_type'],
      objectId: map['object_id'],
      chunkText: map['chunk_text'],
      vector: List<double>.from(map['vector_blob']),
      createdAt: DateTime.parse(map['created_at']),
    );
  }

  /// Calculate cosine similarity with another embedding
  double cosineSimilarity(Embedding other) {
    if (vector.length != other.vector.length) {
      throw ArgumentError('Vector dimensions must match');
    }

    double dotProduct = 0.0;
    double normA = 0.0;
    double normB = 0.0;

    for (int i = 0; i < vector.length; i++) {
      dotProduct += vector[i] * other.vector[i];
      normA += vector[i] * vector[i];
      normB += other.vector[i] * other.vector[i];
    }

    if (normA == 0.0 || normB == 0.0) return 0.0;
    return dotProduct / (normA.sqrt() * normB.sqrt());
  }
}

extension DoubleExtension on double {
  double sqrt() => dart_math.sqrt(this);
}
