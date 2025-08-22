import 'query_context.dart';

/// Query planner that analyzes queries and determines search strategy
abstract class QueryPlanner {
  /// Analyze a query and create execution context
  QueryContext planQuery(String query);

  /// Determine which domains are relevant for the query
  List<String> identifyTargetDomains(String query);

  /// Extract time range information from query
  TimeRange? extractTimeRange(String query);

  /// Identify the user's intent
  QueryIntent identifyIntent(String query);

  /// Extract keywords for filtering
  List<String> extractKeywords(String query);
}

/// Default implementation of query planner
class DefaultQueryPlanner implements QueryPlanner {
  const DefaultQueryPlanner();

  @override
  QueryContext planQuery(String query) {
    final intent = identifyIntent(query);
    final domains = identifyTargetDomains(query);
    final timeRange = extractTimeRange(query);
    final keywords = extractKeywords(query);
    final filters = _extractFilters(query);

    return QueryContext(
      originalQuery: query,
      intent: intent,
      targetDomains: domains,
      timeRange: timeRange,
      keywords: keywords,
      filters: filters,
    );
  }

  @override
  List<String> identifyTargetDomains(String query) {
    final queryLower = query.toLowerCase();
    final domains = <String>[];

    // Domain keyword mappings
    final domainKeywords = {
      'events': ['event', 'happened', 'occurred', 'celebration', 'meeting'],
      'education': ['school', 'university', 'degree', 'course', 'study', 'learn', 'education'],
      'career': ['work', 'job', 'career', 'company', 'project', 'achievement'],
      'meals': ['eat', 'food', 'meal', 'breakfast', 'lunch', 'dinner', 'restaurant', 'cooking'],
      'journals': ['journal', 'diary', 'thought', 'reflection', 'mood', 'feeling'],
      'health_metrics': ['health', 'weight', 'exercise', 'sleep', 'fitness', 'wellness'],
      'finance_records': ['money', 'spend', 'cost', 'expense', 'income', 'budget', 'financial'],
      'tasks_habits': ['task', 'habit', 'routine', 'goal', 'todo', 'productivity'],
      'relations': ['friend', 'family', 'relationship', 'social', 'people', 'contact'],
      'media_logs': ['read', 'watch', 'movie', 'book', 'music', 'podcast', 'media'],
      'travel_logs': ['travel', 'trip', 'vacation', 'visit', 'journey', 'destination'],
    };

    for (final entry in domainKeywords.entries) {
      if (entry.value.any((keyword) => queryLower.contains(keyword))) {
        domains.add(entry.key);
      }
    }

    // If no specific domains identified, include all for broad search
    if (domains.isEmpty) {
      domains.addAll(domainKeywords.keys);
    }

    return domains;
  }

  @override
  TimeRange? extractTimeRange(String query) {
    final queryLower = query.toLowerCase();

    // Exact period matches
    if (queryLower.contains('today')) {
      return TimeRange.period(TimePeriod.today);
    }
    if (queryLower.contains('this week')) {
      return TimeRange.period(TimePeriod.thisWeek);
    }
    if (queryLower.contains('last week')) {
      return TimeRange.period(TimePeriod.lastWeek);
    }
    if (queryLower.contains('this month')) {
      return TimeRange.period(TimePeriod.thisMonth);
    }
    if (queryLower.contains('last month')) {
      return TimeRange.period(TimePeriod.lastMonth);
    }
    if (queryLower.contains('this year')) {
      return TimeRange.period(TimePeriod.thisYear);
    }
    if (queryLower.contains('last year')) {
      return TimeRange.period(TimePeriod.lastYear);
    }

    // Year-specific queries
    final yearMatch = RegExp(r'(?:in |during |year )?(\d{4})').firstMatch(queryLower);
    if (yearMatch != null) {
      final year = int.parse(yearMatch.group(1)!);
      return TimeRange.custom(
        DateTime(year, 1, 1),
        DateTime(year + 1, 1, 1),
      );
    }

    // Recent timeframes
    if (queryLower.contains('recent') || queryLower.contains('lately')) {
      return TimeRange.period(TimePeriod.thisMonth);
    }

    // Relative timeframes
    final daysMatch = RegExp(r'(?:past|last) (\d+) days?').firstMatch(queryLower);
    if (daysMatch != null) {
      final days = int.parse(daysMatch.group(1)!);
      final now = DateTime.now();
      return TimeRange.custom(
        now.subtract(Duration(days: days)),
        now,
      );
    }

    final weeksMatch = RegExp(r'(?:past|last) (\d+) weeks?').firstMatch(queryLower);
    if (weeksMatch != null) {
      final weeks = int.parse(weeksMatch.group(1)!);
      final now = DateTime.now();
      return TimeRange.custom(
        now.subtract(Duration(days: weeks * 7)),
        now,
      );
    }

    return null;
  }

  @override
  QueryIntent identifyIntent(String query) {
    final queryLower = query.toLowerCase();

    // Advice intent keywords
    const adviceKeywords = [
      'how should', 'what should', 'recommend', 'suggest', 'advice',
      'help me', 'plan', 'improve', 'optimize', 'better', 'strategy'
    ];

    // Analysis intent keywords
    const analysisKeywords = [
      'analyze', 'pattern', 'trend', 'correlation', 'relationship',
      'compare', 'difference', 'change', 'over time', 'statistics'
    ];

    // Summary intent keywords
    const summaryKeywords = [
      'summarize', 'summary', 'overview', 'total', 'average',
      'most', 'least', 'top', 'bottom'
    ];

    // Comparison intent keywords
    const comparisonKeywords = [
      'vs', 'versus', 'compared to', 'difference between',
      'better than', 'worse than', 'more than', 'less than'
    ];

    if (adviceKeywords.any((keyword) => queryLower.contains(keyword))) {
      return QueryIntent.advice;
    }

    if (analysisKeywords.any((keyword) => queryLower.contains(keyword))) {
      return QueryIntent.analysis;
    }

    if (comparisonKeywords.any((keyword) => queryLower.contains(keyword))) {
      return QueryIntent.comparison;
    }

    if (summaryKeywords.any((keyword) => queryLower.contains(keyword))) {
      return QueryIntent.summary;
    }

    // Default to search for simple queries
    return QueryIntent.search;
  }

  @override
  List<String> extractKeywords(String query) {
    // Remove common stop words and extract meaningful terms
    final words = query
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), ' ')
        .split(RegExp(r'\s+'))
        .where((word) => word.length > 2)
        .toList();

    const stopWords = {
      'the', 'and', 'or', 'but', 'in', 'on', 'at', 'to', 'for', 'of', 'with',
      'by', 'is', 'are', 'was', 'were', 'be', 'been', 'have', 'has', 'had',
      'do', 'does', 'did', 'will', 'would', 'could', 'should', 'may', 'might',
      'can', 'this', 'that', 'these', 'those', 'what', 'how', 'when', 'where',
      'why', 'who', 'which', 'my', 'me', 'i', 'you', 'your', 'most', 'about'
    };

    return words.where((word) => !stopWords.contains(word)).toList();
  }

  Map<String, dynamic> _extractFilters(String query) {
    final filters = <String, dynamic>{};
    final queryLower = query.toLowerCase();

    // Category filters
    if (queryLower.contains('breakfast')) {
      filters['meal_type'] = 'breakfast';
    }
    if (queryLower.contains('lunch')) {
      filters['meal_type'] = 'lunch';
    }
    if (queryLower.contains('dinner')) {
      filters['meal_type'] = 'dinner';
    }

    // Expense categories
    if (queryLower.contains('外卖') || queryLower.contains('takeout') || queryLower.contains('delivery')) {
      filters['category'] = 'takeout';
    }

    // Health metrics
    if (queryLower.contains('weight')) {
      filters['metric_type'] = 'weight';
    }
    if (queryLower.contains('sleep')) {
      filters['metric_type'] = 'sleep';
    }

    return filters;
  }
}
