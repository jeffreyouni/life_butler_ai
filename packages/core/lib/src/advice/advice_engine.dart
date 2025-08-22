import 'package:meta/meta.dart';
import '../rag/rag_pipeline.dart';
import 'advice_result.dart';
import 'safety_checker.dart';

/// Main advice engine interface
abstract class AdviceEngine {
  /// Generate advice based on query and retrieved context
  Future<AdviceResult> generateAdvice(
    String query,
    RagContext context, {
    Map<String, dynamic>? userPreferences,
    AdviceStyle style = AdviceStyle.balanced,
  });

  /// Analyze query to determine advice category and scope
  AdviceCategory categorizeQuery(String query);

  /// Extract actionable insights from context
  List<ActionableInsight> extractInsights(RagContext context);
}

/// Advice generation styles
enum AdviceStyle {
  conservative,  // Safe, cautious recommendations
  balanced,      // Moderate recommendations
  aggressive,    // Bold, ambitious recommendations
  datadriven,    // Heavily based on quantitative analysis
  concise,       // Brief, to-the-point advice
}

/// Actionable insights extracted from data
@immutable
class ActionableInsight {
  const ActionableInsight({
    required this.type,
    required this.description,
    required this.evidence,
    required this.confidence,
    this.suggestedAction,
    this.impact,
  });

  final InsightType type;
  final String description;
  final String evidence;
  final double confidence;
  final String? suggestedAction;
  final InsightImpact? impact;
}

enum InsightType {
  pattern,      // Recurring patterns in behavior
  trend,        // Trending changes over time
  correlation,  // Relationships between different metrics
  anomaly,      // Unusual events or outliers
  opportunity,  // Areas for improvement
  risk,         // Potential problems or concerns
}

enum InsightImpact {
  low,
  medium,
  high,
  critical,
}

/// Default advice engine implementation
class DefaultAdviceEngine implements AdviceEngine {
  const DefaultAdviceEngine();

  @override
  Future<AdviceResult> generateAdvice(
    String query,
    RagContext context, {
    Map<String, dynamic>? userPreferences,
    AdviceStyle style = AdviceStyle.balanced,
  }) async {
    // Analyze safety considerations
    final safetyResult = SafetyChecker.checkSafety(
      query,
      context.formatForPrompt(),
    );

    // Categorize the query
    final category = categorizeQuery(query);

    // Extract insights
    final insights = extractInsights(context);

    // Generate action items based on insights
    final actionItems = _generateActionItems(insights, style);

    // Calculate confidence based on data quality and relevance
    final confidence = _calculateConfidence(context, insights);

    // Generate main advice text
    final advice = _generateAdviceText(query, context, insights, style);

    // Generate reasoning
    final reasoning = _generateReasoning(insights, context);

    return AdviceResult(
      query: query,
      advice: advice,
      reasoning: reasoning,
      citations: context.citations,
      actionItems: actionItems,
      safetyResult: safetyResult,
      confidence: confidence,
      timeframe: _determineTimeframe(actionItems),
    );
  }

  @override
  AdviceCategory categorizeQuery(String query) {
    final queryLower = query.toLowerCase();

    if (_containsHealthTerms(queryLower)) return AdviceCategory.health;
    if (_containsFinanceTerms(queryLower)) return AdviceCategory.finance;
    if (_containsProductivityTerms(queryLower)) return AdviceCategory.productivity;
    if (_containsRelationshipTerms(queryLower)) return AdviceCategory.relationships;
    if (_containsLearningTerms(queryLower)) return AdviceCategory.learning;
    if (_containsLifestyleTerms(queryLower)) return AdviceCategory.lifestyle;

    return AdviceCategory.general;
  }

  @override
  List<ActionableInsight> extractInsights(RagContext context) {
    final insights = <ActionableInsight>[];

    // This is a simplified implementation
    // In a real system, this would use more sophisticated analysis

    for (final result in context.results) {
      final content = result.text.toLowerCase();

      // Look for patterns
      if (content.contains('every day') || content.contains('daily')) {
        insights.add(ActionableInsight(
          type: InsightType.pattern,
          description: 'Daily routine identified',
          evidence: result.text,
          confidence: 0.7,
          suggestedAction: 'Consider optimizing daily routines',
        ));
      }

      // Look for trends
      if (content.contains('increased') || content.contains('decreased')) {
        insights.add(ActionableInsight(
          type: InsightType.trend,
          description: 'Change trend detected',
          evidence: result.text,
          confidence: 0.6,
          suggestedAction: 'Monitor and adjust based on trend',
        ));
      }

      // Look for opportunities
      if (content.contains('could') || content.contains('should')) {
        insights.add(ActionableInsight(
          type: InsightType.opportunity,
          description: 'Improvement opportunity',
          evidence: result.text,
          confidence: 0.5,
          suggestedAction: 'Take action on identified opportunity',
        ));
      }
    }

    return insights;
  }

  List<ActionItem> _generateActionItems(
    List<ActionableInsight> insights,
    AdviceStyle style,
  ) {
    final items = <ActionItem>[];

    for (final insight in insights) {
      if (insight.suggestedAction != null) {
        final priority = _determinePriority(insight, style);
        final timeframe = _determineTimeframeForInsight(insight, style);

        items.add(ActionItem(
          title: insight.suggestedAction!,
          description: insight.description,
          priority: priority,
          timeframe: timeframe,
          category: insight.type.name,
        ));
      }
    }

    // Limit to most important items
    items.sort((a, b) => (b.priority?.index ?? 0) - (a.priority?.index ?? 0));
    return items.take(5).toList();
  }

  ActionPriority _determinePriority(ActionableInsight insight, AdviceStyle style) {
    switch (insight.impact) {
      case InsightImpact.critical:
        return ActionPriority.urgent;
      case InsightImpact.high:
        return ActionPriority.high;
      case InsightImpact.medium:
        return ActionPriority.medium;
      case InsightImpact.low:
      case null:
        return ActionPriority.low;
    }
  }

  String? _determineTimeframeForInsight(ActionableInsight insight, AdviceStyle style) {
    switch (insight.type) {
      case InsightType.risk:
        return 'Immediate';
      case InsightType.opportunity:
        return style == AdviceStyle.aggressive ? 'This week' : 'This month';
      case InsightType.pattern:
        return 'Ongoing';
      default:
        return 'Within 2 weeks';
    }
  }

  double _calculateConfidence(RagContext context, List<ActionableInsight> insights) {
    if (context.results.isEmpty) return 0.1;

    final avgScore = context.results
        .map((r) => r.similarity)
        .reduce((a, b) => a + b) / context.results.length;

    final insightConfidence = insights.isEmpty
        ? 0.5
        : insights.map((i) => i.confidence).reduce((a, b) => a + b) / insights.length;

    return (avgScore * 0.6 + insightConfidence * 0.4).clamp(0.0, 1.0);
  }

  String _generateAdviceText(
    String query,
    RagContext context,
    List<ActionableInsight> insights,
    AdviceStyle style,
  ) {
    if (context.results.isEmpty) {
      return 'I don\'t have enough relevant information to provide specific advice for this query. '
          'Consider adding more data related to your question.';
    }

    final buffer = StringBuffer();
    buffer.writeln('Based on your personal data, here\'s my analysis:');
    buffer.writeln();

    if (insights.isNotEmpty) {
      final topInsights = insights.take(3);
      for (final insight in topInsights) {
        buffer.writeln('• ${insight.description}');
      }
      buffer.writeln();
    }

    // Add style-specific advice tone
    switch (style) {
      case AdviceStyle.conservative:
        buffer.writeln('I recommend taking a cautious, step-by-step approach:');
        break;
      case AdviceStyle.aggressive:
        buffer.writeln('Here\'s a bold plan to maximize your results:');
        break;
      case AdviceStyle.datadriven:
        buffer.writeln('The data suggests the following evidence-based recommendations:');
        break;
      case AdviceStyle.concise:
        buffer.writeln('Key recommendations:');
        break;
      case AdviceStyle.balanced:
        buffer.writeln('Here\'s a balanced approach based on your data:');
        break;
    }

    return buffer.toString().trim();
  }

  String _generateReasoning(List<ActionableInsight> insights, RagContext context) {
    if (insights.isEmpty) return '';

    final buffer = StringBuffer();
    buffer.writeln('This advice is based on the following analysis of your data:');
    buffer.writeln();

    for (final insight in insights.take(3)) {
      buffer.writeln('**${insight.type.name.toUpperCase()}**: ${insight.description}');
      buffer.writeln('Evidence: ${insight.evidence}');
      buffer.writeln('Confidence: ${(insight.confidence * 100).toStringAsFixed(0)}%');
      buffer.writeln();
    }

    return buffer.toString().trim();
  }

  String? _determineTimeframe(List<ActionItem> actionItems) {
    if (actionItems.isEmpty) return null;

    final hasUrgent = actionItems.any((item) => item.priority == ActionPriority.urgent);
    if (hasUrgent) return 'Immediate action required';

    final hasHigh = actionItems.any((item) => item.priority == ActionPriority.high);
    if (hasHigh) return 'Within 1 week';

    return 'Within 2-4 weeks';
  }

  // Helper methods for categorization
  bool _containsHealthTerms(String query) {
    const terms = ['health', 'weight', 'exercise', 'sleep', 'diet', 'fitness', 'wellness'];
    return terms.any((term) => query.contains(term));
  }

  bool _containsFinanceTerms(String query) {
    const terms = ['money', 'spend', 'cost', 'budget', 'income', 'expense', 'financial'];
    return terms.any((term) => query.contains(term));
  }

  bool _containsProductivityTerms(String query) {
    const terms = ['productive', 'work', 'task', 'habit', 'goal', 'time', 'efficiency'];
    return terms.any((term) => query.contains(term));
  }

  bool _containsRelationshipTerms(String query) {
    const terms = ['relationship', 'friend', 'family', 'social', 'people', 'communication'];
    return terms.any((term) => query.contains(term));
  }

  bool _containsLearningTerms(String query) {
    const terms = ['learn', 'study', 'education', 'skill', 'knowledge', 'course', 'book'];
    return terms.any((term) => query.contains(term));
  }

  bool _containsLifestyleTerms(String query) {
    const terms = ['lifestyle', 'routine', 'habit', 'balance', 'hobby', 'leisure'];
    return terms.any((term) => query.contains(term));
  }
}
