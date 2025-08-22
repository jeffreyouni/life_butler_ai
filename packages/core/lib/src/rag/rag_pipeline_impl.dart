import 'dart:convert';
import 'dart:math';
import '../models/base_model.dart';
import '../models/embedding.dart';
import '../domain/domain_data_retriever.dart';
import 'package:providers_llm/providers_llm.dart'; // Import Message from providers_llm
import 'search_result.dart';
import 'chunk_processor.dart';
import 'rag_pipeline.dart';
import '../utils/logger.dart';

/// Enhanced RAG pipeline with domain data indexing support and LLM integration
class RagPipelineImpl implements RagPipeline {
  static final _logger = Logger('RagPipeline');
  
  final EmbeddingRepository _embeddingRepo;
  final ChunkProcessor _chunkProcessor;
  final EmbeddingService _embeddingService;
  final DomainDataRetriever? _domainRetriever;
  final dynamic _llmProvider; // LLM provider for generating responses

  RagPipelineImpl({
    required EmbeddingRepository embeddingRepo,
    required ChunkProcessor chunkProcessor,
    required EmbeddingService embeddingService,
    DomainDataRetriever? domainRetriever,
    dynamic llmProvider, // Optional LLM provider
  })  : _embeddingRepo = embeddingRepo,
        _chunkProcessor = chunkProcessor,
        _embeddingService = embeddingService,
        _domainRetriever = domainRetriever,
        _llmProvider = llmProvider;

  @override
  Future<void> ingest(BaseModel object, {EmbeddingProgressCallback? onProgress}) async {
    try {
      // 1. Extract searchable text from object
      final searchableText = _extractSearchableText(object);
      if (searchableText.isEmpty) return;

      // 2. Chunk the text
      final chunks = await _chunkProcessor.processText(searchableText);
      if (chunks.isEmpty) return;

      // 3. Generate embeddings
      final embeddings = await _embeddingService.embed(chunks);

      // 4. Store embeddings with metadata
      for (int i = 0; i < chunks.length; i++) {
        final embedding = Embedding(
          id: '${object.id}_chunk_$i',
          objectType: object.runtimeType.toString(),
          objectId: object.id,
          chunkText: chunks[i],
          vector: embeddings[i],
          createdAt: DateTime.now(),
        );
        await _embeddingRepo.create(embedding);
      }
    } catch (e) {
      _logger.info('Error ingesting ${object.runtimeType}: $e');
    }
  }

  @override
  Future<List<SearchResult>> search(
    String query, {
    List<String>? objectTypes,
    DateTime? startDate,
    DateTime? endDate,
    List<String>? tags,
    int limit = 10,
    double minScore = 0.1,
  }) async {
    try {
      // 1. Generate query embedding
      final queryEmbeddings = await _embeddingService.embed([query]);
      final queryVector = queryEmbeddings.first;

      // 2. Search for similar embeddings
      final candidates = await _embeddingRepo.findSimilar(
        queryVector: queryVector,
        objectTypes: objectTypes,
        startDate: startDate,
        endDate: endDate,
        limit: limit * 2, // Get more candidates for better filtering
        threshold: minScore,
      );

      // 3. Convert to SearchResult and calculate similarities
      final searchResults = <SearchResult>[];
      for (final embedding in candidates) {
        final similarity = _calculateCosineSimilarity(queryVector, embedding.vector);
        if (similarity >= minScore) {
          searchResults.add(SearchResult(
            id: embedding.id,
            text: embedding.chunkText,
            objectType: embedding.objectType,
            objectId: embedding.objectId,
            similarity: similarity,
          ));
        }
      }

      // 4. Sort by similarity and return top results
      searchResults.sort((a, b) => b.similarity.compareTo(a.similarity));
      return searchResults.take(limit).toList();
    } catch (e) {
      _logger.info('Error searching: $e');
      return [];
    }
  }

  @override
  Future<String> answer(
    String query, {
    List<String>? objectTypes,
    DateTime? startDate,
    DateTime? endDate,
    List<String>? tags,
    int maxContextLength = 4000,
    Map<String, String>? promptTemplates,
    String? calculationSummary,
  }) async {
    _logger.debug('🔍 RAG Pipeline answer() called with query: "$query"');
    
    // 1. Perform search to get relevant context
    final searchResults = await search(
      query,
      objectTypes: objectTypes,
      startDate: startDate,
      endDate: endDate,
      tags: tags,
      limit: 10,
    );

    _logger.debug('🔍 Found ${searchResults.length} search results');
    
    if (searchResults.isEmpty) {
      return _generateNoDataMessage(query);
    }

    // 2. Assemble context from search results
    final context = _assembleContext(searchResults, maxContextLength);

    // 3. Create prompt for LLM
    final prompt = _createPrompt(query, context, promptTemplates, calculationSummary);
    
    _logger.info('📝 Generated LLM prompt (${prompt.length} chars)');
    
    // 4. Use LLM provider to generate response if available
    if (_llmProvider != null) {
      try {
        final messages = [
          Message.user(prompt),
        ];
        
        _logger.info('🤖 Calling LLM to generate response...');
        final response = await _llmProvider.chat(messages, temperature: 0.7);
        _logger.info('✅ LLM response generated successfully');
        return response;
      } catch (e) {
        _logger.error('❌ LLM call failed: $e, falling back to simple response');
        return _generateSimpleResponse(query, searchResults);
      }
    } else {
      _logger.warning('⚠️ No LLM provider available, using simple response');
      return _generateSimpleResponse(query, searchResults);
    }
  }

  @override
  Future<void> rebuildEmbeddings({
    void Function(int current, int total)? onProgress,
  }) async {
    _logger.info('🔄 Starting embedding rebuild...');
    
    if (_domainRetriever == null) {
      _logger.warning('⚠️ No domain retriever available, skipping rebuild');
      return;
    }
    
    try {
      // Get all domain records that need indexing
      final domainRecords = await _domainRetriever.getAllIndexableRecords();
      _logger.debug('📊 Found ${domainRecords.length} domain records to reindex');
      
      for (int i = 0; i < domainRecords.length; i++) {
        final record = domainRecords[i];
        // Convert IndexableRecord to a BaseModel-like structure for ingestion
        final baseModel = _createBaseModelFromRecord(record);
        await ingest(baseModel);
        
        // Report progress
        onProgress?.call(i + 1, domainRecords.length);
        
        if ((i + 1) % 10 == 0) {
          _logger.info('🔄 Processed ${i + 1}/${domainRecords.length} records');
        }
      }
      
      _logger.info('✅ Embedding rebuild completed');
    } catch (e) {
      _logger.error('❌ Error during embedding rebuild: $e');
    }
  }

  /// Extract searchable text from a domain object
  String _extractSearchableText(BaseModel object) {
    // Use the specialized searchableContent method instead of raw toMap()
    return object.searchableContent;
  }

  /// Assemble search results into coherent context
  String _assembleContext(List<SearchResult> results, int maxLength) {
    final buffer = StringBuffer();
    int currentLength = 0;
    
    buffer.writeln('## Relevant Information\n');
    
    for (int i = 0; i < results.length && currentLength < maxLength; i++) {
      final result = results[i];
      final entry = '${i + 1}. ${result.text}\n   (Type: ${result.objectType}, Relevance: ${(result.similarity * 100).toStringAsFixed(1)}%)\n\n';
      
      if (currentLength + entry.length > maxLength) break;
      
      buffer.write(entry);
      currentLength += entry.length;
    }
    
    return buffer.toString();
  }

  /// Create LLM prompt from query and context
  String _createPrompt(String query, String context, Map<String, String>? promptTemplates, String? calculationSummary) {
    final buffer = StringBuffer();
    
    _logger.debug('🔧 _createPrompt: promptTemplates = ${promptTemplates != null ? 'available (${promptTemplates.keys.join(', ')})' : 'null'}');
    
    // Use custom prompt template if provided
    if (promptTemplates != null && promptTemplates.containsKey('rag_prompt_template')) {
      String template = promptTemplates['rag_prompt_template']!;
      _logger.debug('🎯 Using custom RAG prompt template: ${template.substring(0, template.length.clamp(0, 100))}...');
      
      template = template.replaceAll('{query}', query);
      template = template.replaceAll('{context}', context);
      
      // Handle calculation summary placeholder
      if (calculationSummary != null && calculationSummary.isNotEmpty) {
        template = template.replaceAll('{calculation_summary}', 
          '\n**Calculation Summary:**\n$calculationSummary\n');
      } else {
        // Remove the placeholder if no calculation summary is provided
        template = template.replaceAll('{calculation_summary}', '');
      }
      
      // Clean up any double newlines created by placeholder removal
      template = template.replaceAll(RegExp(r'\n\s*\n\s*\n'), '\n\n');
      
      _logger.debug('📝 Final prompt from template: ${template.substring(0, template.length.clamp(0, 200))}...');
      return template;
    }
    
    // Default prompt
    _logger.warning('⚠️ Using default RAG prompt (no custom template found)');
    buffer.writeln('You are a helpful personal AI assistant. A user has asked you a question about their personal data.');
    buffer.writeln('');
    buffer.writeln('User Question: $query');
    buffer.writeln('');
    if (calculationSummary != null) {
      buffer.writeln('Calculation Summary: $calculationSummary');
      buffer.writeln('');
    }
    buffer.writeln(context);
    buffer.writeln('');
    buffer.writeln('Please provide a helpful, accurate, and natural response based on the user\'s personal data above.');
    buffer.writeln('Be conversational and focus on insights that would be useful to the user.');
    
    return buffer.toString();
  }

  /// Generate simple fallback response when LLM is not available
  String _generateSimpleResponse(String query, List<SearchResult> results) {
    final buffer = StringBuffer();
    
    buffer.writeln('Based on your data, here\'s what I found regarding "$query":');
    buffer.writeln();
    
    for (int i = 0; i < results.take(5).length; i++) {
      final result = results[i];
      buffer.writeln('${i + 1}. ${result.text}');
      if (i < results.length - 1) buffer.writeln();
    }
    
    if (results.length > 5) {
      buffer.writeln();
      buffer.writeln('...and ${results.length - 5} more related entries in your data.');
    }
    
    return buffer.toString();
  }

  /// Generate message when no relevant data is found
  String _generateNoDataMessage(String query) {
    return 'I couldn\'t find relevant information in your data to answer: "$query". You may need to add more data or try a different question.';
  }

  /// Calculate cosine similarity between two vectors
  double _calculateCosineSimilarity(List<double> a, List<double> b) {
    if (a.length != b.length) return 0.0;
    
    double dotProduct = 0.0;
    double normA = 0.0;
    double normB = 0.0;
    
    for (int i = 0; i < a.length; i++) {
      dotProduct += a[i] * b[i];
      normA += a[i] * a[i];
      normB += b[i] * b[i];
    }
    
    if (normA == 0.0 || normB == 0.0) return 0.0;
    
    return dotProduct / (sqrt(normA) * sqrt(normB));
  }

  /// Convert IndexableRecord to BaseModel for ingestion
  BaseModel _createBaseModelFromRecord(IndexableRecord record) {
    return _IndexableRecordWrapper(record);
  }

  /// Get indexing status for the UI
  Future<Map<String, dynamic>> getIndexingStatus() async {
    try {
      // Get counts of embedded data by type
      final embeddingCounts = await _getEmbeddingCounts();
      
      // Check if domain data is available
      final domainDataCounts = _domainRetriever != null 
          ? await _domainRetriever.getDomainDataCounts()
          : <String, int>{};
      
      return {
        'totalEmbeddings': embeddingCounts.values.fold(0, (sum, count) => sum + count),
        'embeddingsByType': embeddingCounts,
        'domainDataCounts': domainDataCounts,
        'indexingComplete': embeddingCounts.isNotEmpty,
      };
    } catch (e) {
      _logger.info('Error getting indexing status: $e');
      return {
        'totalEmbeddings': 0,
        'embeddingsByType': <String, int>{},
        'domainDataCounts': <String, int>{},
        'indexingComplete': false,
      };
    }
  }

  /// Get embedding counts by object type
  Future<Map<String, int>> _getEmbeddingCounts() async {
    try {
      // Get all embeddings grouped by object type
      final allEmbeddings = await _embeddingRepo.searchSimilar(limit: 10000);
      final counts = <String, int>{};
      
      for (final embedding in allEmbeddings) {
        final objectType = embedding.objectType;
        counts[objectType] = (counts[objectType] ?? 0) + 1;
      }
      
      return counts;
    } catch (e) {
      _logger.info('Error getting embedding counts: $e');
      return <String, int>{};
    }
  }
}

/// Wrapper to make IndexableRecord compatible with BaseModel interface
class _IndexableRecordWrapper implements BaseModel {
  final IndexableRecord _record;
  
  _IndexableRecordWrapper(this._record);
  
  @override
  String get id => _record.id;
  
  @override
  String get objectType => _record.objectType;
  
  @override
  DateTime get createdAt => _record.timestamp;
  
  @override
  List<String> get tags => [];
  
  @override
  String get userId => _record.userId ?? '';
  
  @override
  Map<String, dynamic> toMap() => _record.structuredData;
  
  @override
  String get displayTitle => _record.objectType;
  
  @override
  String get searchableContent => _record.toSearchableText();
  
  @override
  bool get isDeleted => false;
  
  @override
  DateTime? get deletedAt => null;
  
  @override
  DateTime get updatedAt => _record.timestamp;
}

/// Embedding service interface for RAG
abstract class EmbeddingService {
  Future<List<List<double>>> embed(List<String> texts, {EmbeddingProgressCallback? onProgress});
}

/// Repository interface for embeddings
abstract class EmbeddingRepository {
  Future<void> create(Embedding embedding);
  Future<List<Embedding>> searchSimilar({
    List<String>? objectTypes,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 100,
  });
  Future<void> deleteByObject(String objectType, String objectId);
  
  /// Enhanced similarity search with query vector and threshold
  Future<List<Embedding>> findSimilar({
    required List<double> queryVector,
    List<String>? objectTypes,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 10,
    double threshold = 0.0,
  });
}
