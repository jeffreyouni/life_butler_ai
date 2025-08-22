import 'dart:math' as math;

/// Abstract interface for text chunking
abstract class ChunkProcessor {
  Future<List<String>> processText(String text);
}

/// Utility class for text chunking and processing
class TextChunker {
  static const int defaultMaxTokens = 512;
  static const int defaultOverlap = 50;

  /// Split text into chunks for embedding
  static List<String> chunkText(
    String text, {
    int maxTokens = defaultMaxTokens,
    int overlap = defaultOverlap,
  }) {
    if (text.isEmpty) return [];

    // Simple approximation: ~4 characters per token
    final maxChars = maxTokens * 4;
    final overlapChars = overlap * 4;

    if (text.length <= maxChars) {
      return [text];
    }

    final chunks = <String>[];
    var start = 0;

    while (start < text.length) {
      var end = math.min(start + maxChars, text.length);

      // Try to break at sentence boundaries
      if (end < text.length) {
        final lastSentence = text.lastIndexOf('.', end);
        final lastNewline = text.lastIndexOf('\n', end);
        final breakPoint = math.max(lastSentence, lastNewline);

        if (breakPoint > start + maxChars * 0.5) {
          end = breakPoint + 1;
        }
      }

      final chunk = text.substring(start, end).trim();
      if (chunk.isNotEmpty) {
        chunks.add(chunk);
      }

      start = math.max(start + 1, end - overlapChars);
    }

    return chunks;
  }

  /// Extract keywords from text for filtering
  static Set<String> extractKeywords(String text) {
    final words = text
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), ' ')
        .split(RegExp(r'\s+'))
        .where((word) => word.length > 2)
        .toSet();

    // Remove common stop words
    final stopWords = <String>{
      'the', 'and', 'or', 'but', 'in', 'on', 'at', 'to', 'for', 'of', 'with',
      'by', 'is', 'are', 'was', 'were', 'be', 'been', 'have', 'has', 'had',
      'do', 'does', 'did', 'will', 'would', 'could', 'should', 'may', 'might',
      'can', 'this', 'that', 'these', 'those', 'i', 'you', 'he', 'she', 'it',
      'we', 'they', 'me', 'him', 'her', 'us', 'them', 'my', 'your', 'his',
      'her', 'its', 'our', 'their'
    };

    return words.difference(stopWords);
  }

  /// Clean and normalize text
  static String normalizeText(String text) {
    return text
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(RegExp(r'[^\w\s.,!?-]'), '')
        .trim();
  }
}
