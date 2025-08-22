import 'package:meta/meta.dart';
import '../query/query_context.dart';
import '../query/query_planner.dart';
import '../rag/rag_pipeline.dart';
import '../advice/advice_engine.dart';

/// Main request routing interface that determines the best processing path
/// for user requests (calculation/aggregation vs retrieval/generation)
abstract class RequestRouter {
  /// Route a user request to the most appropriate processing path
  Future<RequestRouting> routeRequest(String query);

  /// Analyze query complexity and determine processing strategy
  ProcessingStrategy determineProcessingStrategy(String query);

  /// Check if query requires calculation/aggregation capabilities
  bool requiresCalculation(String query);

  /// Check if query requires retrieval/generation capabilities
  bool requiresGeneration(String query);
}

/// Routing result that defines how to process the request
@immutable
class RequestRouting {
  const RequestRouting({
    required this.originalQuery,
    required this.strategy,
    required this.processingPath,
    required this.queryContext,
    required this.confidence,
    this.calculationSpecs,
    this.retrievalSpecs,
    this.hybrid = false,
  });

  final String originalQuery;
  final ProcessingStrategy strategy;
  final ProcessingPath processingPath;
  final QueryContext queryContext;
  final double confidence;
  final CalculationSpecs? calculationSpecs;
  final RetrievalSpecs? retrievalSpecs;
  final bool hybrid; // Whether this requires both calculation and generation

  /// Whether this query requires calculation/aggregation
  bool get needsCalculation => processingPath == ProcessingPath.calculation || hybrid;

  /// Whether this query requires retrieval/generation
  bool get needsGeneration => processingPath == ProcessingPath.retrieval || hybrid;

  /// Whether this is a complex query requiring multiple processing steps
  bool get isComplex => hybrid || strategy == ProcessingStrategy.multiStep;
}

/// Processing strategies for different query types
enum ProcessingStrategy {
  direct,       // Simple, single-step processing
  calculation,  // Focus on aggregation/filtering
  retrieval,    // Focus on search/generation
  multiStep,    // Complex multi-step processing
  hybrid,       // Requires both calculation and generation
}

/// Primary processing paths
enum ProcessingPath {
  calculation,  // Aggregation, filtering, mathematical operations
  retrieval,    // Semantic search, context retrieval, generation
  hybrid,       // Both calculation and retrieval needed
}

/// Specifications for calculation-focused processing
@immutable
class CalculationSpecs {
  const CalculationSpecs({
    required this.operations,
    required this.aggregations,
    required this.filters,
    this.timeRange,
    this.groupBy,
    this.sortBy,
  });

  final List<CalculationOperation> operations;
  final List<AggregationType> aggregations;
  final Map<String, dynamic> filters;
  final TimeRange? timeRange;
  final List<String>? groupBy;
  final String? sortBy;
}

/// Specifications for retrieval-focused processing
@immutable
class RetrievalSpecs {
  const RetrievalSpecs({
    required this.searchTerms,
    required this.contextNeeds,
    required this.generationType,
    this.domainFocus,
    this.semanticWeight = 0.7,
    this.keywordWeight = 0.3,
  });

  final List<String> searchTerms;
  final ContextNeeds contextNeeds;
  final GenerationType generationType;
  final List<String>? domainFocus;
  final double semanticWeight;
  final double keywordWeight;
}

/// Types of calculations needed
enum CalculationOperation {
  sum, average, count, max, min, median, 
  trend, correlation, percentage, ratio, 
  grouping, filtering, ranking
}

/// Types of aggregations
enum AggregationType {
  sum, count, average, max, min, 
  groupBy, distinctCount, 
  timeSeriesSum, timeSeriesAverage
}

/// Types of context needed for generation
enum ContextNeeds {
  minimal,     // Basic facts and figures
  moderate,    // Some background context
  extensive,   // Rich contextual information
  historical,  // Historical patterns and trends
  comparative, // Comparison across time/categories
}

/// Types of generation output
enum GenerationType {
  factual,     // Straightforward information retrieval
  analytical,  // Pattern analysis and insights
  advisory,    // Recommendations and advice
  narrative,   // Story-like explanations
  summary,     // Condensed overviews
}

/// Default implementation of request router
class DefaultRequestRouter implements RequestRouter {
  const DefaultRequestRouter({
    required QueryPlanner queryPlanner,
    required RagPipeline ragPipeline,
    required AdviceEngine adviceEngine,
  }) : _queryPlanner = queryPlanner,
       _ragPipeline = ragPipeline,
       _adviceEngine = adviceEngine;

  final QueryPlanner _queryPlanner;
  final RagPipeline _ragPipeline;
  final AdviceEngine _adviceEngine;

  @override
  Future<RequestRouting> routeRequest(String query) async {
    // Step 1: Plan the query to understand its structure
    final queryContext = _queryPlanner.planQuery(query);
    
    // Step 2: Determine processing strategy
    final strategy = determineProcessingStrategy(query);
    
    // Step 3: Analyze calculation vs generation needs
    final needsCalc = requiresCalculation(query);
    final needsGen = requiresGeneration(query);
    
    // Step 4: Determine primary processing path
    ProcessingPath processingPath;
    bool hybrid = false;
    
    if (needsCalc && needsGen) {
      processingPath = ProcessingPath.hybrid;
      hybrid = true;
    } else if (needsCalc) {
      processingPath = ProcessingPath.calculation;
    } else {
      processingPath = ProcessingPath.retrieval;
    }
    
    // Step 5: Generate specifications
    final calcSpecs = needsCalc ? _generateCalculationSpecs(query, queryContext) : null;
    final retrievalSpecs = needsGen ? _generateRetrievalSpecs(query, queryContext) : null;
    
    // Step 6: Calculate confidence
    final confidence = _calculateRoutingConfidence(query, queryContext, strategy);
    
    return RequestRouting(
      originalQuery: query,
      strategy: strategy,
      processingPath: processingPath,
      queryContext: queryContext,
      confidence: confidence,
      calculationSpecs: calcSpecs,
      retrievalSpecs: retrievalSpecs,
      hybrid: hybrid,
    );
  }

  @override
  ProcessingStrategy determineProcessingStrategy(String query) {
    final queryLower = query.toLowerCase();
    
    // Multi-step indicators
    final multiStepKeywords = [
      'compare and analyze', 'show me trend and explain', 'calculate then suggest',
      'analyze pattern and recommend', 'break down and advise', 'summary with insights'
    ];
    
    if (multiStepKeywords.any((kw) => queryLower.contains(kw))) {
      return ProcessingStrategy.multiStep;
    }
    
    // Hybrid processing indicators (calculation + generation)
    final hybridPatterns = [
      'how much.*spent.*and.*suggest', 'total.*and.*recommend',
      'average.*and.*advice', 'analyze.*spending.*pattern',
      'show.*trend.*and.*explain', 'calculate.*and.*why'
    ];
    
    for (final pattern in hybridPatterns) {
      if (RegExp(pattern).hasMatch(queryLower)) {
        return ProcessingStrategy.hybrid;
      }
    }
    
    // Calculation-focused indicators
    if (_hasCalculationKeywords(queryLower)) {
      return ProcessingStrategy.calculation;
    }
    
    // Retrieval-focused indicators
    if (_hasRetrievalKeywords(queryLower)) {
      return ProcessingStrategy.retrieval;
    }
    
    // Default to direct processing
    return ProcessingStrategy.direct;
  }

  @override
  bool requiresCalculation(String query) {
    final queryLower = query.toLowerCase();
    
    // Mathematical operation keywords
    final mathKeywords = [
      'total', 'sum', 'average', 'mean', 'count', 'number of',
      'maximum', 'max', 'minimum', 'min', 'highest', 'lowest',
      'percentage', 'percent', '%', 'ratio', 'proportion',
      'calculate', 'compute', 'add up', 'how much', 'how many'
    ];
    
    // Aggregation keywords
    final aggregationKeywords = [
      'group by', 'categorize', 'breakdown', 'distribute',
      'per day', 'per week', 'per month', 'daily', 'weekly', 'monthly',
      'each', 'every', 'all', 'sort', 'rank', 'top', 'bottom'
    ];
    
    // Statistical keywords
    final statisticalKeywords = [
      'trend', 'pattern', 'growth', 'increase', 'decrease',
      'correlation', 'relationship', 'compare', 'comparison',
      'statistics', 'stats', 'analysis', 'analyze'
    ];
    
    final allCalcKeywords = [...mathKeywords, ...aggregationKeywords, ...statisticalKeywords];
    
    return allCalcKeywords.any((kw) => queryLower.contains(kw));
  }

  @override
  bool requiresGeneration(String query) {
    final queryLower = query.toLowerCase();
    
    // Question words requiring narrative response
    final questionWords = [
      'why', 'how', 'what if', 'explain', 'describe', 'tell me about',
      'what does it mean', 'what happened', 'can you help'
    ];
    
    // Advice/recommendation keywords
    final adviceKeywords = [
      'suggest', 'recommend', 'advice', 'should i', 'what should',
      'how can i', 'help me', 'improve', 'optimize', 'better'
    ];
    
    // Narrative/explanation keywords
    final narrativeKeywords = [
      'story', 'journey', 'experience', 'background', 'context',
      'details', 'elaborate', 'expand', 'overview', 'summary'
    ];
    
    final allGenKeywords = [...questionWords, ...adviceKeywords, ...narrativeKeywords];
    
    return allGenKeywords.any((kw) => queryLower.contains(kw));
  }

  /// Generate calculation specifications based on query analysis
  CalculationSpecs _generateCalculationSpecs(String query, QueryContext context) {
    final queryLower = query.toLowerCase();
    final operations = <CalculationOperation>[];
    final aggregations = <AggregationType>[];
    
    // Identify operations needed
    if (queryLower.contains('total') || queryLower.contains('sum') || 
        queryLower.contains('how much') || queryLower.contains('spend') ||
        queryLower.contains('spent') || queryLower.contains('cost') ||
        queryLower.contains('expense') || queryLower.contains('paid')) {
      operations.add(CalculationOperation.sum);
      aggregations.add(AggregationType.sum);
    }
    
    if (queryLower.contains('average') || queryLower.contains('mean')) {
      operations.add(CalculationOperation.average);
      aggregations.add(AggregationType.average);
    }
    
    if (queryLower.contains('count') || queryLower.contains('number')) {
      operations.add(CalculationOperation.count);
      aggregations.add(AggregationType.count);
    }
    
    if (queryLower.contains('trend') || queryLower.contains('pattern')) {
      operations.add(CalculationOperation.trend);
      aggregations.add(AggregationType.timeSeriesAverage);
    }
    
    if (queryLower.contains('group') || queryLower.contains('categorize')) {
      operations.add(CalculationOperation.grouping);
      aggregations.add(AggregationType.groupBy);
    }
    
    // Extract grouping criteria
    List<String>? groupBy;
    if (queryLower.contains('by category')) groupBy = ['category'];
    if (queryLower.contains('by day')) groupBy = ['day'];
    if (queryLower.contains('by month')) groupBy = ['month'];
    
    return CalculationSpecs(
      operations: operations,
      aggregations: aggregations,
      filters: context.filters,
      timeRange: context.timeRange,
      groupBy: groupBy,
    );
  }

  /// Generate retrieval specifications based on query analysis
  RetrievalSpecs _generateRetrievalSpecs(String query, QueryContext context) {
    final queryLower = query.toLowerCase();
    
    // Determine context needs
    ContextNeeds contextNeeds;
    if (queryLower.contains('detail') || queryLower.contains('comprehensive')) {
      contextNeeds = ContextNeeds.extensive;
    } else if (queryLower.contains('compare') || queryLower.contains('vs')) {
      contextNeeds = ContextNeeds.comparative;
    } else if (queryLower.contains('history') || queryLower.contains('over time')) {
      contextNeeds = ContextNeeds.historical;
    } else if (queryLower.contains('summary') || queryLower.contains('brief')) {
      contextNeeds = ContextNeeds.minimal;
    } else {
      contextNeeds = ContextNeeds.moderate;
    }
    
    // Determine generation type
    GenerationType generationType;
    if (queryLower.contains('recommend') || queryLower.contains('suggest')) {
      generationType = GenerationType.advisory;
    } else if (queryLower.contains('analyze') || queryLower.contains('pattern')) {
      generationType = GenerationType.analytical;
    } else if (queryLower.contains('story') || queryLower.contains('journey')) {
      generationType = GenerationType.narrative;
    } else if (queryLower.contains('summary') || queryLower.contains('overview')) {
      generationType = GenerationType.summary;
    } else {
      generationType = GenerationType.factual;
    }
    
    return RetrievalSpecs(
      searchTerms: context.keywords,
      contextNeeds: contextNeeds,
      generationType: generationType,
      domainFocus: context.targetDomains,
    );
  }

  /// Calculate confidence in routing decision
  double _calculateRoutingConfidence(String query, QueryContext context, ProcessingStrategy strategy) {
    double confidence = 0.5; // Base confidence
    
    // Higher confidence for clear intent
    if (context.intent != QueryIntent.search) confidence += 0.2;
    
    // Higher confidence for specific domains
    if (context.targetDomains.length <= 3 && context.targetDomains.isNotEmpty) confidence += 0.1;
    
    // Higher confidence for clear time ranges
    if (context.timeRange != null) confidence += 0.1;
    
    // Higher confidence for strategy alignment
    if (strategy == ProcessingStrategy.direct) confidence += 0.1;
    
    return confidence.clamp(0.0, 1.0);
  }

  /// Check if query has calculation-focused keywords
  bool _hasCalculationKeywords(String query) {
    final calcKeywords = [
      'calculate', 'compute', 'total', 'sum', 'average', 'count',
      'statistics', 'breakdown', 'analyze spending', 'how much'
    ];
    return calcKeywords.any((kw) => query.toLowerCase().contains(kw));
  }

  /// Check if query has retrieval-focused keywords
  bool _hasRetrievalKeywords(String query) {
    final retrievalKeywords = [
      'tell me', 'explain', 'describe', 'what happened', 'story',
      'recommend', 'suggest', 'advice', 'why', 'how can'
    ];
    return retrievalKeywords.any((kw) => query.toLowerCase().contains(kw));
  }
}
