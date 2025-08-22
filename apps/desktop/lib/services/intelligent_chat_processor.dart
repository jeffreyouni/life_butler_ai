import 'package:meta/meta.dart';
import 'package:core/core.dart';
import 'package:data/data.dart';

/// Intelligent chat query processor that handles bilingual queries
/// and provides comprehensive answers using database data
class IntelligentChatProcessor {
  static final _logger = Logger('IntelligentChatProcessor');
  
  const IntelligentChatProcessor({
    required this.router,
    required this.processor,
    required this.ragPipeline,
    required this.database,
    this.promptTemplates,
  });

  final RequestRouter router;
  final RequestProcessor processor;
  final RagPipeline ragPipeline;
  final LifeButlerDatabase database;
  final Map<String, String>? promptTemplates;

  /// Process a user query and provide a comprehensive answer
  Future<ChatResponse> processQuery(String query) async {
    try {
      _logger.debug('🧠 Processing query: "$query"');
      
      // 1. Detect language and normalize
      final language = _detectLanguage(query);
      _logger.debug('🌐 Detected language: $language');
      
      // 2. Route the request to determine processing strategy
      final routing = await router.routeRequest(query);
      _logger.debug('🎯 Routed to: ${routing.processingPath} (confidence: ${routing.confidence.toStringAsFixed(3)})');
      
      // 3. Process the request based on routing
      final result = await processor.processRequest(routing);
      
      // 4. Generate comprehensive response
      final response = await _generateComprehensiveResponse(
        query: query,
        language: language,
        routing: routing,
        result: result,
      );
      
      return response;
      
    } catch (e) {
      _logger.error('❌ Error processing query: $e');
      final language = _detectLanguage(query);
      return ChatResponse(
        answer: language == 'zh' ? '抱歉，处理您的请求时遇到了错误。' : 'Sorry, I encountered an error processing your request.',
        confidence: 0.0,
        language: language,
        processingPath: ProcessingPath.retrieval,
        error: e.toString(),
      );
    }
  }

  /// Generate a comprehensive response based on processing results
  Future<ChatResponse> _generateComprehensiveResponse({
    required String query,
    required String language,
    required RequestRouting routing,
    required ProcessingResult result,
  }) async {
    final buffer = StringBuffer();
    
    // Add result-specific content
    if (result is CalculationResult) {
      buffer.write(await _formatCalculationResponse(result, language, query));
    } else if (result is RetrievalResult) {
      buffer.write(await _formatRetrievalResponse(result, language, query));
    } else if (result is HybridResult) {
      buffer.write(await _formatHybridResponse(result, language, query));
    }
    
    // Add contextual insights if available
    final insights = await _generateContextualInsights(query, result, language);
    if (insights.isNotEmpty) {
      buffer.write('\n\n');
      buffer.write(insights);
    }
    
    // Add follow-up suggestions
    final suggestions = _generateFollowUpSuggestions(query, result, language);
    if (suggestions.isNotEmpty) {
      buffer.write('\n\n');
      buffer.write(suggestions);
    }
    
    return ChatResponse(
      answer: buffer.toString(),
      confidence: result.confidence,
      language: language,
      processingPath: routing.processingPath,
      processingTime: result.processingTime,
      sources: _extractSources(result),
      metadata: {
        'routing_confidence': routing.confidence,
        'hybrid_processing': routing.hybrid,
        'data_points': _getDataPointCount(result),
      },
    );
  }

  /// Format calculation result into user-friendly text with data quality analysis
  Future<String> _formatCalculationResponse(
    CalculationResult result,
    String language,
    String query,
  ) async {
    // Check if this is an enhanced result with AI explanation
    if (result is EnhancedCalculationResult) {
      // Use the built-in formatting that includes the AI explanation
      return result.toResponseText();
    }
    
    final buffer = StringBuffer();
    
    // Analyze data quality issues
    final dataQualityIssues = _analyzeDataQualityIssues(result.dataPoints);
    final hasDataIssues = dataQualityIssues.isNotEmpty;
    
    if (language == 'zh') {
      // Data Quality Warning (if issues exist)
      if (hasDataIssues) {
        buffer.writeln('⚠️ **数据质量提醒**');
        buffer.writeln('');
        
        final zeroAmountCount = dataQualityIssues.where((d) => d.contains('0.00')).length;
        final missingDataCount = dataQualityIssues.where((d) => d.contains('No amount')).length;
        
        if (zeroAmountCount > 0) {
          buffer.writeln('发现 $zeroAmountCount 条记录金额为0，这可能影响分析准确性。');
        }
        if (missingDataCount > 0) {
          buffer.writeln('发现 $missingDataCount 条记录缺少金额信息。');
        }
        
        buffer.writeln('');
        buffer.writeln('📊 **基于现有数据的分析**');
      } else {
        buffer.writeln('📊 **数据分析结果**');
      }
      
      if (result.calculations.isNotEmpty) {
        final main = result.calculations.entries.first;
        if (main.key == 'Total') {
          if (hasDataIssues) {
            buffer.writeln('当前可计算总计: ¥${main.value.toStringAsFixed(2)}');
            buffer.writeln('⚠️ 注意：此金额可能不完整，因为部分记录缺少金额信息');
          } else {
            buffer.writeln('总计: ¥${main.value.toStringAsFixed(2)}');
          }
        } else if (main.key == 'Average') {
          buffer.writeln('平均值: ¥${main.value.toStringAsFixed(2)}');
        } else if (main.key == 'Count') {
          buffer.writeln('数量: ${main.value.toInt()}');
        }
      }
      
      if (result.dataPoints.isNotEmpty) {
        final validRecords = result.dataPoints.where((d) => 
          !d.description.contains('USD 0.00') && 
          !d.description.contains('No amount')).length;
        
        buffer.writeln('总记录数: ${result.dataPoints.length}条');
        if (hasDataIssues) {
          buffer.writeln('有效记录数: $validRecords条');
        }
        
        // Show detailed analysis
        buffer.writeln('\n**详细分析:**');
        final problemRecords = result.dataPoints.where((d) => 
          d.description.contains('USD 0.00') || 
          d.description.contains('No amount')).length;
        
        if (problemRecords > 0) {
          buffer.writeln('• 需要补充信息的记录: $problemRecords条');
          buffer.writeln('• 数据完整性: ${((validRecords / result.dataPoints.length) * 100).toStringAsFixed(1)}%');
        }
        
        // Show sample valid records
        final validSamples = result.dataPoints
          .where((d) => !d.description.contains('USD 0.00') && !d.description.contains('No amount'))
          .take(3);
        
        if (validSamples.isNotEmpty) {
          buffer.writeln('\n**有效记录示例:**');
          for (final item in validSamples) {
            buffer.writeln('• ${item.description}');
          }
        }
        
        // Add improvement recommendations
        if (hasDataIssues) {
          buffer.writeln('\n💡 **改进建议:**');
          buffer.writeln('1. 请检查并补充缺失的金额信息');
          buffer.writeln('2. 确认零金额记录是否为实际免费项目');
          buffer.writeln('3. 完善数据后可获得更准确的分析结果');
          buffer.writeln('');
          buffer.writeln('📝 **后续您可以询问:**');
          buffer.writeln('• "帮我检查哪些记录需要补充金额"');
          buffer.writeln('• "我的支出按分类统计是怎样的？"');
          buffer.writeln('• "给我一些节省开支的建议"');
        }
      }
    } else {
      // English version with similar structure
      if (hasDataIssues) {
        buffer.writeln('⚠️ **Data Quality Notice**');
        buffer.writeln('');
        
        final zeroAmountCount = dataQualityIssues.where((d) => d.contains('0.00')).length;
        final missingDataCount = dataQualityIssues.where((d) => d.contains('No amount')).length;
        
        if (zeroAmountCount > 0) {
          buffer.writeln('Found $zeroAmountCount records with zero amounts, which may affect analysis accuracy.');
        }
        if (missingDataCount > 0) {
          buffer.writeln('Found $missingDataCount records missing amount information.');
        }
        
        buffer.writeln('');
        buffer.writeln('📊 **Analysis Based on Available Data**');
      } else {
        buffer.writeln('📊 **Data Analysis**');
      }
      
      if (result.calculations.isNotEmpty) {
        final main = result.calculations.entries.first;
        if (main.key == 'Total') {
          if (hasDataIssues) {
            buffer.writeln('Calculable total: ¥${main.value.toStringAsFixed(2)}');
            buffer.writeln('⚠️ Note: This amount may be incomplete due to missing data');
          } else {
            buffer.writeln('Total: ¥${main.value.toStringAsFixed(2)}');
          }
        } else if (main.key == 'Average') {
          buffer.writeln('Average: ¥${main.value.toStringAsFixed(2)}');
        } else if (main.key == 'Count') {
          buffer.writeln('Count: ${main.value.toInt()}');
        }
      }
      
      if (result.dataPoints.isNotEmpty) {
        final validRecords = result.dataPoints.where((d) => 
          !d.description.contains('USD 0.00') && 
          !d.description.contains('No amount')).length;
        
        buffer.writeln('Total records: ${result.dataPoints.length}');
        if (hasDataIssues) {
          buffer.writeln('Valid records: $validRecords');
          buffer.writeln('Data completeness: ${((validRecords / result.dataPoints.length) * 100).toStringAsFixed(1)}%');
        }
        
        // Show sample valid records
        final validSamples = result.dataPoints
          .where((d) => !d.description.contains('USD 0.00') && !d.description.contains('No amount'))
          .take(3);
        
        if (validSamples.isNotEmpty) {
          buffer.writeln('\n**Sample Valid Records:**');
          for (final item in validSamples) {
            buffer.writeln('• ${item.description}');
          }
        }
        
        // Add improvement recommendations
        if (hasDataIssues) {
          buffer.writeln('\n💡 **Recommendations:**');
          buffer.writeln('1. Please review and add missing amount information');
          buffer.writeln('2. Confirm if zero-amount records are actually free items');
          buffer.writeln('3. More accurate analysis will be available once data is complete');
          buffer.writeln('');
          buffer.writeln('📝 **You can then ask:**');
          buffer.writeln('• "Help me check which records need amount information"');
          buffer.writeln('• "What are my expenses by category?"');
          buffer.writeln('• "Give me some money-saving suggestions"');
        }
      }
    }
    
    return buffer.toString();
  }
  
  /// Analyze data quality issues in data points
  List<String> _analyzeDataQualityIssues(List<DataPoint> dataPoints) {
    final issues = <String>[];
    
    for (final point in dataPoints) {
      if (point.description.contains('USD 0.00') || 
          point.description.contains('No amount was provided') ||
          point.value == 0.0) {
        issues.add(point.description);
      }
    }
    
    return issues;
  }

  /// Format retrieval result into user-friendly text
  Future<String> _formatRetrievalResponse(
    RetrievalResult result,
    String language,
    String query,
  ) async {
    final buffer = StringBuffer();
    
    // Main response
    buffer.writeln(result.response);
    
    // Add sources if available
    if (result.sources.isNotEmpty) {
      if (language == 'zh') {
        buffer.writeln('\n📚 **参考来源:**');
      } else {
        buffer.writeln('\n📚 **Sources:**');
      }
      
      for (final source in result.sources.take(3)) {
        buffer.writeln('• ${source.title} (${source.type})');
      }
    }
    
    return buffer.toString();
  }

  /// Format hybrid result into user-friendly text
  Future<String> _formatHybridResponse(
    HybridResult result,
    String language,
    String query,
  ) async {
    final buffer = StringBuffer();
    
    // Start with calculation results
    if (result.calculationResult.calculations.isNotEmpty) {
      buffer.write(await _formatCalculationResponse(
        result.calculationResult,
        language,
        query,
      ));
      buffer.writeln();
    }
    
    // Add synthesis/insights
    if (result.synthesis.isNotEmpty) {
      if (language == 'zh') {
        buffer.writeln('\n💡 **深入分析:**');
      } else {
        buffer.writeln('\n💡 **Insights:**');
      }
      buffer.writeln(result.synthesis);
    }
    
    // Add retrieval context if useful
    if (result.retrievalResult.response.isNotEmpty && 
        result.retrievalResult.response != result.synthesis) {
      buffer.writeln();
      buffer.writeln(result.retrievalResult.response);
    }
    
    return buffer.toString();
  }

  /// Generate contextual insights based on data patterns
  Future<String> _generateContextualInsights(
    String query,
    ProcessingResult result,
    String language,
  ) async {
    final insights = <String>[];
    
    if (result is CalculationResult && result.dataPoints.isNotEmpty) {
      // Analyze spending patterns
      if (query.toLowerCase().contains('spend') || query.contains('花')) {
        final categories = <String, double>{};
        for (final point in result.dataPoints) {
          if (point.category != null) {
            categories[point.category!] = (categories[point.category!] ?? 0) + point.value;
          }
        }
        
        if (categories.isNotEmpty) {
          final topCategory = categories.entries.reduce((a, b) => a.value > b.value ? a : b);
          if (language == 'zh') {
            insights.add('💡 您在${topCategory.key}方面的支出最多，占总支出的${(topCategory.value / result.calculations['Total']! * 100).toStringAsFixed(1)}%');
          } else {
            insights.add('💡 Your highest spending is in ${topCategory.key}, accounting for ${(topCategory.value / result.calculations['Total']! * 100).toStringAsFixed(1)}% of total expenses');
          }
        }
      }
      
      // Analyze time patterns
      final recentData = result.dataPoints.where((p) => 
        DateTime.now().difference(p.timestamp).inDays <= 7).length;
      if (recentData > 0) {
        if (language == 'zh') {
          insights.add('📅 最近7天内有$recentData条相关记录');
        } else {
          insights.add('📅 $recentData relevant records in the past 7 days');
        }
      }
    }
    
    return insights.join('\n');
  }

  /// Generate follow-up suggestions
  String _generateFollowUpSuggestions(
    String query,
    ProcessingResult result,
    String language,
  ) {
    final suggestions = <String>[];
    
    if (language == 'zh') {
      suggestions.add('🔍 **您可以继续询问:**');
      
      if (query.contains('花') || query.contains('支出')) {
        suggestions.addAll([
          '• "按类别分析我的支出"',
          '• "这个月比上个月花费如何?"',
          '• "给我一些节约建议"',
        ]);
      } else if (query.contains('收入')) {
        suggestions.addAll([
          '• "我的收支平衡如何?"',
          '• "分析我的财务趋势"',
        ]);
      } else {
        suggestions.addAll([
          '• "本月的财务状况如何?"',
          '• "分析我的生活习惯"',
          '• "给我一些建议"',
        ]);
      }
    } else {
      suggestions.add('🔍 **You can also ask:**');
      
      if (query.toLowerCase().contains('spend') || query.toLowerCase().contains('expense')) {
        suggestions.addAll([
          '• "Analyze my spending by category"',
          '• "How does this month compare to last month?"',
          '• "Give me some saving tips"',
        ]);
      } else if (query.toLowerCase().contains('income')) {
        suggestions.addAll([
          '• "How is my income vs expenses?"',
          '• "Analyze my financial trends"',
        ]);
      } else {
        suggestions.addAll([
          '• "How are my finances this month?"',
          '• "Analyze my lifestyle patterns"',
          '• "Give me some suggestions"',
        ]);
      }
    }
    
    return suggestions.join('\n');
  }

  /// Detect query language (simple heuristic)
  String _detectLanguage(String query) {
    final chineseChars = RegExp(r'[\u4e00-\u9fff]');
    final chineseMatches = chineseChars.allMatches(query).length;
    final totalChars = query.length;
    
    return (chineseMatches / totalChars) > 0.3 ? 'zh' : 'en';
  }

  /// Extract sources from processing result
  List<SourceInfo> _extractSources(ProcessingResult result) {
    if (result is RetrievalResult) {
      return result.sources.map((s) => SourceInfo(
        id: s.id,
        title: s.title,
        type: s.type,
        relevance: s.relevanceScore ?? 0.0,
      )).toList();
    } else if (result is HybridResult) {
      return _extractSources(result.retrievalResult);
    }
    return [];
  }

  /// Get data point count from result
  int _getDataPointCount(ProcessingResult result) {
    if (result is CalculationResult) {
      return result.dataPoints.length;
    } else if (result is HybridResult) {
      return result.calculationResult.dataPoints.length;
    }
    return 0;
  }
}

/// Chat response with comprehensive information
@immutable
class ChatResponse {
  const ChatResponse({
    required this.answer,
    required this.confidence,
    required this.language,
    required this.processingPath,
    this.processingTime,
    this.sources = const [],
    this.metadata = const {},
    this.error,
  });

  final String answer;
  final double confidence;
  final String language;
  final ProcessingPath processingPath;
  final Duration? processingTime;
  final List<SourceInfo> sources;
  final Map<String, dynamic> metadata;
  final String? error;

  bool get hasError => error != null;
  bool get isHighConfidence => confidence > 0.8;
}

/// Source information for citations
@immutable
class SourceInfo {
  const SourceInfo({
    required this.id,
    required this.title,
    required this.type,
    required this.relevance,
  });

  final String id;
  final String title;
  final String type;
  final double relevance;
}
