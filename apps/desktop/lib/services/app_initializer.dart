import 'package:data/data.dart';
import 'package:core/core.dart';
import 'comprehensive_seed_data_en.dart';
import 'embedding_status.dart';

class AppInitializer {
  static LifeButlerDatabase? _sharedDatabase;
  static final _logger = Logger('AppInitializer');
  
  static LifeButlerDatabase getSharedDatabase() {
    _sharedDatabase ??= LifeButlerDatabase();
    return _sharedDatabase!;
  }
  
  static Future<void> initializeBasicData() async {
    try {
      final database = getSharedDatabase();
      
      _logger.info('Database initialized successfully');
      _logger.info('Data package import working!');
      
      // Initialize basic data without RAG embeddings
      try {
        _logger.info('Initializing basic data...');
        final seedData = ComprehensiveSeedData(database);
        await seedData.generateBasicData(); // New method for data without embeddings
        _logger.info('Basic data generation complete!');
      } catch (seedError) {
        _logger.warning('Basic data initialization failed: $seedError');
        _logger.warning('Application will continue without test data.');
      }
      
    } catch (e) {
      _logger.error('Error initializing basic data', e);
    }
  }
  
  /// Initialize embeddings after Riverpod is available
  static Future<void> initializeEmbeddings(LifeButlerDatabase database, RagPipeline ragPipeline) async {
    // Check if embeddings are already being generated or completed
    if (EmbeddingStatus.isGenerating || EmbeddingStatus.isComplete) {
      _logger.info('Embeddings already initialized or in progress, skipping...');
      return;
    }
    
    try {
      // Start embedding generation
      EmbeddingStatus.startGeneration();
      _logger.info('Generating embeddings for RAG system...');
      
      final seedData = ComprehensiveSeedData(database, ragPipeline: ragPipeline);
      await seedData.generateEmbeddingsOnly();
      
      // Mark as complete
      EmbeddingStatus.markComplete();
      _logger.info('Embeddings generation complete!');
    } catch (e) {
      // Reset status on error so it can be retried
      EmbeddingStatus.reset();
      _logger.error('Error generating embeddings', e);
      rethrow;
    }
  }
}
