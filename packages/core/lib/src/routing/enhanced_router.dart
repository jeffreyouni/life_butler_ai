import 'package:meta/meta.dart';
import '../query/query_context.dart';
import '../query/query_planner.dart';
import '../rag/rag_pipeline.dart';
import '../advice/advice_engine.dart';
import '../utils/logger.dart';
import 'request_router.dart';

/// Weighted keyword for enhanced rule-based classification
class WeightedKeyword {
  final String keyword;
  final double weight;
  final List<String> domains;

  const WeightedKeyword(this.keyword, this.weight, this.domains);
}

/// Information about mixed query detection
class MixedQueryInfo {
  final bool isMixed;
  final double calculationStrength;
  final double retrievalStrength;

  const MixedQueryInfo({
    required this.isMixed,
    required this.calculationStrength,
    required this.retrievalStrength,
  });
}

/// Enhanced rule classification result with language detection
class RuleClassificationResult {
  final Map<IntentType, double> scores;
  final bool hasHighConfidenceMatch;
  final bool mixedQueryDetected;
  final String detectedLanguage;
  final List<String> queryVariants;

  const RuleClassificationResult({
    required this.scores,
    required this.hasHighConfidenceMatch,
    this.mixedQueryDetected = false,
    this.detectedLanguage = 'en',
    this.queryVariants = const [],
  });

  @override
  String toString() {
    return 'RuleResult(scores: $scores, highConfidence: $hasHighConfidenceMatch, '
           'mixed: $mixedQueryDetected, lang: $detectedLanguage)';
  }
}

/// Enhanced three-stage routing system for robust intent classification
class EnhancedRequestRouter implements RequestRouter {
  final QueryPlanner _queryPlanner;
  final RagPipeline _ragPipeline;
  final AdviceEngine _adviceEngine;
  final _ruleBasedClassifier = RuleBasedClassifier();
  final _semanticClassifier = SemanticClassifier();
  final _llmClassifier = LLMClassifier();
  
  static final _logger = Logger('EnhancedRouter');

  EnhancedRequestRouter({
    required QueryPlanner queryPlanner,
    required RagPipeline ragPipeline,
    required AdviceEngine adviceEngine,
  }) : _queryPlanner = queryPlanner,
       _ragPipeline = ragPipeline,
       _adviceEngine = adviceEngine;

  @override
  Future<RequestRouting> routeRequest(String query) async {
    _logger.debug('Enhanced router processing: "$query"');
    final queryContext = _queryPlanner.planQuery(query);
    
    // Stage 1: Rule-based classification (fast, high precision)
    final ruleResult = await _ruleBasedClassifier.classify(query);
    
    // Stage 2: Semantic prototype similarity
    final semanticResult = await _semanticClassifier.classify(query);
    
    // Stage 3: LLM function calling (when needed)
    LLMClassificationResult? llmResult;
    if (!ruleResult.hasHighConfidenceMatch && !semanticResult.meetsThreshold) {
      _logger.debug('Falling back to LLM classification...');
      llmResult = await _llmClassifier.classify(query, queryContext);
    }

    // Enhanced weighted decision with mixed query support
    final decision = _makeWeightedDecision(
      query: query,
      queryContext: queryContext,
      ruleResult: ruleResult,
      semanticResult: semanticResult,
      llmResult: llmResult,
    );

    // Enhanced logging for generation queries
    _logRoutingDecision(query, decision, ruleResult, semanticResult, llmResult);
    
    return _buildRouting(query, queryContext, decision);
  }

  void _logRoutingDecision(
    String query, 
    RoutingDecision decision,
    RuleClassificationResult ruleResult,
    SemanticClassificationResult semanticResult,
    LLMClassificationResult? llmResult,
  ) {
    _logger.debug('Final routing decision: ${decision.primaryIntent} (confidence: ${decision.confidence.toStringAsFixed(3)})');
    _logger.debug('Mixed query: ${decision.isMixedQuery}');
    _logger.debug('Hybrid mode: ${decision.hybrid}');
    _logger.debug('Language: ${ruleResult.detectedLanguage}');
    if (ruleResult.queryVariants.length > 1) {
      _logger.debug('Query variants: ${ruleResult.queryVariants}');
    }
    
    // Log rule hits
    final ruleHits = <String>[];
    ruleResult.scores.forEach((intent, score) {
      if (score > 0) {
        ruleHits.add('${intent.name}:${score.toStringAsFixed(2)}');
      }
    });
    _logger.info('   Rule hits: ${ruleHits.join(', ')}');
    
    // Log semantic scores
    final semanticHits = <String>[];
    semanticResult.scores.forEach((intent, score) {
      if (score > 0) {
        semanticHits.add('${intent.name}:${score.toStringAsFixed(2)}');
      }
    });
    _logger.info('   Semantic scores: ${semanticHits.join(', ')}');
  }

  @override
  ProcessingStrategy determineProcessingStrategy(String query) {
    // This will be determined by the enhanced routing logic
    return ProcessingStrategy.hybrid;
  }

  @override
  bool requiresCalculation(String query) {
    return _ruleBasedClassifier.hasCalculationKeywords(query);
  }

  @override
  bool requiresGeneration(String query) {
    return _ruleBasedClassifier.hasGenerationKeywords(query);
  }

  RoutingDecision _makeWeightedDecision({
    required String query,
    required QueryContext queryContext,
    required RuleClassificationResult ruleResult,
    required SemanticClassificationResult semanticResult,
    LLMClassificationResult? llmResult,
  }) {
    const weights = RoutingWeights(
      rule: 0.4,
      semantic: 0.3,
      llm: 0.3,
      dataMissing: 0.2,
    );

    _logger.debug('📊 Computing weighted decision...');
    final scores = <IntentType, double>{};
    
    // Rule-based scores
    for (final entry in ruleResult.scores.entries) {
      scores[entry.key] = (scores[entry.key] ?? 0.0) + weights.rule * entry.value;
      _logger.info('   Rule ${entry.key}: ${entry.value.toStringAsFixed(3)} -> ${scores[entry.key]!.toStringAsFixed(3)}');
    }
    
    // Semantic scores
    for (final entry in semanticResult.scores.entries) {
      scores[entry.key] = (scores[entry.key] ?? 0.0) + weights.semantic * entry.value;
      _logger.info('   Semantic ${entry.key}: ${entry.value.toStringAsFixed(3)} -> ${scores[entry.key]!.toStringAsFixed(3)}');
    }
    
    // LLM scores
    if (llmResult != null) {
      scores[llmResult.intent] = (scores[llmResult.intent] ?? 0.0) + weights.llm * llmResult.confidence;
      _logger.info('   LLM ${llmResult.intent}: ${llmResult.confidence.toStringAsFixed(3)} -> ${scores[llmResult.intent]!.toStringAsFixed(3)}');
    }
    
    // Enhanced mixed query detection
    final isMixedQuery = ruleResult.mixedQueryDetected || 
                         _detectMixedFromScores(scores, ruleResult, semanticResult);
    
    // Data availability penalty
    final dataMissingPenalty = _calculateDataMissingPenalty(queryContext);
    for (final entry in scores.entries.toList()) {
      if (_requiresData(entry.key)) {
        final newScore = entry.value - weights.dataMissing * dataMissingPenalty;
        scores[entry.key] = newScore;
        if (dataMissingPenalty > 0) {
          _logger.info('   Data penalty for ${entry.key}: ${entry.value.toStringAsFixed(3)} -> ${newScore.toStringAsFixed(3)}');
        }
      }
    }
    
    // Find best intent with semantic fallback
    final sortedScores = scores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    IntentType primaryIntent;
    double primaryScore;
    
    if (sortedScores.isNotEmpty) {
      primaryIntent = sortedScores.first.key;
      primaryScore = sortedScores.first.value;
    } else {
      // Semantic fallback when no rule matches
      if (semanticResult.meetsThreshold) {
        final topSemantic = semanticResult.scores.entries
            .reduce((a, b) => a.value > b.value ? a : b);
        primaryIntent = topSemantic.key;
        primaryScore = topSemantic.value;
        _logger.info('   🔄 Applied semantic fallback: ${primaryIntent} (${primaryScore.toStringAsFixed(3)})');
      } else {
        primaryIntent = IntentType.retrieval;
        primaryScore = 0.3; // Low confidence fallback
        _logger.info('   🔄 Applied default fallback: ${primaryIntent}');
      }
    }
    
    // Enhanced hybrid detection
    final aggScore = scores[IntentType.aggregate] ?? 0.0;
    final retScore = scores[IntentType.retrieval] ?? 0.0;
    final hybridThreshold = 0.5;
    
    final shouldUseHybrid = isMixedQuery || 
                           (aggScore > hybridThreshold && retScore > hybridThreshold);
    
    _logger.info('   Mixed query detected: $isMixedQuery');
    _logger.info('   Hybrid recommended: $shouldUseHybrid (agg: ${aggScore.toStringAsFixed(3)}, ret: ${retScore.toStringAsFixed(3)})');
    
    return RoutingDecision(
      primaryIntent: primaryIntent,
      confidence: primaryScore,
      hybrid: shouldUseHybrid,
      ruleResult: ruleResult,
      semanticResult: semanticResult,
      llmResult: llmResult,
      isMixedQuery: isMixedQuery,
    );
  }

  bool _detectMixedFromScores(
    Map<IntentType, double> scores,
    RuleClassificationResult ruleResult,
    SemanticClassificationResult semanticResult,
  ) {
    final aggScore = scores[IntentType.aggregate] ?? 0.0;
    final retScore = scores[IntentType.retrieval] ?? 0.0;
    
    // Consider mixed if both calculation and retrieval have reasonable scores
    return aggScore > 0.3 && retScore > 0.3;
  }

  RequestRouting _buildRouting(String query, QueryContext queryContext, RoutingDecision decision) {
    ProcessingPath path;
    ProcessingStrategy strategy;
    CalculationSpecs? calcSpecs;
    RetrievalSpecs? retrievalSpecs;

    if (decision.hybrid) {
      path = ProcessingPath.hybrid;
      strategy = ProcessingStrategy.hybrid;
      calcSpecs = _generateCalculationSpecs(query, queryContext);
      retrievalSpecs = _generateRetrievalSpecs(query, queryContext);
    } else {
      switch (decision.primaryIntent) {
        case IntentType.aggregate:
          path = ProcessingPath.calculation;
          strategy = ProcessingStrategy.calculation;
          calcSpecs = _generateCalculationSpecs(query, queryContext);
          break;
        case IntentType.retrieval:
          path = ProcessingPath.retrieval;
          strategy = ProcessingStrategy.retrieval;
          retrievalSpecs = _generateRetrievalSpecs(query, queryContext);
          break;
        case IntentType.reminder:
          path = ProcessingPath.retrieval;  // Use retrieval for reminders
          strategy = ProcessingStrategy.direct;
          retrievalSpecs = _generateRetrievalSpecs(query, queryContext);
          break;
      }
    }

    return RequestRouting(
      originalQuery: query,
      strategy: strategy,
      processingPath: path,
      queryContext: queryContext,
      confidence: decision.confidence,
      calculationSpecs: calcSpecs,
      retrievalSpecs: retrievalSpecs,
      hybrid: decision.hybrid,
    );
  }

  double _calculateDataMissingPenalty(QueryContext context) {
    // Check if required data sources are available
    double penalty = 0.0;
    
    // Check if financial data is needed but missing
    if (context.targetDomains.contains('finance_records')) {
      // In a real implementation, check if finance database has data
      penalty += 0.1; // Mock penalty for missing financial data
    }
    
    return penalty.clamp(0.0, 1.0);
  }

  bool _requiresData(IntentType intent) {
    return intent == IntentType.aggregate || intent == IntentType.retrieval;
  }

  bool _isComplexSentence(String query) {
    // Check for complex sentence patterns that might require hybrid processing
    final complexPatterns = [
      RegExp(r'and.*suggest|and.*recommend', caseSensitive: false),
      RegExp(r'show.*and.*explain', caseSensitive: false),
      RegExp(r'calculate.*and.*why', caseSensitive: false),
      RegExp(r'total.*and.*advice', caseSensitive: false),
    ];
    
    return complexPatterns.any((pattern) => pattern.hasMatch(query)) || 
           query.split(' ').length > 8; // Long sentences are often complex
  }

  // Implement spec generation methods (reuse existing logic)
  CalculationSpecs _generateCalculationSpecs(String query, QueryContext context) {
    // Reuse existing implementation from DefaultRequestRouter
    final queryLower = query.toLowerCase();
    final operations = <CalculationOperation>[];
    final aggregations = <AggregationType>[];
    
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
    
    return CalculationSpecs(
      operations: operations,
      aggregations: aggregations,
      filters: context.filters,
      timeRange: context.timeRange,
      groupBy: null,
    );
  }

  RetrievalSpecs _generateRetrievalSpecs(String query, QueryContext context) {
    // Determine generation type based on query characteristics
    GenerationType generationType;
    
    if (context.intent == QueryIntent.advice) {
      generationType = GenerationType.advisory;
    } else if (_isExplanatoryQuery(query)) {
      // Use narrative for "why", "how", explanatory questions
      generationType = GenerationType.narrative;
    } else {
      generationType = GenerationType.factual;
    }
    
    return RetrievalSpecs(
      searchTerms: context.keywords,
      contextNeeds: context.intent == QueryIntent.advice ? ContextNeeds.extensive : ContextNeeds.moderate,
      generationType: generationType,
      domainFocus: context.targetDomains,
    );
  }
  
  /// Check if the query is asking for an explanation
  bool _isExplanatoryQuery(String query) {
    final lowercaseQuery = query.toLowerCase();
    final explanatoryPatterns = [
      'why am i',
      'why do i',
      'why is',
      'how am i',
      'how do i',
      'what is causing',
      'what makes',
      'explain why',
      'tell me why',
    ];
    
    return explanatoryPatterns.any((pattern) => lowercaseQuery.contains(pattern));
  }
}

/// Stage 1: Rule-based classifier with multilingual support
class RuleBasedClassifier {
  static final _logger = Logger('RuleBasedClassifier');
  
  // Enhanced multilingual rule mappings with comprehensive domain coverage
  static final _aggregationRules = <String, List<WeightedKeyword>>{
    // Chinese patterns
    'aggregate_cn': [
      WeightedKeyword('总计', 2.0, ['finance', 'general']),
      WeightedKeyword('总额', 2.0, ['finance']),
      WeightedKeyword('总共', 1.8, ['general']),
      WeightedKeyword('一共', 1.8, ['general']),
      WeightedKeyword('合计', 2.0, ['finance']),
      WeightedKeyword('平均', 2.0, ['health', 'finance', 'general']),
      WeightedKeyword('均值', 1.8, ['health', 'finance']),
      WeightedKeyword('平均数', 1.8, ['general']),
      WeightedKeyword('数量', 1.5, ['general']),
      WeightedKeyword('个数', 1.5, ['general']),
      WeightedKeyword('多少个', 1.8, ['general']),
      WeightedKeyword('多少钱', 2.0, ['finance']),
      WeightedKeyword('花了多少', 2.0, ['finance']),
      WeightedKeyword('消费', 1.8, ['finance']),
      WeightedKeyword('支出', 2.0, ['finance']),
      WeightedKeyword('收入', 2.0, ['finance']),
      WeightedKeyword('最大', 1.5, ['general']),
      WeightedKeyword('最小', 1.5, ['general']),
      WeightedKeyword('最高', 1.8, ['health', 'finance']),
      WeightedKeyword('最低', 1.8, ['health', 'finance']),
      WeightedKeyword('卡路里', 2.0, ['meals', 'health']),
      WeightedKeyword('体重', 2.0, ['health']),
      WeightedKeyword('睡眠时间', 2.0, ['health']),
      WeightedKeyword('锻炼时间', 2.0, ['health']),
      // Enhanced mixed-query patterns
      WeightedKeyword('吃饭花', 2.5, ['meals', 'finance']),
      WeightedKeyword('本月', 1.5, ['general']),
      WeightedKeyword('这个月', 1.5, ['general']),
      WeightedKeyword('这月', 1.5, ['general']),
      WeightedKeyword('今年', 1.5, ['general']),
      WeightedKeyword('统计', 2.0, ['general']),
      WeightedKeyword('计算', 2.0, ['general']),
      WeightedKeyword('多少', 2.5, ['finance', 'general']),
    ],
    // English patterns
    'aggregate_en': [
      WeightedKeyword('total', 2.0, ['finance', 'general']),
      WeightedKeyword('sum', 2.0, ['finance', 'general']),
      WeightedKeyword('amount', 2.0, ['finance']),
      WeightedKeyword('altogether', 1.5, ['general']),
      WeightedKeyword('average', 2.0, ['health', 'finance', 'general']),
      WeightedKeyword('mean', 1.8, ['general']),
      WeightedKeyword('avg', 1.8, ['general']),
      WeightedKeyword('count', 1.5, ['general']),
      WeightedKeyword('number of', 1.8, ['general']),
      WeightedKeyword('how many', 1.8, ['general']),
      WeightedKeyword('how much', 2.0, ['finance']),
      WeightedKeyword('spend', 2.0, ['finance']),
      WeightedKeyword('spent', 2.0, ['finance']),
      WeightedKeyword('cost', 2.0, ['finance']),
      WeightedKeyword('expense', 2.0, ['finance']),
      WeightedKeyword('paid', 1.8, ['finance']),
      WeightedKeyword('income', 2.0, ['finance']),
      WeightedKeyword('revenue', 1.8, ['finance']),
      WeightedKeyword('maximum', 1.5, ['general']),
      WeightedKeyword('minimum', 1.5, ['general']),
      WeightedKeyword('highest', 1.8, ['health', 'finance']),
      WeightedKeyword('lowest', 1.8, ['health', 'finance']),
      WeightedKeyword('max', 1.5, ['general']),
      WeightedKeyword('min', 1.5, ['general']),
      WeightedKeyword('calories', 2.0, ['meals', 'health']),
      WeightedKeyword('weight', 2.0, ['health']),
      WeightedKeyword('sleep', 2.0, ['health']),
      WeightedKeyword('exercise', 2.0, ['health']),
      // Enhanced time-range keywords
      WeightedKeyword('this month', 1.5, ['general']),
      WeightedKeyword('monthly', 1.5, ['general']),
      WeightedKeyword('this year', 1.5, ['general']),
      WeightedKeyword('yearly', 1.5, ['general']),
      WeightedKeyword('calculate', 2.0, ['general']),
      WeightedKeyword('compute', 2.0, ['general']),
    ],
  };

  static final _retrievalRules = <String, List<WeightedKeyword>>{
    // Chinese patterns
    'retrieval_cn': [
      WeightedKeyword('告诉我', 1.5, ['general']),
      WeightedKeyword('解释', 2.0, ['general']),
      WeightedKeyword('说明', 1.8, ['general']),
      WeightedKeyword('描述', 1.8, ['general']),
      WeightedKeyword('建议', 2.0, ['general']),
      WeightedKeyword('推荐', 2.0, ['general']),
      WeightedKeyword('怎么办', 2.0, ['general']),
      WeightedKeyword('如何', 2.0, ['general']),
      WeightedKeyword('为什么', 2.5, ['general']),
      WeightedKeyword('原因', 2.0, ['general']),
      WeightedKeyword('分析', 2.5, ['general']),
      WeightedKeyword('历史', 1.5, ['general']),
      WeightedKeyword('记录', 1.5, ['general']),
      WeightedKeyword('发生了什么', 1.8, ['general']),
      WeightedKeyword('改进', 2.0, ['general']),
      WeightedKeyword('优化', 2.0, ['general']),
      WeightedKeyword('提高', 1.8, ['general']),
      WeightedKeyword('心情', 1.8, ['journals', 'health']),
      WeightedKeyword('情绪', 2.0, ['journals', 'health']),
      WeightedKeyword('感觉', 1.5, ['journals', 'health']),
      WeightedKeyword('健康', 2.0, ['health']),
      WeightedKeyword('饮食', 2.0, ['meals', 'health']),
      WeightedKeyword('吃饭', 2.0, ['meals']),
      WeightedKeyword('餐', 1.8, ['meals']),
      WeightedKeyword('学习', 2.0, ['education']),
      WeightedKeyword('工作', 2.0, ['career']),
      WeightedKeyword('睡眠', 2.0, ['health']),
      WeightedKeyword('锻炼', 2.0, ['health']),
      WeightedKeyword('财务', 2.0, ['finance']),
      WeightedKeyword('日记', 2.0, ['journals']),
    ],
    // English patterns
    'retrieval_en': [
      WeightedKeyword('tell me', 1.5, ['general']),
      WeightedKeyword('explain', 2.0, ['general']),
      WeightedKeyword('describe', 1.8, ['general']),
      WeightedKeyword('show me', 1.5, ['general']),
      WeightedKeyword('recommend', 2.0, ['general']),
      WeightedKeyword('suggest', 2.0, ['general']),
      WeightedKeyword('advice', 2.0, ['general']),
      WeightedKeyword('help', 1.5, ['general']),
      WeightedKeyword('why', 2.5, ['general']),
      WeightedKeyword('reason', 2.0, ['general']),
      WeightedKeyword('analyze', 2.5, ['general']),
      WeightedKeyword('analysis', 2.5, ['general']),
      WeightedKeyword('history', 1.5, ['general']),
      WeightedKeyword('record', 1.5, ['general']),
      WeightedKeyword('what happened', 1.8, ['general']),
      WeightedKeyword('story', 1.5, ['general']),
      WeightedKeyword('improve', 2.0, ['general']),
      WeightedKeyword('optimize', 2.0, ['general']),
      WeightedKeyword('enhance', 1.8, ['general']),
      WeightedKeyword('mood', 2.0, ['journals', 'health']),
      WeightedKeyword('feeling', 1.8, ['journals', 'health']),
      WeightedKeyword('emotion', 2.0, ['journals', 'health']),
      WeightedKeyword('health', 2.0, ['health']),
      WeightedKeyword('diet', 2.0, ['meals', 'health']),
      WeightedKeyword('food', 2.0, ['meals']),
      WeightedKeyword('meal', 2.0, ['meals']),
      WeightedKeyword('eating', 1.8, ['meals']),
      WeightedKeyword('study', 2.0, ['education']),
      WeightedKeyword('work', 2.0, ['career']),
      WeightedKeyword('finance', 2.0, ['finance']),
      WeightedKeyword('sleep', 2.0, ['health']),
      WeightedKeyword('exercise', 2.0, ['health']),
      WeightedKeyword('journal', 2.0, ['journals']),
      WeightedKeyword('diary', 2.0, ['journals']),
    ],
  };

  static final _reminderRules = <String, List<String>>{
    // Chinese patterns
    'reminder_cn': [
      '提醒', '闹钟', '定时', '计划',
      '每天', '每周', '每月', '定期',
      '重复', '循环', '周期性',
    ],
    // English patterns
    'reminder_en': [
      'remind', 'reminder', 'alarm', 'schedule',
      'every day', 'daily', 'weekly', 'monthly',
      'repeat', 'recurring', 'periodic', 'rrule',
    ],
  };

  Future<RuleClassificationResult> classify(String query) async {
    final queryLower = query.toLowerCase();
    final scores = <IntentType, double>{};
    final detectedLanguage = _detectLanguage(query);
    final queryVariants = _generateQueryVariants(query, detectedLanguage);
    
    _logger.debug('🔍 Rule-based classification for: "$query"');
    _logger.info('   Detected language: $detectedLanguage');
    _logger.info('   Query variants: $queryVariants');
    
    // Check aggregation rules with enhanced scoring
    double aggScore = 0.0;
    final aggMatches = <String>[];
    for (final ruleSet in _aggregationRules.values) {
      for (final weightedKeyword in ruleSet) {
        for (final variant in queryVariants) {
          if (variant.contains(weightedKeyword.keyword.toLowerCase())) {
            aggScore += weightedKeyword.weight;
            aggMatches.add(weightedKeyword.keyword);
          }
        }
      }
    }
    if (aggScore > 0) {
      scores[IntentType.aggregate] = (aggScore / 5.0).clamp(0.0, 1.0);
      _logger.info('   Aggregation matches: $aggMatches (score: ${scores[IntentType.aggregate]})');
    }
    
    // Check retrieval rules with enhanced scoring
    double retScore = 0.0;
    final retMatches = <String>[];
    for (final ruleSet in _retrievalRules.values) {
      for (final weightedKeyword in ruleSet) {
        for (final variant in queryVariants) {
          if (variant.contains(weightedKeyword.keyword.toLowerCase())) {
            retScore += weightedKeyword.weight;
            retMatches.add(weightedKeyword.keyword);
          }
        }
      }
    }
    if (retScore > 0) {
      scores[IntentType.retrieval] = (retScore / 5.0).clamp(0.0, 1.0);
      _logger.info('   Retrieval matches: $retMatches (score: ${scores[IntentType.retrieval]})');
    }
    
    // Check reminder rules (keep existing simple logic)
    double remScore = 0.0;
    final remMatches = <String>[];
    for (final ruleSet in _reminderRules.values) {
      for (final rule in ruleSet) {
        for (final variant in queryVariants) {
          if (variant.contains(rule.toLowerCase())) {
            remScore += 1.0;
            remMatches.add(rule);
          }
        }
      }
    }
    if (remScore > 0) {
      scores[IntentType.reminder] = (remScore / 3.0).clamp(0.0, 1.0);
      _logger.info('   Reminder matches: $remMatches (score: ${scores[IntentType.reminder]})');
    }
    
    // Detect mixed queries (both calc + explanation)
    final mixedQueryInfo = _detectMixedQuery(query, queryVariants, aggScore, retScore);
    
    final maxScore = scores.isNotEmpty ? scores.values.reduce((a, b) => a > b ? a : b) : 0.0;
    final highConfidenceThreshold = 0.8;
    
    final result = RuleClassificationResult(
      scores: scores,
      hasHighConfidenceMatch: maxScore > highConfidenceThreshold,
      mixedQueryDetected: mixedQueryInfo.isMixed,
      detectedLanguage: detectedLanguage,
      queryVariants: queryVariants,
    );
    
    _logger.info('   Final rule result: ${result.toString()}');
    return result;
  }

  String _detectLanguage(String query) {
    // Simple heuristic: if contains Han characters, it's Chinese
    final hanPattern = RegExp(r'[\u4e00-\u9fff]');
    return hanPattern.hasMatch(query) ? 'zh' : 'en';
  }

  List<String> _generateQueryVariants(String query, String detectedLanguage) {
    final variants = [query.toLowerCase()];
    
    // Add translated variant using lightweight dictionary
    if (detectedLanguage == 'zh') {
      variants.add(_translateToEnglish(query));
    } else {
      variants.add(_translateToChinese(query));
    }
    
    return variants;
  }

  String _translateToEnglish(String chineseQuery) {
    // Lightweight phrase dictionary for common patterns
    final translations = {
      '多少钱': 'how much money',
      '为什么': 'why',
      '怎么办': 'what to do',
      '总计': 'total',
      '平均': 'average',
      '分析': 'analyze',
      '建议': 'suggest',
      '改进': 'improve',
      '消费': 'spending',
      '支出': 'expense',
      '收入': 'income',
      '吃饭': 'eating',
      '心情': 'mood',
      '健康': 'health',
      '这个月': 'this month',
      '上个月': 'last month',
      '今天': 'today',
      '昨天': 'yesterday',
      '本周': 'this week',
      '上周': 'last week',
    };
    
    String translated = chineseQuery.toLowerCase();
    translations.forEach((chinese, english) {
      translated = translated.replaceAll(chinese, english);
    });
    
    return translated;
  }

  String _translateToChinese(String englishQuery) {
    // Lightweight phrase dictionary for common patterns
    final translations = {
      'how much': '多少',
      'why': '为什么',
      'total': '总计',
      'average': '平均',
      'analyze': '分析',
      'suggest': '建议',
      'improve': '改进',
      'spending': '消费',
      'expense': '支出',
      'income': '收入',
      'eating': '吃饭',
      'mood': '心情',
      'health': '健康',
      'this month': '这个月',
      'last month': '上个月',
      'today': '今天',
      'yesterday': '昨天',
      'this week': '本周',
      'last week': '上周',
    };
    
    String translated = englishQuery.toLowerCase();
    translations.forEach((english, chinese) {
      translated = translated.replaceAll(english, chinese);
    });
    
    return translated;
  }

  MixedQueryInfo _detectMixedQuery(String query, List<String> variants, double aggScore, double retScore) {
    // Detect queries that ask for both calculation AND explanation/advice
    final mixedPatterns = [
      // English patterns
      RegExp(r'(how much|total|amount|spent).*and.*(why|explain|suggest|improve|advice)', caseSensitive: false),
      RegExp(r'(calculate|sum).*and.*(analyze|recommend)', caseSensitive: false),
      RegExp(r'(show me).*and.*(help|advice)', caseSensitive: false),
      
      // Chinese patterns
      RegExp(r'(多少钱|总计|花费).*为什么', caseSensitive: false),
      RegExp(r'(总计|计算).*建议', caseSensitive: false),
      RegExp(r'(多少|数量).*分析', caseSensitive: false),
      RegExp(r'(支出|消费).*改进', caseSensitive: false),
    ];
    
    final isMixed = mixedPatterns.any((pattern) => pattern.hasMatch(query)) ||
                   (aggScore > 1.0 && retScore > 1.0); // Both types have significant matches
    
    return MixedQueryInfo(
      isMixed: isMixed,
      calculationStrength: aggScore,
      retrievalStrength: retScore,
    );
  }

  bool hasCalculationKeywords(String query) {
    final queryLower = query.toLowerCase();
    return _aggregationRules.values
        .expand((rules) => rules)
        .any((weightedKeyword) => queryLower.contains(weightedKeyword.keyword.toLowerCase()));
  }

  bool hasGenerationKeywords(String query) {
    final queryLower = query.toLowerCase();
    return _retrievalRules.values
        .expand((rules) => rules)
        .any((weightedKeyword) => queryLower.contains(weightedKeyword.keyword.toLowerCase()));
  }
}

/// Stage 2: Semantic prototype similarity classifier
class SemanticClassifier {
  static final _logger = Logger('SemanticClassifier');
  
  static final _prototypes = <IntentType, List<String>>{
    IntentType.aggregate: [
      "How much money did I spend on groceries this month?",
      "What's the total amount of my expenses?", 
      "Show me the average cost per meal",
      "Count how many books I read this year",
      "What's my highest expense category?",
      "这个月我花了多少钱？",
      "我的平均支出是多少？",
      "计算我今年的总收入",
    ],
    IntentType.retrieval: [
      "Tell me about my recent activities",
      "What happened last week?",
      "Explain my spending patterns",
      "Show me my journal entries about travel",
      "Recommend books based on my reading history",
      "告诉我最近发生了什么",
      "解释一下我的消费习惯",
      "推荐一些适合我的电影",
    ],
    IntentType.reminder: [
      "Remind me to exercise every morning",
      "Set up a weekly review schedule",
      "Create a recurring alarm for medication",
      "Schedule monthly budget review",
      "每天提醒我喝水",
      "设置每周的会议提醒",
      "创建定期的任务提醒",
    ],
  };

  Future<SemanticClassificationResult> classify(String query) async {
    _logger.debug('🧠 Semantic classification for: "$query"');
    
    // Enhanced similarity calculation with dynamic thresholds
    final scores = <IntentType, double>{};
    final queryLength = query.split(' ').length;
    
    // Dynamic similarity threshold based on query complexity
    final baseSimilarityThreshold = 0.53;
    final lengthAdjustment = (queryLength - 5) * 0.02; // Adjust for longer queries
    final dynamicThreshold = (baseSimilarityThreshold + lengthAdjustment).clamp(0.4, 0.7);
    
    _logger.info('   Query length: $queryLength words');
    _logger.info('   Dynamic similarity threshold: ${dynamicThreshold.toStringAsFixed(3)}');
    
    for (final entry in _prototypes.entries) {
      double maxSimilarity = 0.0;
      String bestMatch = '';
      
      for (final prototype in entry.value) {
        final similarity = _calculateSimilarity(query, prototype);
        if (similarity > maxSimilarity) {
          maxSimilarity = similarity;
          bestMatch = prototype;
        }
      }
      
      scores[entry.key] = maxSimilarity;
      if (maxSimilarity > dynamicThreshold) {
        _logger.info('   ${entry.key}: ${maxSimilarity.toStringAsFixed(3)} (match: "${bestMatch.substring(0, bestMatch.length.clamp(0, 50))}...")');
      }
    }
    
    final sortedScores = scores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    final margin = sortedScores.length >= 2 
        ? sortedScores[0].value - sortedScores[1].value 
        : sortedScores.isNotEmpty ? sortedScores[0].value : 0.0;
    
    final topScore = sortedScores.isNotEmpty ? sortedScores[0].value : 0.0;
    final meetsThreshold = topScore >= dynamicThreshold;
    
    _logger.info('   Top score: ${topScore.toStringAsFixed(3)}, Margin: ${margin.toStringAsFixed(3)}, Meets threshold: $meetsThreshold');
    
    return SemanticClassificationResult(
      scores: scores,
      margin: margin,
      dynamicThreshold: dynamicThreshold,
      meetsThreshold: meetsThreshold,
    );
  }

  double _calculateSimilarity(String query1, String query2) {
    // Simple similarity calculation - in practice, use embedding similarity
    final words1 = query1.toLowerCase().split(' ').toSet();
    final words2 = query2.toLowerCase().split(' ').toSet();
    final intersection = words1.intersection(words2);
    final union = words1.union(words2);
    return union.isEmpty ? 0.0 : intersection.length / union.length;
  }
}

/// Stage 3: LLM function calling classifier
class LLMClassifier {
  Future<LLMClassificationResult> classify(String query, QueryContext context) async {
    // Mock implementation - in practice, call actual LLM
    // For demo purposes, use simple heuristics
    
    final queryLower = query.toLowerCase();
    IntentType intent;
    String reason;
    Map<String, dynamic> slots = {};
    
    if (queryLower.contains('much') || queryLower.contains('total') || queryLower.contains('spend')) {
      intent = IntentType.aggregate;
      reason = "Query asks for quantitative information about spending/amounts";
      slots = {
        'operation': 'sum',
        'domain': 'finance',
        'timeframe': context.timeRange?.toString() ?? 'unspecified',
      };
    } else if (queryLower.contains('tell') || queryLower.contains('explain') || queryLower.contains('show')) {
      intent = IntentType.retrieval;
      reason = "Query requests information retrieval or explanation";
      slots = {
        'domains': context.targetDomains,
        'searchType': 'descriptive',
      };
    } else {
      intent = IntentType.retrieval;
      reason = "Default to retrieval for unclear queries";
      slots = {};
    }
    
    return LLMClassificationResult(
      intent: intent,
      reason: reason,
      slots: slots,
      confidence: 0.7,
    );
  }
}

// Supporting data classes
enum IntentType { aggregate, retrieval, reminder }

@immutable
class RoutingWeights {
  const RoutingWeights({
    required this.rule,
    required this.semantic,
    required this.llm,
    required this.dataMissing,
  });
  
  final double rule;
  final double semantic;
  final double llm;
  final double dataMissing;
}

@immutable
class SemanticClassificationResult {
  const SemanticClassificationResult({
    required this.scores,
    required this.margin,
    this.dynamicThreshold = 0.53,
    this.meetsThreshold = false,
  });
  
  final Map<IntentType, double> scores;
  final double margin;
  final double dynamicThreshold;
  final bool meetsThreshold;
}

@immutable
class LLMClassificationResult {
  const LLMClassificationResult({
    required this.intent,
    required this.reason,
    required this.slots,
    required this.confidence,
  });
  
  final IntentType intent;
  final String reason;
  final Map<String, dynamic> slots;
  final double confidence;
}

@immutable
class RoutingDecision {
  const RoutingDecision({
    required this.primaryIntent,
    required this.confidence,
    required this.hybrid,
    required this.ruleResult,
    required this.semanticResult,
    this.llmResult,
    this.isMixedQuery = false,
  });
  
  final IntentType primaryIntent;
  final double confidence;
  final bool hybrid;
  final bool isMixedQuery;
  final RuleClassificationResult ruleResult;
  final SemanticClassificationResult semanticResult;
  final LLMClassificationResult? llmResult;

  @override
  String toString() {
    return 'RoutingDecision(intent: $primaryIntent, confidence: ${confidence.toStringAsFixed(3)}, '
           'hybrid: $hybrid, mixed: $isMixedQuery)';
  }
}
