import 'dart:math' as math;
import 'dart:typed_data';

import 'package:core/core.dart' hide Embedding;
import 'package:core/src/models/embedding.dart' as core;
import '../database/database.dart';

/// Drift implementation of EmbeddingRepository
class DriftEmbeddingRepository implements EmbeddingRepository {
  final LifeButlerDatabase _database;
  bool _firstCalculation = true;
  static final _logger = Logger('DriftEmbeddingRepository');

  DriftEmbeddingRepository(this._database);

  @override
  Future<void> create(core.Embedding embedding) async {
    // Convert vector to blob
    final vectorBytes = _vectorToBytes(embedding.vector);
    
    final embeddingCompanion = EmbeddingsCompanion.insert(
      id: embedding.id,
      objectType: embedding.objectType,
      objectId: embedding.objectId,
      chunkText: embedding.chunkText,
      vectorBlob: vectorBytes,
      createdAt: embedding.createdAt,
    );

    await _database.into(_database.embeddings).insertOnConflictUpdate(embeddingCompanion);
  }

  @override
  Future<List<core.Embedding>> searchSimilar({
    List<String>? objectTypes,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 100,
  }) async {
    _logger.debug('DriftEmbeddingRepository.searchSimilar() called with:');
    _logger.debug('ObjectTypes: $objectTypes');
    _logger.debug('StartDate: $startDate');
    _logger.debug('EndDate: $endDate');
    _logger.debug('Limit: $limit');
    
    // Build query with filters
    var query = _database.select(_database.embeddings);
    
    if (objectTypes != null && objectTypes.isNotEmpty) {
      _logger.debug('Filtering by object types: $objectTypes');
      query = query..where((tbl) => tbl.objectType.isIn(objectTypes));
    }
    
    // Skip date filtering for now to fix compilation
    // TODO: Fix date filtering syntax
    
    query = query..limit(limit);
    
    _logger.debug('Executing database query...');
    final results = await query.get();
    
    _logger.debug('Database returned ${results.length} raw embeddings');
    
    // Convert to Embedding objects
    final embeddings = results.map((row) => core.Embedding(
      id: row.id,
      objectType: row.objectType,
      objectId: row.objectId,
      chunkText: row.chunkText,
      vector: _vectorFromBytes(row.vectorBlob),
      createdAt: row.createdAt,
    )).toList();
    
    _logger.debug('Converted to ${embeddings.length} core.Embedding objects');
    
    if (embeddings.isNotEmpty) {
      _logger.verbose('Sample embeddings:');
      for (int i = 0; i < embeddings.length.clamp(0, 3); i++) {
        final emb = embeddings[i];
        _logger.verbose('$i: ${emb.objectType}/${emb.objectId} - ${emb.chunkText.substring(0, emb.chunkText.length.clamp(0, 50))}...');
      }
    }
    
    return embeddings;
  }

  @override
  Future<void> deleteByObject(String objectType, String objectId) async {
    await (_database.delete(_database.embeddings)
      ..where((tbl) => tbl.objectType.equals(objectType))
      ..where((tbl) => tbl.objectId.equals(objectId))
      ).go();
  }

  /// Additional method for similarity search with query vector
  @override
  Future<List<core.Embedding>> findSimilar({
    required List<double> queryVector,
    List<String>? objectTypes,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 10,
    double threshold = 0.0,
  }) async {
    _logger.debug('DriftEmbeddingRepository.findSimilar() called with:');
    _logger.debug('QueryVector length: ${queryVector.length}');
    _logger.debug('ObjectTypes: $objectTypes');
    _logger.debug('StartDate: $startDate');
    _logger.debug('EndDate: $endDate');
    _logger.debug('Limit: $limit');
    _logger.debug('Threshold: $threshold');
    
    // Get all candidates first
    _logger.debug('Getting candidate embeddings...');
    final candidates = await searchSimilar(
      objectTypes: objectTypes,
      startDate: startDate,
      endDate: endDate,
      limit: 1000, // Get more candidates for similarity calculation
    );
    
    _logger.debug('Retrieved ${candidates.length} candidate embeddings');
    
    if (candidates.isEmpty) {
      _logger.warning('No candidate embeddings found in database');
      return [];
    }

    // Calculate similarities and filter
    final results = <({core.Embedding embedding, double similarity})>[];
    
    _logger.debug('Calculating similarities...');
    for (int i = 0; i < candidates.length; i++) {
      final candidate = candidates[i];
      final similarity = _cosineSimilarity(queryVector, candidate.vector);
      
  if (i < 5) {
        _logger.verbose('Candidate $i: ${candidate.objectType}/${candidate.objectId} - similarity: ${similarity.toStringAsFixed(3)} (threshold: $threshold)');
      }
      
      if (similarity >= threshold) {
        results.add((embedding: candidate, similarity: similarity));
      }
    }
    
    _logger.debug('Found ${results.length} embeddings above threshold ($threshold)');

    // Sort by similarity (highest first) and limit
    results.sort((a, b) => b.similarity.compareTo(a.similarity));
    final finalResults = results.take(limit).map((r) => r.embedding).toList();
    
    _logger.info('📋 Returning top ${finalResults.length} results');
    return finalResults;
  }  /// Convert vector to bytes for storage
  Uint8List _vectorToBytes(List<double> vector) {
    final buffer = Float64List.fromList(vector);
    return buffer.buffer.asUint8List();
  }

  /// Convert bytes back to vector
  List<double> _vectorFromBytes(Uint8List bytes) {
    final buffer = Float64List.view(bytes.buffer);
    return buffer.toList();
  }

  /// Calculate cosine similarity between two vectors
  double _cosineSimilarity(List<double> a, List<double> b) {
    if (a.length != b.length) {
      _logger.error('❌ Vector length mismatch: ${a.length} vs ${b.length}');
      _logger.info('   This usually indicates embeddings from different models.');
      _logger.info('   Consider clearing embeddings and regenerating with consistent model.');
      return 0.0;
    }
    
    double dotProduct = 0.0;
    double normA = 0.0;
    double normB = 0.0;
    
    for (int i = 0; i < a.length; i++) {
      dotProduct += a[i] * b[i];
      normA += a[i] * a[i];
      normB += b[i] * b[i];
    }
    
    
    if (_firstCalculation) {
      _firstCalculation = false;
      _logger.debug('🧮 First cosine similarity calculation:');
      _logger.info('   Vector A length: ${a.length}, first 5: ${a.take(5).toList()}');
      _logger.info('   Vector B length: ${b.length}, first 5: ${b.take(5).toList()}');
      _logger.info('   Dot product: $dotProduct');
      _logger.info('   Norm A: $normA');
      _logger.info('   Norm B: $normB');
      _logger.info('   Sqrt Norm A: ${math.sqrt(normA)}');
      _logger.info('   Sqrt Norm B: ${math.sqrt(normB)}');
    }
    
    if (normA == 0.0 || normB == 0.0) {
      if (_firstCalculation) {
        _logger.error('❌ Zero norm detected - one or both vectors are zero vectors');
      }
      return 0.0;
    }
    
    final similarity = dotProduct / (math.sqrt(normA) * math.sqrt(normB));
    return similarity;
  }
}
