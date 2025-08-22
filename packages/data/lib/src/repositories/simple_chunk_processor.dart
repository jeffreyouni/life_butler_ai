import 'package:core/core.dart';

/// Simple implementation of ChunkProcessor
class SimpleChunkProcessor implements ChunkProcessor {
  final int maxChunkSize;
  final int overlapSize;

  SimpleChunkProcessor({
    this.maxChunkSize = 500,
    this.overlapSize = 50,
  });

  @override
  Future<List<String>> processText(String text) async {
    if (text.trim().isEmpty) return [];
    
    // Use the static utility for chunking
    return TextChunker.chunkText(
      text,
      maxTokens: maxChunkSize ~/ 4, // Approximate tokens from characters
      overlap: overlapSize ~/ 4,
    );
  }
}
