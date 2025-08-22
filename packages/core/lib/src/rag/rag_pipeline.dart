import 'package:meta/meta.dart';
import '../models/base_model.dart';
import 'search_result.dart';

/// Progress callback for embedding generation
typedef EmbeddingProgressCallback = void Function(int currentStep, int totalSteps, String operation);

/// Main RAG pipeline interface
abstract class RagPipeline {
  /// Ingest an object: normalize → chunk → embed → store
  Future<void> ingest(BaseModel object, {EmbeddingProgressCallback? onProgress});

  /// Search for relevant content
  Future<List<SearchResult>> search(
    String query, {
    List<String>? objectTypes,
    DateTime? startDate,
    DateTime? endDate,
    List<String>? tags,
    int limit = 10,
    double minScore = 0.1,
  });

  /// Generate answer with RAG
  Future<String> answer(
    String query, {
    List<String>? objectTypes,
    DateTime? startDate,
    DateTime? endDate,
    List<String>? tags,
    int maxContextLength = 4000,
    Map<String, String>? promptTemplates,
    String? calculationSummary, // For mixed queries
  });

  /// Rebuild all embeddings
  Future<void> rebuildEmbeddings({
    void Function(int current, int total)? onProgress,
  });
}

/// RAG search filters
@immutable
class SearchFilters {
  const SearchFilters({
    this.objectTypes,
    this.startDate,
    this.endDate,
    this.tags,
    this.userId,
  });

  final List<String>? objectTypes;
  final DateTime? startDate;
  final DateTime? endDate;
  final List<String>? tags;
  final String? userId;

  bool matches(BaseModel object) {
    if (userId != null && object.userId != userId) return false;
    if (objectTypes != null && !objectTypes!.contains(object.objectType)) {
      return false;
    }
    if (startDate != null && object.createdAt.isBefore(startDate!)) {
      return false;
    }
    if (endDate != null && object.createdAt.isAfter(endDate!)) return false;
    if (tags != null && tags!.isNotEmpty) {
      final objectTags = object.tags.map((t) => t.toLowerCase()).toSet();
      final filterTags = tags!.map((t) => t.toLowerCase()).toSet();
      if (objectTags.intersection(filterTags).isEmpty) return false;
    }
    return true;
  }
}

/// Context for RAG answers
@immutable
class RagContext {
  const RagContext({
    required this.query,
    required this.results,
    required this.totalTokens,
  });

  final String query;
  final List<SearchResult> results;
  final int totalTokens;

  /// Format context for LLM prompt
  String formatForPrompt() {
    final buffer = StringBuffer();
    buffer.writeln('Query: $query\n');
    buffer.writeln('Relevant context from personal data:\n');

    for (int i = 0; i < results.length; i++) {
      final result = results[i];
      buffer.writeln('[$i] ${result.citation}');
      buffer.writeln('Content: ${result.text}');
      buffer.writeln('Relevance: ${(result.similarity * 100).toStringAsFixed(1)}%\n');
    }

    return buffer.toString();
  }

  /// Get citations for the answer
  List<String> get citations {
    return results.map((r) => r.citation).toList();
  }
}
