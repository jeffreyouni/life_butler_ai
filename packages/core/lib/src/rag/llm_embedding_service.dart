import 'rag_pipeline_impl.dart';
import 'rag_pipeline.dart';
import '../utils/logger.dart';

/// Embedding service implementation using LLM providers
class LLMEmbeddingService implements EmbeddingService {
  static final _logger = Logger('LLMEmbeddingService');
  
  final dynamic _provider; // Use dynamic to avoid direct dependency

  LLMEmbeddingService(this._provider);

  @override
  Future<List<List<double>>> embed(List<String> texts, {EmbeddingProgressCallback? onProgress}) async {
    if (texts.isEmpty) return [];
    
    _logger.info('🔮 LLMEmbeddingService.embed() called with ${texts.length} texts');
    for (int i = 0; i < texts.length.clamp(0, 3); i++) {
      _logger.info('   Text $i: ${texts[i].substring(0, texts[i].length.clamp(0, 50))}...');
    }
    
    try {
      // Process in smaller batches to avoid context issues
      const batchSize = 5; // Reduce batch size to prevent context overflow
      final List<List<double>> allEmbeddings = [];
      
      for (int i = 0; i < texts.length; i += batchSize) {
        final end = (i + batchSize < texts.length) ? i + batchSize : texts.length;
        final batch = texts.sublist(i, end);
        
        _logger.info('🔄 Processing batch ${i ~/ batchSize + 1}/${(texts.length / batchSize).ceil()}: ${batch.length} texts');
        
        try {
          // Call the actual API
          final batchEmbeddings = await _provider.embed(batch);
          
          _logger.info('✅ Batch embedding successful, got ${batchEmbeddings.length} vectors');
          
          
          if (batchEmbeddings.isNotEmpty) {
            final firstVector = batchEmbeddings.first;
            _logger.info('   Vector length: ${firstVector.length}');
            _logger.info('   Vector sample (first 5): ${firstVector.take(5).toList()}');
            _logger.info('   Vector sum: ${firstVector.fold(0.0, (a, b) => a + b)}');
            _logger.info('   Vector magnitude: ${firstVector.fold(0.0, (a, b) => a + b * b)}');
          }
          
          allEmbeddings.addAll(batchEmbeddings);
        } catch (e) {
          _logger.error('❌ Error generating embeddings for batch $i-$end: $e');
          // Add fallback embeddings for failed batch
          for (int j = 0; j < batch.length; j++) {
            final fallback = _getFallbackEmbedding();
            _logger.warning('⚠️ Using fallback embedding for text $j: length=${fallback.length}, sum=${fallback.fold(0.0, (a, b) => a + b)}');
            allEmbeddings.add(fallback);
          }
        }
        
        // Add small delay between batches to prevent overwhelming the model
        if (i + batchSize < texts.length) {
          await Future.delayed(const Duration(milliseconds: 100));
        }
      }
      
      _logger.info('✅ Total embeddings generated: ${allEmbeddings.length}');
      return allEmbeddings;
    } catch (e) {
      _logger.error('❌ Critical error generating embeddings: $e');
      // Return fallback vectors for all texts
      final fallbacks = List.generate(texts.length, (_) => _getFallbackEmbedding());
      _logger.warning('⚠️ Using ${fallbacks.length} fallback embeddings');
      return fallbacks;
    }
  }
  
  /// Get fallback embedding vector (zero vector with appropriate dimensions)
  List<double> _getFallbackEmbedding() {
    // Use 768 dimensions for nomic-embed-text
    final providerName = _provider.name?.toString().toLowerCase() ?? '';
    final dimensions = providerName == 'ollama' ? 768 : 1536;
    return List.filled(dimensions, 0.0);
  }
}
