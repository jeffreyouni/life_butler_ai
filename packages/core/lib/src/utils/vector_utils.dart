import 'dart:math' as math;

/// Utility functions for vector operations
class VectorUtils {
  /// Calculate cosine similarity between two vectors
  static double cosineSimilarity(List<double> a, List<double> b) {
    if (a.length != b.length) {
      throw ArgumentError('Vector dimensions must match: ${a.length} vs ${b.length}');
    }

    double dotProduct = 0.0;
    double normA = 0.0;
    double normB = 0.0;

    for (int i = 0; i < a.length; i++) {
      dotProduct += a[i] * b[i];
      normA += a[i] * a[i];
      normB += b[i] * b[i];
    }

    if (normA == 0.0 || normB == 0.0) return 0.0;
    return dotProduct / (math.sqrt(normA) * math.sqrt(normB));
  }

  /// Calculate Euclidean distance between two vectors
  static double euclideanDistance(List<double> a, List<double> b) {
    if (a.length != b.length) {
      throw ArgumentError('Vector dimensions must match');
    }

    double sum = 0.0;
    for (int i = 0; i < a.length; i++) {
      final diff = a[i] - b[i];
      sum += diff * diff;
    }

    return math.sqrt(sum);
  }

  /// Normalize a vector to unit length
  static List<double> normalize(List<double> vector) {
    final norm = math.sqrt(vector.map((x) => x * x).reduce((a, b) => a + b));
    if (norm == 0.0) return vector;
    return vector.map((x) => x / norm).toList();
  }

  /// Calculate the magnitude (norm) of a vector
  static double magnitude(List<double> vector) {
    return math.sqrt(vector.map((x) => x * x).reduce((a, b) => a + b));
  }

  /// Add two vectors element-wise
  static List<double> add(List<double> a, List<double> b) {
    if (a.length != b.length) {
      throw ArgumentError('Vector dimensions must match');
    }
    return [for (int i = 0; i < a.length; i++) a[i] + b[i]];
  }

  /// Subtract vector b from vector a element-wise
  static List<double> subtract(List<double> a, List<double> b) {
    if (a.length != b.length) {
      throw ArgumentError('Vector dimensions must match');
    }
    return [for (int i = 0; i < a.length; i++) a[i] - b[i]];
  }

  /// Multiply vector by scalar
  static List<double> scale(List<double> vector, double scalar) {
    return vector.map((x) => x * scalar).toList();
  }

  /// Calculate dot product of two vectors
  static double dotProduct(List<double> a, List<double> b) {
    if (a.length != b.length) {
      throw ArgumentError('Vector dimensions must match');
    }
    return [for (int i = 0; i < a.length; i++) a[i] * b[i]]
        .reduce((sum, value) => sum + value);
  }

  /// Find the most similar vectors using cosine similarity
  static List<SimilarityResult> findMostSimilar(
    List<double> queryVector,
    Map<String, List<double>> vectors, {
    int limit = 10,
    double minSimilarity = 0.0,
  }) {
    final results = <SimilarityResult>[];

    for (final entry in vectors.entries) {
      final similarity = cosineSimilarity(queryVector, entry.value);
      if (similarity >= minSimilarity) {
        results.add(SimilarityResult(
          id: entry.key,
          similarity: similarity,
        ));
      }
    }

    // Sort by similarity (descending)
    results.sort((a, b) => b.similarity.compareTo(a.similarity));

    return results.take(limit).toList();
  }

  /// Perform weighted average of vectors
  static List<double> weightedAverage(
    List<List<double>> vectors,
    List<double> weights,
  ) {
    if (vectors.length != weights.length) {
      throw ArgumentError('Number of vectors must match number of weights');
    }

    if (vectors.isEmpty) return [];

    final dimension = vectors.first.length;
    final result = List<double>.filled(dimension, 0.0);
    double totalWeight = 0.0;

    for (int i = 0; i < vectors.length; i++) {
      if (vectors[i].length != dimension) {
        throw ArgumentError('All vectors must have the same dimension');
      }

      final weight = weights[i];
      totalWeight += weight;

      for (int j = 0; j < dimension; j++) {
        result[j] += vectors[i][j] * weight;
      }
    }

    if (totalWeight == 0.0) return result;

    // Normalize by total weight
    for (int i = 0; i < dimension; i++) {
      result[i] /= totalWeight;
    }

    return result;
  }
}

/// Result of similarity calculation
class SimilarityResult {
  const SimilarityResult({
    required this.id,
    required this.similarity,
  });

  final String id;
  final double similarity;

  @override
  String toString() => 'SimilarityResult(id: $id, similarity: $similarity)';
}
