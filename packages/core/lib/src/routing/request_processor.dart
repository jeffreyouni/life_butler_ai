import 'package:meta/meta.dart';
import 'package:providers_llm/providers_llm.dart';
import 'request_router.dart';
import '../rag/rag_pipeline.dart';
import '../rag/search_result.dart';
import '../advice/advice_engine.dart';
import '../advice/advice_result.dart';
import '../models/base_model.dart';
import '../query/query_context.dart';
import '../utils/logger.dart';

/// Intelligent request processor that executes the optimal processing path
/// for user requests based on routing decisions
abstract class RequestProcessor {
  /// Process a request using the determined routing strategy
  Future<ProcessingResult> processRequest(RequestRouting routing);

  /// Execute calculation-focused processing (aggregation/filtering)
  Future<CalculationResult> executeCalculation(CalculationSpecs specs, String query);

  /// Execute retrieval-focused processing (search/generation)
  Future<RetrievalResult> executeRetrieval(RetrievalSpecs specs, String query);

  /// Execute hybrid processing (calculation + generation)
  Future<HybridResult> executeHybrid(
    CalculationSpecs calcSpecs, 
    RetrievalSpecs retrievalSpecs, 
    String query
  );
}

/// Base result class for all processing outcomes
@immutable
abstract class ProcessingResult {
  const ProcessingResult({
    required this.query,
    required this.processingTime,
    required this.confidence,
  });

  final String query;
  final Duration processingTime;
  final double confidence;

  /// Convert result to user-friendly response text
  String toResponseText();
}

/// Result of calculation-focused processing
@immutable
class CalculationResult extends ProcessingResult {
  const CalculationResult({
    required super.query,
    required super.processingTime,
    required super.confidence,
    required this.calculations,
    required this.aggregations,
    required this.dataPoints,
    this.visualizationData,
  });

  final Map<String, dynamic> calculations;
  final Map<String, dynamic> aggregations;
  final List<DataPoint> dataPoints;
  final Map<String, dynamic>? visualizationData;

  @override
  String toResponseText() {
    final buffer = StringBuffer();
    buffer.writeln('📊 **Calculation Results**\n');
    
    // Show main calculations
    for (final entry in calculations.entries) {
      buffer.writeln('• **${entry.key}**: ${_formatValue(entry.value)}');
    }
    
    // Show aggregations
    if (aggregations.isNotEmpty) {
      buffer.writeln('\n📈 **Summary Statistics**');
      for (final entry in aggregations.entries) {
        buffer.writeln('• ${entry.key}: ${_formatValue(entry.value)}');
      }
    }
    
    // Show data insights
    if (dataPoints.isNotEmpty) {
      buffer.writeln('\n🔍 **Key Data Points** (${dataPoints.length} records analyzed)');
      for (final point in dataPoints.take(5)) {
        buffer.writeln('• ${point.description}');
      }
    }
    
    return buffer.toString();
  }

  String _formatValue(dynamic value) {
    if (value is double) {
      return value.toStringAsFixed(2);
    } else if (value is int) {
      return value.toString();
    } else if (value is String) {
      return value;
    } else {
      return value.toString();
    }
  }
}

/// Result of retrieval-focused processing
@immutable
class RetrievalResult extends ProcessingResult {
  const RetrievalResult({
    required super.query,
    required super.processingTime,
    required super.confidence,
    required this.response,
    required this.sources,
    required this.generationType,
    this.advice,
  });

  final String response;
  final List<SourceCitation> sources;
  final GenerationType generationType;
  final String? advice;

  @override
  String toResponseText() {
    final buffer = StringBuffer();
    
    // Main response
    buffer.writeln(response);
    
    // Add advice if available
    if (advice != null && advice!.isNotEmpty) {
      buffer.writeln('\n💡 **Recommendations**');
      buffer.writeln(advice);
    }
    
    // Add sources
    if (sources.isNotEmpty) {
      buffer.writeln('\n📚 **Sources**');
      for (int i = 0; i < sources.length; i++) {
        final source = sources[i];
        buffer.writeln('${i + 1}. ${source.title} (${source.type})');
      }
    }
    
    return buffer.toString();
  }
}

/// Result of hybrid processing (calculation + generation)
@immutable
class HybridResult extends ProcessingResult {
  const HybridResult({
    required super.query,
    required super.processingTime,
    required super.confidence,
    required this.calculationResult,
    required this.retrievalResult,
    required this.synthesis,
  });

  final CalculationResult calculationResult;
  final RetrievalResult retrievalResult;
  final String synthesis; // Combined interpretation

  @override
  String toResponseText() {
    final buffer = StringBuffer();
    
    // Combined analysis header
    buffer.writeln('🔬 **Comprehensive Analysis**\n');
    
    // Synthesis first (most important)
    if (synthesis.isNotEmpty) {
      buffer.writeln(synthesis);
      buffer.writeln();
    }
    
    // Then calculations
    buffer.writeln('📊 **Quantitative Analysis**');
    for (final entry in calculationResult.calculations.entries) {
      buffer.writeln('• **${entry.key}**: ${entry.value}');
    }
    buffer.writeln();
    
    // Then contextual insights
    buffer.writeln('🧠 **Contextual Insights**');
    buffer.writeln(retrievalResult.response);
    
    // Advice if available
    if (retrievalResult.advice != null) {
      buffer.writeln('\n💡 **Actionable Recommendations**');
      buffer.writeln(retrievalResult.advice);
    }
    
    return buffer.toString();
  }
}

/// Data point from calculation processing
@immutable
class DataPoint {
  const DataPoint({
    required this.id,
    required this.value,
    required this.description,
    required this.timestamp,
    this.category,
    this.metadata,
  });

  final String id;
  final double value;
  final String description;
  final DateTime timestamp;
  final String? category;
  final Map<String, dynamic>? metadata;
}

/// Source citation for retrieval results
@immutable
class SourceCitation {
  const SourceCitation({
    required this.id,
    required this.title,
    required this.type,
    required this.timestamp,
    this.relevanceScore,
    this.snippet,
  });

  final String id;
  final String title;
  final String type;
  final DateTime timestamp;
  final double? relevanceScore;
  final String? snippet;
}

/// Default implementation of request processor
class DefaultRequestProcessor implements RequestProcessor {
  static final _logger = Logger('RequestProcessor');
  
  DefaultRequestProcessor({
    required RagPipeline ragPipeline,
    required AdviceEngine adviceEngine,
    required DataAggregator dataAggregator,
    dynamic llmProvider,
    this.promptTemplates,
  }) : _ragPipeline = ragPipeline,
       _adviceEngine = adviceEngine,
       _dataAggregator = dataAggregator,
       _llmProvider = llmProvider {
    
    _logger.debug('🔧 DefaultRequestProcessor initialized with promptTemplates: ${promptTemplates != null ? 'available (${promptTemplates!.keys.join(', ')})' : 'null'}');
    if (promptTemplates != null && promptTemplates!.containsKey('rag_prompt_template')) {
      final template = promptTemplates!['rag_prompt_template']!;
      _logger.debug('🎯 RAG template preview: ${template.substring(0, template.length.clamp(0, 150))}...');
    }
  }

  final RagPipeline _ragPipeline;
  final AdviceEngine _adviceEngine;
  final DataAggregator _dataAggregator;
  final dynamic _llmProvider;
  final Map<String, String>? promptTemplates;

  @override
  Future<ProcessingResult> processRequest(RequestRouting routing) async {
    final startTime = DateTime.now();
    
    try {
      ProcessingResult result;
      
      switch (routing.processingPath) {
        case ProcessingPath.calculation:
          result = await executeCalculation(routing.calculationSpecs!, routing.originalQuery);
          break;
          
        case ProcessingPath.retrieval:
          result = await executeRetrieval(routing.retrievalSpecs!, routing.originalQuery);
          break;
          
        case ProcessingPath.hybrid:
          result = await executeHybrid(
            routing.calculationSpecs!,
            routing.retrievalSpecs!,
            routing.originalQuery,
          );
          break;
      }
      
      return result;
      
    } catch (e) {
      final processingTime = DateTime.now().difference(startTime);
      
      // Return error result
      return RetrievalResult(
        query: routing.originalQuery,
        processingTime: processingTime,
        confidence: 0.0,
        response: 'Sorry, I encountered an error while processing your request: $e',
        sources: [],
        generationType: GenerationType.factual,
      );
    }
  }

  @override
  Future<CalculationResult> executeCalculation(CalculationSpecs specs, String query) async {
    final startTime = DateTime.now();
    
    // Execute calculations based on specifications
    final calculations = <String, dynamic>{};
    final aggregations = <String, dynamic>{};
    final dataPoints = <DataPoint>[];
    
    // Perform aggregations
    for (final aggregation in specs.aggregations) {
      switch (aggregation) {
        case AggregationType.sum:
          final result = await _dataAggregator.calculateSum(
            filters: specs.filters,
            timeRange: specs.timeRange,
          );
          calculations['Total'] = result.value;
          dataPoints.addAll(result.dataPoints);
          break;
          
        case AggregationType.average:
          final result = await _dataAggregator.calculateAverage(
            filters: specs.filters,
            timeRange: specs.timeRange,
          );
          calculations['Average'] = result.value;
          dataPoints.addAll(result.dataPoints);
          break;
          
        case AggregationType.count:
          final result = await _dataAggregator.calculateCount(
            filters: specs.filters,
            timeRange: specs.timeRange,
          );
          calculations['Count'] = result.value;
          dataPoints.addAll(result.dataPoints);
          break;
          
        default:
          // Handle other aggregation types
          break;
      }
    }
    
    // Generate summary aggregations
    if (dataPoints.isNotEmpty) {
      aggregations['Data Points'] = dataPoints.length;
      aggregations['Date Range'] = _formatDateRange(dataPoints);
    }
    
    // Generate AI-powered explanation of calculation results
    String aiExplanation;
    try {
      aiExplanation = await _generateCalculationExplanation(query, calculations, aggregations, dataPoints);
    } catch (e) {
      _logger.info('🚨 AI calculation explanation failed, using fallback: $e');
      aiExplanation = _generateRuleBasedCalculationSummary(calculations, aggregations);
    }
    
    final processingTime = DateTime.now().difference(startTime);
    
    final calculationResult = CalculationResult(
      query: query,
      processingTime: processingTime,
      confidence: 0.9, // High confidence for calculations
      calculations: calculations,
      aggregations: aggregations,
      dataPoints: dataPoints,
    );

    // Add AI explanation to the response
    return _addAIExplanationToCalculationResult(calculationResult, aiExplanation);
  }

  @override
  Future<RetrievalResult> executeRetrieval(RetrievalSpecs specs, String query) async {
    final startTime = DateTime.now();
    
    // Execute semantic search
    final searchResults = await _ragPipeline.search(
      query,
      objectTypes: specs.domainFocus,
      limit: _getSearchLimit(specs.contextNeeds),
    );
    
    // Generate response based on generation type
    String response;
    String? advice;
    
    switch (specs.generationType) {
      case GenerationType.advisory:
        // Use RAG pipeline with prompt templates for advisory responses
        response = await _ragPipeline.answer(
          query,
          promptTemplates: promptTemplates,
        );
        // Keep advice field for backward compatibility
        advice = null;
        break;
        
      case GenerationType.analytical:
        response = await _ragPipeline.answer(
          query, 
          promptTemplates: promptTemplates,
        );
        break;
        
      case GenerationType.summary:
        response = await _ragPipeline.answer(
          query, 
          promptTemplates: promptTemplates,
        );
        break;
        
      case GenerationType.narrative:
        response = await _ragPipeline.answer(
          query, 
          promptTemplates: promptTemplates,
        );
        break;
        
      default:
        response = await _ragPipeline.answer(
          query, 
          promptTemplates: promptTemplates,
        );
        break;
    }
    
    // Create source citations
    final sources = searchResults.map((result) => SourceCitation(
      id: result.id,
      title: result.text.length > 50 
          ? '${result.text.substring(0, 50)}...' 
          : result.text,
      type: result.objectType,
      timestamp: DateTime.now(), // Use current time as fallback since SearchResult doesn't have timestamp
      relevanceScore: result.similarity,
      snippet: result.text,
    )).toList();
    
    final processingTime = DateTime.now().difference(startTime);
    
    return RetrievalResult(
      query: query,
      processingTime: processingTime,
      confidence: _calculateRetrievalConfidence(searchResults),
      response: response,
      sources: sources,
      generationType: specs.generationType,
      advice: advice,
    );
  }

  @override
  Future<HybridResult> executeHybrid(
    CalculationSpecs calcSpecs,
    RetrievalSpecs retrievalSpecs,
    String query,
  ) async {
    final startTime = DateTime.now();
    
    // Execute both calculation and retrieval in parallel for efficiency
    final results = await Future.wait([
      executeCalculation(calcSpecs, query),
      executeRetrieval(retrievalSpecs, query),
    ]);
    
    final calculationResult = results[0] as CalculationResult;
    final retrievalResult = results[1] as RetrievalResult;
    
    // Generate synthesis combining both results
    final synthesis = await _generateSynthesis(
      query, 
      calculationResult, 
      retrievalResult
    );
    
    final processingTime = DateTime.now().difference(startTime);
    final combinedConfidence = (calculationResult.confidence + retrievalResult.confidence) / 2;
    
    return HybridResult(
      query: query,
      processingTime: processingTime,
      confidence: combinedConfidence,
      calculationResult: calculationResult,
      retrievalResult: retrievalResult,
      synthesis: synthesis,
    );
  }

  /// Generate synthesis for hybrid results using AI
  Future<String> _generateSynthesis(
    String query,
    CalculationResult calcResult,
    RetrievalResult retrievalResult,
  ) async {
    try {
      // Try AI-powered synthesis first
      return await _generateAISynthesis(query, calcResult, retrievalResult);
    } catch (e) {
      _logger.info('🚨 AI synthesis failed, falling back to rule-based: $e');
      // Fallback to rule-based synthesis
      return _generateRuleBasedSynthesis(calcResult, retrievalResult);
    }
  }

  /// Generate AI-powered synthesis combining calculation and retrieval results
  Future<String> _generateAISynthesis(
    String query,
    CalculationResult calcResult,
    RetrievalResult retrievalResult,
  ) async {
    // Use RAG pipeline with prompt templates for consistent synthesis generation
    return await _ragPipeline.answer(
      query,
      promptTemplates: promptTemplates,
    );
  }

  /// Build specialized prompt for hybrid analysis
  String _buildHybridPrompt(
    String query,
    CalculationResult calcResult,
    RetrievalResult retrievalResult,
  ) {
    final buffer = StringBuffer();
    
    buffer.writeln('Human: You are a personal data analyst and life coach. '
        'The user asked: "$query"');
    buffer.writeln();
    buffer.writeln('User Query: $query');
    buffer.writeln('Response Type: hybrid (analytical + contextual)');
    buffer.writeln();
    
    // Add calculation data
    if (calcResult.calculations.isNotEmpty) {
      buffer.writeln('Calculation Results:');
      calcResult.calculations.forEach((key, value) {
        buffer.writeln('• $key: $value');
      });
      buffer.writeln();
    }
    
    // Add retrieval context
    if (retrievalResult.sources.isNotEmpty) {
      buffer.writeln('Relevant Context (${retrievalResult.sources.length} items):');
      for (int i = 0; i < retrievalResult.sources.length; i++) {
        final source = retrievalResult.sources[i];
        final relevance = ((source.relevanceScore ?? 0.0) * 100).toStringAsFixed(1);
        buffer.writeln('${i + 1}. ${source.snippet}');
        buffer.writeln('   Type: ${source.type}, Relevance: $relevance%');
      }
      buffer.writeln();
    }
    
    buffer.writeln('Please provide a comprehensive response that:');
    buffer.writeln('1. Synthesizes the calculated data with the contextual information');
    buffer.writeln('2. Explains what the numbers mean in the context of their life');
    buffer.writeln('3. Identifies patterns and trends from the data');
    buffer.writeln('4. Provides actionable insights and recommendations');
    buffer.writeln('5. Uses a supportive and analytical tone');
    buffer.writeln();
    buffer.writeln('Create a cohesive analysis that helps them understand both the '
        'quantitative and qualitative aspects of their situation.');
    buffer.writeln('Assistant: ');
    
    return buffer.toString();
  }

  /// Fallback rule-based synthesis when AI fails
  String _generateRuleBasedSynthesis(
    CalculationResult calcResult,
    RetrievalResult retrievalResult,
  ) {
    final buffer = StringBuffer();
    
    // Start with the most important finding
    if (calcResult.calculations.isNotEmpty) {
      final mainCalculation = calcResult.calculations.entries.first;
      buffer.writeln('Based on your data analysis:');
      buffer.writeln('• **${mainCalculation.key}**: ${mainCalculation.value}');
      buffer.writeln();
    }
    
    // Add contextual interpretation
    buffer.writeln('**Analysis**: ${retrievalResult.response}');
    buffer.writeln();
    
    // Add actionable insights if available
    if (retrievalResult.advice != null) {
      buffer.writeln('**Key Insights**: ${retrievalResult.advice}');
    }
    
    return buffer.toString();
  }

  /// Helper methods
  RagContext _createRagContext(String query, List<SearchResult> searchResults) {
    return RagContext(
      query: query,
      results: searchResults,
      totalTokens: query.length + searchResults.fold(0, (sum, r) => sum + r.text.length),
    );
  }

  int _getSearchLimit(ContextNeeds contextNeeds) {
    switch (contextNeeds) {
      case ContextNeeds.minimal:
        return 3;
      case ContextNeeds.moderate:
        return 5;
      case ContextNeeds.extensive:
        return 10;
      case ContextNeeds.historical:
        return 15;
      case ContextNeeds.comparative:
        return 8;
    }
  }

  double _calculateRetrievalConfidence(List<SearchResult> searchResults) {
    if (searchResults.isEmpty) return 0.0;
    
    // Calculate average similarity score
    final avgSimilarity = searchResults
        .map((r) => r.similarity)
        .reduce((a, b) => a + b) / searchResults.length;
    
    return avgSimilarity.clamp(0.0, 1.0);
  }

  String _formatDateRange(List<DataPoint> dataPoints) {
    if (dataPoints.isEmpty) return 'No data';
    
    final dates = dataPoints.map((dp) => dp.timestamp).toList()..sort();
    final start = dates.first;
    final end = dates.last;
    
    if (start.year == end.year && start.month == end.month && start.day == end.day) {
      return '${start.year}-${start.month.toString().padLeft(2, '0')}-${start.day.toString().padLeft(2, '0')}';
    } else {
      return '${start.year}-${start.month.toString().padLeft(2, '0')}-${start.day.toString().padLeft(2, '0')} to ${end.year}-${end.month.toString().padLeft(2, '0')}-${end.day.toString().padLeft(2, '0')}';
    }
  }

  Future<String> _generateAnalyticalResponse(String query, List<SearchResult> searchResults) async {
    if (searchResults.isEmpty) {
      return 'No data available for analysis.';
    }
    
    // Try AI-powered response first
    if (_llmProvider != null) {
      try {
        return await _generateAIResponse(query, searchResults, 'analytical');
      } catch (e) {
        _logger.error('❌ AI analytical response failed: $e');
        // Fall back to rule-based response
      }
    }
    
    // Fallback: Rule-based response
    final buffer = StringBuffer();
    buffer.writeln('**Analytical Insights:**\n');
    
    // Group results by object type for analysis
    final groupedResults = <String, List<SearchResult>>{};
    for (final result in searchResults) {
      groupedResults.putIfAbsent(result.objectType, () => []).add(result);
    }
    
    for (final entry in groupedResults.entries) {
      buffer.writeln('**${entry.key}** (${entry.value.length} records):');
      for (final result in entry.value.take(3)) {
        buffer.writeln('• ${result.text.length > 100 ? result.text.substring(0, 100) + '...' : result.text}');
      }
      buffer.writeln();
    }
    
    return buffer.toString();
  }

  Future<String> _generateSummaryResponse(String query, List<SearchResult> searchResults) async {
    if (searchResults.isEmpty) {
      return 'No data available to summarize.';
    }
    
    // Try AI-powered response first
    if (_llmProvider != null) {
      try {
        return await _generateAIResponse(query, searchResults, 'summary');
      } catch (e) {
        _logger.error('❌ AI summary response failed: $e');
        // Fall back to rule-based response
      }
    }
    
    // Fallback: Rule-based response
    final buffer = StringBuffer();
    buffer.writeln('**Summary of findings:**\n');
    buffer.writeln('Found ${searchResults.length} relevant records across your personal data.\n');
    
    // Show most relevant result
    final topResult = searchResults.first;
    buffer.writeln('**Most relevant information:**');
    buffer.writeln(topResult.text.length > 200 ? topResult.text.substring(0, 200) + '...' : topResult.text);
    
    return buffer.toString();
  }

  Future<String> _generateNarrativeResponse(String query, List<SearchResult> searchResults) async {
    if (searchResults.isEmpty) {
      return 'I don\'t have enough data to provide a meaningful explanation for your question.';
    }
    
    // Try AI-powered response first
    if (_llmProvider != null) {
      try {
        return await _generateAIResponse(query, searchResults, 'narrative');
      } catch (e) {
        _logger.error('❌ AI narrative response failed: $e');
        // Fall back to rule-based response
      }
    }
    
    // Fallback: Rule-based response
    final buffer = StringBuffer();
    buffer.writeln('Based on your data, here\'s what I found:\n');
    
    // Group by object type for better organization
    final groupedResults = <String, List<SearchResult>>{};
    for (final result in searchResults) {
      groupedResults.putIfAbsent(result.objectType, () => []).add(result);
    }
    
    for (final entry in groupedResults.entries) {
      final objectType = entry.key;
      final results = entry.value;
      
      buffer.writeln('**${objectType} Analysis:**');
      if (results.length > 3) {
        buffer.writeln('I found ${results.length} relevant records. Here are the most relevant ones:');
      }
      
      for (final result in results.take(3)) {
        buffer.writeln('• ${result.text}');
      }
      buffer.writeln();
    }
    
    return buffer.toString();
  }

  Future<String> _generateFactualResponse(String query, List<SearchResult> searchResults) async {
    if (searchResults.isEmpty) {
      return 'No specific information found for your query.';
    }
    
    // Try AI-powered response first
    if (_llmProvider != null) {
      try {
        return await _generateAIResponse(query, searchResults, 'factual');
      } catch (e) {
        _logger.error('❌ AI factual response failed: $e');
        // Fall back to rule-based response
      }
    }
    
    // Fallback: Rule-based response
    final buffer = StringBuffer();
    buffer.writeln('**Information from your data:**\n');
    
    for (int i = 0; i < searchResults.take(5).length; i++) {
      final result = searchResults[i];
      buffer.writeln('${i + 1}. ${result.text}');
      buffer.writeln('   Source: ${result.objectType} (${(result.similarity * 100).toStringAsFixed(1)}% match)');
      buffer.writeln();
    }
    
    return buffer.toString();
  }
  
  /// Universal AI-powered response generator for all query types
  Future<String> _generateAIResponse(String query, List<SearchResult> searchResults, String responseType) async {
    // Prepare context for the LLM
    final contextBuffer = StringBuffer();
    contextBuffer.writeln('User Query: $query');
    contextBuffer.writeln('Response Type: $responseType');
    contextBuffer.writeln('\nRelevant Data (${searchResults.length} total):');
    
    for (int i = 0; i < searchResults.take(10).length; i++) {
      final result = searchResults[i];
      contextBuffer.writeln('${i + 1}. ${result.text}');
      contextBuffer.writeln('   Type: ${result.objectType}, Relevance: ${(result.similarity * 100).toStringAsFixed(1)}%');
    }
    
    // Create specialized prompts based on response type
    final prompt = _buildPromptForResponseType(query, responseType, contextBuffer.toString());
    
    final messages = [
      Message.user(prompt),
    ];

    _logger.info('🤖 Calling LLM for $responseType response...');
    final aiResponse = await _llmProvider!.chat(messages, temperature: 0.7);
    final preview = aiResponse.length > 100 ? aiResponse.substring(0, 100) + '...' : aiResponse;
    _logger.info('✅ LLM generated $responseType response: $preview');
    
    return aiResponse;
  }
  
  /// Build specialized prompts for different response types
  String _buildPromptForResponseType(String query, String responseType, String context) {
    switch (responseType) {
      case 'analytical':
        return '''You are a personal data analyst AI. The user asked: "$query"

$context

Please provide an analytical response that:
1. Identifies patterns and trends in the data
2. Provides statistical insights and correlations
3. Explains the significance of the findings
4. Uses data-driven reasoning

Keep the response detailed but accessible, focusing on meaningful insights from their personal data.''';

      case 'summary':
        return '''You are a personal assistant AI. The user asked: "$query"

$context

Please provide a concise summary that:
1. Highlights the most important findings
2. Presents key information clearly and briefly
3. Focuses on what's most relevant to their query
4. Uses bullet points or structured format when helpful

Keep the response brief but comprehensive, covering the essential points.''';

      case 'narrative':
        return '''You are a personal life coach AI. The user asked: "$query"

$context

Please provide a narrative response that:
1. Tells the story behind their data
2. Explains patterns and relationships in their life
3. Provides context and meaning to the information
4. Offers insights about their habits and behaviors
5. Uses an encouraging and supportive tone

Create a cohesive story that helps them understand their data in the context of their life.''';

      case 'factual':
        return '''You are a personal information assistant AI. The user asked: "$query"

$context

Please provide a factual response that:
1. Presents the relevant information clearly
2. Sticks to the facts from their data
3. Organizes information logically
4. Provides specific details and examples
5. Avoids speculation or advice

Focus on delivering accurate, well-organized information from their personal data.''';

      default:
        return '''You are a helpful personal assistant AI. The user asked: "$query"

$context

Please provide a helpful response based on their personal data that directly addresses their question.''';
    }
  }
  
  /// Generate AI-powered explanation of calculation results
  Future<String> _generateCalculationExplanation(
    String query,
    Map<String, dynamic> calculations,
    Map<String, dynamic> aggregations,
    List<DataPoint> dataPoints,
  ) async {
    // Use RAG pipeline with prompt templates for consistent calculation explanation
    return await _ragPipeline.answer(
      query,
      promptTemplates: promptTemplates,
    );
  }

  /// Build specialized prompt for calculation explanation
  String _buildCalculationPrompt(
    String query,
    Map<String, dynamic> calculations,
    Map<String, dynamic> aggregations,
    List<DataPoint> dataPoints,
  ) {
    final buffer = StringBuffer();
    
    buffer.writeln('Human: You are a personal financial analyst and data interpreter. '
        'The user asked: "$query"');
    buffer.writeln();
    buffer.writeln('User Query: $query');
    buffer.writeln('Response Type: calculation analysis');
    buffer.writeln();
    
    // Add calculation results
    if (calculations.isNotEmpty) {
      buffer.writeln('Calculation Results:');
      calculations.forEach((key, value) {
        if (value is double) {
          buffer.writeln('• $key: ${value.toStringAsFixed(2)}');
        } else {
          buffer.writeln('• $key: $value');
        }
      });
      buffer.writeln();
    }
    
    // Add aggregation metadata
    if (aggregations.isNotEmpty) {
      buffer.writeln('Data Summary:');
      aggregations.forEach((key, value) {
        buffer.writeln('• $key: $value');
      });
      buffer.writeln();
    }
    
    // Add sample data points if available
    if (dataPoints.isNotEmpty) {
      final sampleSize = dataPoints.length > 3 ? 3 : dataPoints.length;
      buffer.writeln('Sample Data Points ($sampleSize of ${dataPoints.length}):');
      for (int i = 0; i < sampleSize; i++) {
        final point = dataPoints[i];
        buffer.writeln('${i + 1}. ${point.description}: ${point.value}');
      }
      buffer.writeln();
    }
    
    buffer.writeln('Please provide a clear and insightful explanation that:');
    buffer.writeln('1. Interprets what these numbers mean in practical terms');
    buffer.writeln('2. Provides context about whether these results are typical or unusual');
    buffer.writeln('3. Explains any patterns or trends visible in the data');
    buffer.writeln('4. Offers actionable insights based on the calculations');
    buffer.writeln('5. Uses a supportive and analytical tone');
    buffer.writeln();
    buffer.writeln('Make the data meaningful and actionable for the user.');
    buffer.writeln('Assistant: ');
    
    return buffer.toString();
  }

  /// Fallback rule-based calculation summary when AI fails
  String _generateRuleBasedCalculationSummary(
    Map<String, dynamic> calculations,
    Map<String, dynamic> aggregations,
  ) {
    final buffer = StringBuffer();
    
    if (calculations.isNotEmpty) {
      buffer.writeln('**Calculation Results:**');
      calculations.forEach((key, value) {
        if (value is double) {
          buffer.writeln('• **$key**: ${value.toStringAsFixed(2)}');
        } else {
          buffer.writeln('• **$key**: $value');
        }
      });
      buffer.writeln();
    }
    
    if (aggregations.isNotEmpty) {
      buffer.writeln('**Data Summary:**');
      aggregations.forEach((key, value) {
        buffer.writeln('• $key: $value');
      });
    }
    
    return buffer.toString();
  }

  /// Add AI explanation to calculation result by creating an enhanced version
  CalculationResult _addAIExplanationToCalculationResult(
    CalculationResult result,
    String aiExplanation,
  ) {
    return EnhancedCalculationResult(
      query: result.query,
      processingTime: result.processingTime,
      confidence: result.confidence,
      calculations: result.calculations,
      aggregations: result.aggregations,
      dataPoints: result.dataPoints,
      aiExplanation: aiExplanation,
      visualizationData: result.visualizationData,
    );
  }
}

/// Enhanced calculation result that includes AI explanation
class EnhancedCalculationResult extends CalculationResult {
  const EnhancedCalculationResult({
    required super.query,
    required super.processingTime,
    required super.confidence,
    required super.calculations,
    required super.aggregations,
    required super.dataPoints,
    required this.aiExplanation,
    super.visualizationData,
  });

  final String aiExplanation;

  @override
  String toResponseText() {
    final buffer = StringBuffer();
    
    // Add AI explanation first
    buffer.writeln('🤖 **AI Analysis**\n');
    buffer.writeln(aiExplanation);
    buffer.writeln('\n---\n');
    
    // Then add the original calculation details
    buffer.writeln('📊 **Detailed Results**\n');
    
    // Show main calculations
    for (final entry in calculations.entries) {
      buffer.writeln('• **${entry.key}**: ${_formatValue(entry.value)}');
    }
    
    // Show aggregations
    if (aggregations.isNotEmpty) {
      buffer.writeln('\n📈 **Summary Statistics**');
      for (final entry in aggregations.entries) {
        buffer.writeln('• ${entry.key}: ${_formatValue(entry.value)}');
      }
    }
    
    // Show data insights
    if (dataPoints.isNotEmpty) {
      buffer.writeln('\n🔍 **Key Data Points** (${dataPoints.length} records analyzed)');
      for (final point in dataPoints.take(5)) {
        buffer.writeln('• ${point.description}');
      }
    }
    
    return buffer.toString();
  }

  String _formatValue(dynamic value) {
    if (value is double) {
      return value.toStringAsFixed(2);
    } else if (value is int) {
      return value.toString();
    } else if (value is String) {
      return value;
    } else {
      return value.toString();
    }
  }
}

/// Interface for data aggregation operations
abstract class DataAggregator {
  Future<AggregationResult> calculateSum({
    Map<String, dynamic>? filters,
    TimeRange? timeRange,
  });

  Future<AggregationResult> calculateAverage({
    Map<String, dynamic>? filters,
    TimeRange? timeRange,
  });

  Future<AggregationResult> calculateCount({
    Map<String, dynamic>? filters,
    TimeRange? timeRange,
  });
}

/// Result of aggregation operations
@immutable
class AggregationResult {
  const AggregationResult({
    required this.value,
    required this.dataPoints,
    this.metadata,
  });

  final double value;
  final List<DataPoint> dataPoints;
  final Map<String, dynamic>? metadata;
}
