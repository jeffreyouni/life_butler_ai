import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:data/data.dart';
import 'package:providers_llm/providers_llm.dart';
import 'package:core/core.dart';
import '../services/app_initializer.dart';
import '../services/embedding_status.dart';
import '../services/app_data_access_delegate_simple_impl.dart';
import '../services/intelligent_chat_processor.dart';

final _logger = Logger('AppProviders');

// Theme provider
final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.system);

// Embedding generation completion status
final embeddingGenerationCompleteProvider = StateProvider<bool>((ref) => false);

// Domain indexing completion status - simple boolean
final domainIndexingCompleteProvider = StateProvider<bool>((ref) => false);

// Embedding status provider with real-time updates
class EmbeddingStatusNotifier extends StateNotifier<EmbeddingStatusData> {
  EmbeddingStatusNotifier() : super(EmbeddingStatusData.initial()) {
    // Listen to EmbeddingStatus changes
    EmbeddingStatus.addListener(_updateStatus);
    _updateStatus(); // Initial update
  }

  void _updateStatus() {
    state = EmbeddingStatusData(
      isComplete: EmbeddingStatus.isComplete,
      isGenerating: EmbeddingStatus.isGenerating,
    );
  }

  @override
  void dispose() {
    EmbeddingStatus.removeListener(_updateStatus);
    super.dispose();
  }
}

final embeddingStatusProvider = StateNotifierProvider<EmbeddingStatusNotifier, EmbeddingStatusData>((ref) {
  return EmbeddingStatusNotifier();
});

// Simplified data class for embedding status - only loading and completed
class EmbeddingStatusData {
  final bool isComplete;
  final bool isGenerating;

  const EmbeddingStatusData({
    required this.isComplete,
    required this.isGenerating,
  });

  factory EmbeddingStatusData.initial() {
    return const EmbeddingStatusData(
      isComplete: false,
      isGenerating: false,
    );
  }
}

// Database provider - use shared singleton instance
final databaseProvider = Provider<LifeButlerDatabase>((ref) {
  // Use the shared database instance from AppInitializer
  return AppInitializer.getSharedDatabase();
});

// Data providers for each domain
final eventsProvider = FutureProvider<List<Event>>((ref) async {
  final database = ref.watch(databaseProvider);
  return await database.select(database.events).get();
});

final mealsProvider = FutureProvider<List<Meal>>((ref) async {
  final database = ref.watch(databaseProvider);
  return await database.select(database.meals).get();
});

final journalsProvider = FutureProvider<List<Journal>>((ref) async {
  final database = ref.watch(databaseProvider);
  return await database.select(database.journals).get();
});

final financeRecordsProvider = FutureProvider<List<FinanceRecord>>((ref) async {
  final database = ref.watch(databaseProvider);
  return await database.select(database.financeRecords).get();
});

final healthMetricsProvider = FutureProvider<List<HealthMetric>>((ref) async {
  final database = ref.watch(databaseProvider);
  return await database.select(database.healthMetrics).get();
});

final educationProvider = FutureProvider<List<EducationData>>((ref) async {
  final database = ref.watch(databaseProvider);
  return await database.select(database.education).get();
});

// LLM configuration provider
final llmConfigProvider = Provider<LLMConfig>((ref) {
  return LLMConfig.fromEnvironment({
    'OLLAMA_BASE_URL': dotenv.env['OLLAMA_BASE_URL'] ?? '',
    'OLLAMA_CHAT_MODEL': dotenv.env['OLLAMA_CHAT_MODEL'] ?? '',
    'OLLAMA_EMBED_MODEL': dotenv.env['OLLAMA_EMBED_MODEL'] ?? '',
  });
});

// Provider selector provider
final providerSelectorProvider = Provider<ProviderSelector>((ref) {
  final config = ref.watch(llmConfigProvider);
  return ProviderSelector(
    config: config,
    strategy: ProviderStrategy.ollamaOnly,
  );
});

// Current LLM provider
final currentLLMProviderProvider = FutureProvider<ModelProvider?>((ref) async {
  final selector = ref.watch(providerSelectorProvider);
  return await selector.getCurrentProvider();
});

// Provider status
final providerStatusProvider = FutureProvider<ProviderStatus>((ref) async {
  final selector = ref.watch(providerSelectorProvider);
  return await selector.getProviderStatus();
});

// Selected navigation index
final selectedNavigationIndexProvider = StateProvider<int>((ref) => 0);

// AI Prompt templates provider (async loading, but stays synced with notifier)
final aiPromptTemplatesProvider = Provider<Map<String, String>>((ref) {
  return ref.watch(aiPromptTemplatesNotifierProvider);
});

// AI Prompt templates notifier for editing
final aiPromptTemplatesNotifierProvider = StateNotifierProvider<AIPromptTemplatesNotifier, Map<String, String>>((ref) {
  return AIPromptTemplatesNotifier();
});

// Async initialization provider
final aiPromptTemplatesInitProvider = FutureProvider<void>((ref) async {
  final notifier = ref.read(aiPromptTemplatesNotifierProvider.notifier);
  await notifier.ensureLoaded();
});

// AI Prompt templates notifier
class AIPromptTemplatesNotifier extends StateNotifier<Map<String, String>> {
  static const String _prefixKey = 'ai_prompt_template_';
  bool _isLoaded = false;
  
  AIPromptTemplatesNotifier() : super(_getDefaultPrompts());

  /// Ensure prompts are loaded from SharedPreferences
  Future<void> ensureLoaded() async {
    if (_isLoaded) return;
    await _loadPrompts();
    _isLoaded = true;
  }

  static Map<String, String> _getDefaultPrompts() {
    return {
      'system_prompt': '''You are Life Butler AI, a professional personal life data analyst.

Analyze the user's personal life data and provide deep insights and practical recommendations.

Response requirements:
- Respond in English
- Use Markdown format
- Provide specific numeric analyses where possible
- Offer actionable recommendations
- Cite specific data sources

Keep responses concise and valuable.''',
      'user_message_template': '''Please analyze the following question in detail: {query}''',
      'rag_prompt_template': '''Answer the user's question based on the following personal data:

**User question:** {query}

{calculation_summary}

{context}

**Response requirements:**
• Analyze based on the provided information
• Cite specific data sources where applicable
• Provide actionable recommendations (if applicable)
• Respond in English
• Use Markdown format''',
      'no_data_message': '''I understand your question: "{message}"

However, I need to analyze your personal data first. Please add some data in each section (events, meals, journals, etc.), and then I will be able to provide personalized insights and recommendations.''',
      'ai_unavailable_message': '''❌ **AI service unavailable**

Please check the following:
• Ensure Ollama is running
• Check your network connection

For now, here is a simple data-based summary:
{dataSummary}''',
    };
  }

  Future<void> _loadPrompts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final defaultPrompts = _getDefaultPrompts();
      final loadedPrompts = <String, String>{};
      
      for (final key in defaultPrompts.keys) {
        final savedValue = prefs.getString('$_prefixKey$key');
        loadedPrompts[key] = savedValue ?? defaultPrompts[key]!;
      }
      
      state = loadedPrompts;
    } catch (e) {
      // If loading fails, use defaults
      state = _getDefaultPrompts();
    }
  }

  Future<void> updatePrompt(String key, String value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('$_prefixKey$key', value);
      state = {...state, key: value};
      
      
      // Invalidate the async provider to force refresh
      // Note: In a real app, you might want to use a more sophisticated state management approach
    } catch (e) {
      // If saving fails, still update the state temporarily
      state = {...state, key: value};
      print('❌ Failed to save prompt "$key": $e');
    }
  }

  Future<void> resetToDefaults() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final defaultPrompts = _getDefaultPrompts();
      
      // Clear saved prompts
      for (final key in defaultPrompts.keys) {
        await prefs.remove('$_prefixKey$key');
      }
      
      state = defaultPrompts;
    } catch (e) {
      // If clearing fails, still reset state
      state = _getDefaultPrompts();
    }
  }

  String getPrompt(String key) {
    return state[key] ?? _getDefaultPrompts()[key] ?? '';
  }
}

// RAG-related providers

// Data access delegate provider
final dataAccessDelegateProvider = Provider<DataAccessDelegate>((ref) {
  final database = ref.watch(databaseProvider);
  return AppDataAccessDelegateSimple(database);
});

// Domain data retriever provider
final domainDataRetrieverProvider = Provider<DomainDataRetriever>((ref) {
  final dataAccess = ref.watch(dataAccessDelegateProvider);
  return DataLayerDomainRetriever(dataAccess);
});

// Embedding service provider
final embeddingServiceProvider = FutureProvider<EmbeddingService>((ref) async {
  // Wait for the provider to be available
  final provider = await ref.watch(currentLLMProviderProvider.future);
  if (provider == null) {
    _logger.warning('No LLM provider available, using dummy service');
    // Return a dummy service that returns zero vectors
    return _DummyEmbeddingService();
  }
  _logger.info('Using LLMEmbeddingService with ${provider.name}');
  return LLMEmbeddingService(provider);
});

// Embedding repository provider
final embeddingRepositoryProvider = Provider<EmbeddingRepository>((ref) {
  final database = ref.watch(databaseProvider);
  return DriftEmbeddingRepository(database);
});

// Chunk processor provider
final chunkProcessorProvider = Provider<ChunkProcessor>((ref) {
  return SimpleChunkProcessor();
});

// Enhanced RAG pipeline provider with domain data support and auto-indexing
final ragPipelineProvider = FutureProvider<RagPipeline>((ref) async {
  final embeddingRepo = ref.watch(embeddingRepositoryProvider);
  final chunkProcessor = ref.watch(chunkProcessorProvider);
  final embeddingService = await ref.watch(embeddingServiceProvider.future);
  final domainRetriever = ref.watch(domainDataRetrieverProvider);
  final llmProvider = await ref.watch(currentLLMProviderProvider.future);
  
  final pipeline = RagPipelineImpl(
    embeddingRepo: embeddingRepo,
    chunkProcessor: chunkProcessor,
    embeddingService: embeddingService,
    domainRetriever: domainRetriever,
    llmProvider: llmProvider,
  );

  // Trigger domain indexing if needed (async, non-blocking)
  _triggerDomainIndexingIfNeeded(pipeline, ref);
  
  return pipeline;
});

/// Helper function to trigger domain indexing without blocking the provider
void _triggerDomainIndexingIfNeeded(RagPipelineImpl pipeline, FutureProviderRef<RagPipeline> ref) {
  // Run indexing in background
  Future.delayed(const Duration(seconds: 2), () async {
    try {
      // Check if embeddings are already generating or complete
      if (EmbeddingStatus.isGenerating) {
        _logger.info('⚠️ Embeddings already generating, skipping domain indexing');
        return;
      }
      
      if (EmbeddingStatus.isComplete) {
        _logger.info('✅ Embeddings already complete, skipping domain indexing');
        ref.read(domainIndexingCompleteProvider.notifier).state = true;
        return;
      }

      final status = await pipeline.getIndexingStatus();
      final overallCoverage = status['overall_coverage'] as double? ?? 0.0;
      final totalRecords = status['total_domain_records'] as int? ?? 0;
      
      _logger.debug('Domain indexing status: ${(overallCoverage * 100).toStringAsFixed(1)}% coverage, $totalRecords total records');
      
      // If coverage is low or no records indexed, trigger indexing
      if (totalRecords > 0 && overallCoverage < 0.8) {
        _logger.info('Starting background domain indexing...');
        EmbeddingStatus.startGeneration(); // Mark as generating
        
        await pipeline.rebuildEmbeddings(
          onProgress: (current, total) {
            if (current % 5 == 0 || current == total) {
              _logger.debug('Domain indexing progress: $current/$total');
            }
          },
        );
        
        EmbeddingStatus.markComplete(); // Mark as complete
        _logger.info('Background domain indexing completed');
        // Set completion status to true after indexing is done
        ref.read(domainIndexingCompleteProvider.notifier).state = true;
        
      } else if (totalRecords == 0) {
        _logger.info('No domain records found to index');
        // No records means "complete" in a sense
        ref.read(domainIndexingCompleteProvider.notifier).state = true;
      } else {
        _logger.info('Domain indexing is up to date');
        // Already up to date means complete
        ref.read(domainIndexingCompleteProvider.notifier).state = true;
      }
    } catch (e) {
      EmbeddingStatus.reset(); // Reset on error
      _logger.error('Background domain indexing failed: $e');
      // Even on error, set to true to stop loading state
      ref.read(domainIndexingCompleteProvider.notifier).state = true;
    }
  });
}

// Enhanced router provider with domain support
final enhancedRouterProvider = FutureProvider<EnhancedRequestRouter>((ref) async {
  final ragPipeline = await ref.watch(ragPipelineProvider.future);
  // For now, use simple implementations for query planner and advice engine
  const queryPlanner = DefaultQueryPlanner();
  const adviceEngine = DefaultAdviceEngine();
  
  return EnhancedRequestRouter(
    queryPlanner: queryPlanner,
    ragPipeline: ragPipeline,
    adviceEngine: adviceEngine,
  );
});

// Real data aggregator provider
final dataAggregatorProvider = Provider<RealDataAggregator>((ref) {
  final database = ref.watch(databaseProvider);
  return RealDataAggregator(database: database);
});

// Request processor provider
final requestProcessorProvider = FutureProvider<RequestProcessor>((ref) async {
  // Ensure prompt templates are loaded first
  await ref.watch(aiPromptTemplatesInitProvider.future);
  
  final ragPipeline = await ref.watch(ragPipelineProvider.future);
  const adviceEngine = DefaultAdviceEngine();
  final dataAggregator = ref.watch(dataAggregatorProvider);
  final llmProvider = await ref.watch(currentLLMProviderProvider.future);
  final promptTemplates = ref.watch(aiPromptTemplatesProvider);
  
  return DefaultRequestProcessor(
    ragPipeline: ragPipeline,
    adviceEngine: adviceEngine,
    dataAggregator: dataAggregator,
    llmProvider: llmProvider,
    promptTemplates: promptTemplates,
  );
});

// Intelligent chat processor provider
final intelligentChatProcessorProvider = FutureProvider<IntelligentChatProcessor>((ref) async {
  // Ensure prompt templates are loaded first
  await ref.watch(aiPromptTemplatesInitProvider.future);
  
  final router = await ref.watch(enhancedRouterProvider.future);
  final processor = await ref.watch(requestProcessorProvider.future);
  final ragPipeline = await ref.watch(ragPipelineProvider.future);
  final database = ref.watch(databaseProvider);
  final promptTemplates = ref.watch(aiPromptTemplatesProvider);
  
  return IntelligentChatProcessor(
    router: router,
    processor: processor,
    ragPipeline: ragPipeline,
    database: database,
    promptTemplates: promptTemplates,
  );
});

// Domain indexing action provider (for triggering re-indexing)
final domainIndexingActionProvider = StateNotifierProvider<DomainIndexingNotifier, DomainIndexingState>((ref) {
  return DomainIndexingNotifier(ref);
});

/// State for domain indexing progress
class DomainIndexingState {
  final bool isIndexing;
  final int current;
  final int total;
  final String? error;

  const DomainIndexingState({
    this.isIndexing = false,
    this.current = 0,
    this.total = 0,
    this.error,
  });

  DomainIndexingState copyWith({
    bool? isIndexing,
    int? current,
    int? total,
    String? error,
  }) {
    return DomainIndexingState(
      isIndexing: isIndexing ?? this.isIndexing,
      current: current ?? this.current,
      total: total ?? this.total,
      error: error ?? this.error,
    );
  }

  double get progress => total > 0 ? current / total : 0.0;
}

/// Notifier for domain indexing actions
class DomainIndexingNotifier extends StateNotifier<DomainIndexingState> {
  final Ref _ref;

  DomainIndexingNotifier(this._ref) : super(const DomainIndexingState());

  /// Trigger domain data re-indexing
  Future<void> rebuildIndex() async {
    if (state.isIndexing) return;

    state = state.copyWith(isIndexing: true, current: 0, total: 0, error: null);

    try {
      final ragPipeline = await _ref.read(ragPipelineProvider.future);
      
      await ragPipeline.rebuildEmbeddings(
        onProgress: (current, total) {
          state = state.copyWith(current: current, total: total);
        },
      );

      state = state.copyWith(isIndexing: false);
      _logger.info('Domain indexing completed successfully');
    } catch (e) {
      state = state.copyWith(isIndexing: false, error: e.toString());
                _logger.warning('Domain indexing failed: $e');
    }
  }
}

// Dummy embedding service for fallback
class _DummyEmbeddingService implements EmbeddingService {
  @override
  Future<List<List<double>>> embed(List<String> texts, {EmbeddingProgressCallback? onProgress}) async {
    // Return zero vectors with consistent dimensions
    // Use 768 for Ollama/nomic-embed-text
    // Since we use ollamaFirst strategy, default to 768
    const defaultDimensions = 768;
    
    // Report progress for dummy service
    for (int i = 0; i < texts.length; i++) {
      onProgress?.call(i + 1, texts.length, 'Generating dummy embedding ${i + 1}/${texts.length}');
    }
    
    return List.generate(texts.length, (_) => List.filled(defaultDimensions, 0.0));
  }
}
