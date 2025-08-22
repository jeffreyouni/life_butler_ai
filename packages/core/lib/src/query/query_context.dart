import 'package:meta/meta.dart';

@immutable
class QueryContext {
  const QueryContext({
    required this.originalQuery,
    required this.intent,
    this.targetDomains = const [],
    this.timeRange,
    this.keywords = const [],
    this.filters = const {},
  });

  final String originalQuery;
  final QueryIntent intent;
  final List<String> targetDomains;
  final TimeRange? timeRange;
  final List<String> keywords;
  final Map<String, dynamic> filters;

  /// Whether this is a cross-domain query requiring data fusion
  bool get isCrossDomain => targetDomains.length > 1;

  /// Whether this query is asking for advice/recommendations
  bool get isAdviceQuery => intent == QueryIntent.advice;

  /// Whether this query is asking for analysis/patterns
  bool get isAnalysisQuery => intent == QueryIntent.analysis;
}

enum QueryIntent {
  search,      // Simple information retrieval
  analysis,    // Pattern analysis, trends, correlations
  advice,      // Recommendations and action plans
  summary,     // Summarization of data
  comparison,  // Comparing different time periods or categories
}

@immutable
class TimeRange {
  const TimeRange({
    this.start,
    this.end,
    this.period,
  });

  final DateTime? start;
  final DateTime? end;
  final TimePeriod? period;

  /// Create a time range for a specific period
  factory TimeRange.period(TimePeriod period) {
    final now = DateTime.now();
    DateTime start;

    switch (period) {
      case TimePeriod.today:
        start = DateTime(now.year, now.month, now.day);
        break;
      case TimePeriod.thisWeek:
        start = now.subtract(Duration(days: now.weekday - 1));
        start = DateTime(start.year, start.month, start.day);
        break;
      case TimePeriod.lastWeek:
        final lastWeekStart = now.subtract(Duration(days: now.weekday + 6));
        start = DateTime(lastWeekStart.year, lastWeekStart.month, lastWeekStart.day);
        break;
      case TimePeriod.thisMonth:
        start = DateTime(now.year, now.month, 1);
        break;
      case TimePeriod.lastMonth:
        final lastMonth = DateTime(now.year, now.month - 1, 1);
        start = lastMonth;
        break;
      case TimePeriod.thisYear:
        start = DateTime(now.year, 1, 1);
        break;
      case TimePeriod.lastYear:
        start = DateTime(now.year - 1, 1, 1);
        break;
    }

    return TimeRange(start: start, period: period);
  }

  /// Create a custom time range
  factory TimeRange.custom(DateTime start, DateTime end) {
    return TimeRange(start: start, end: end);
  }

  /// Get the end date for period-based ranges
  DateTime? get effectiveEnd {
    if (end != null) return end;
    if (period == null || start == null) return null;

    switch (period!) {
      case TimePeriod.today:
        return start!.add(const Duration(days: 1));
      case TimePeriod.thisWeek:
      case TimePeriod.lastWeek:
        return start!.add(const Duration(days: 7));
      case TimePeriod.thisMonth:
      case TimePeriod.lastMonth:
        return DateTime(start!.year, start!.month + 1, 1);
      case TimePeriod.thisYear:
      case TimePeriod.lastYear:
        return DateTime(start!.year + 1, 1, 1);
    }
  }

  /// Get a human-readable description of the time range
  String get description {
    if (period != null) {
      switch (period!) {
        case TimePeriod.today:
          return 'today';
        case TimePeriod.thisWeek:
          return 'this week';
        case TimePeriod.lastWeek:
          return 'last week';
        case TimePeriod.thisMonth:
          return 'this month';
        case TimePeriod.lastMonth:
          return 'last month';
        case TimePeriod.thisYear:
          return 'this year';
        case TimePeriod.lastYear:
          return 'last year';
      }
    }

    if (start != null && end != null) {
      return 'from ${start!.toIso8601String().split('T')[0]} to ${end!.toIso8601String().split('T')[0]}';
    }

    if (start != null) {
      return 'since ${start!.toIso8601String().split('T')[0]}';
    }

    return 'all time';
  }
}

enum TimePeriod {
  today,
  thisWeek,
  lastWeek,
  thisMonth,
  lastMonth,
  thisYear,
  lastYear,
}
