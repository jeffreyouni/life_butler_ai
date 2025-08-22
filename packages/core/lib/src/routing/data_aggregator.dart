import 'package:meta/meta.dart';
import 'request_processor.dart';
import '../query/query_context.dart';
import 'spending_analysis.dart';

// Core data model interfaces for routing system
// These avoid conflicts with the actual data layer models
abstract class CoreFinanceRecord {
  String get id;
  String get type; // 'income' or 'expense'
  double get amount;
  String? get category;
  String? get notes;
  DateTime get time;
  String? get currency;
}

abstract class CoreMeal {
  String get id;
  String get name;
  DateTime get time;
  int? get caloriesInt;
  String? get location;
}

abstract class CoreEvent {
  String get id;
  String get title;
  DateTime get date;
  String? get description;
  String? get location;
}

abstract class CoreJournal {
  String get id;
  String get contentMd;
  DateTime get createdAt;
  int? get moodInt;
  Map<String, dynamic>? get topicsJson;
}

abstract class CoreHealthMetric {
  String get id;
  String get metricType;
  double get value;
  String get unit;
  DateTime get time;
}

// Core DAO interfaces for routing system
abstract class CoreFinanceRecordDAO {
  Future<List<CoreFinanceRecord>> getAll();
}

abstract class CoreMealDAO {
  Future<List<CoreMeal>> getAll();
}

abstract class CoreEventDAO {
  Future<List<CoreEvent>> getAll();
}

abstract class CoreJournalDAO {
  Future<List<CoreJournal>> getAll();
}

abstract class CoreHealthMetricDAO {
  Future<List<CoreHealthMetric>> getAll();
}

/// Default implementation of data aggregator for calculation operations
class DefaultDataAggregator implements DataAggregator {
  const DefaultDataAggregator({
    required this.financeDao,
    required this.mealDao,
    required this.eventDao,
    required this.journalDao,
    required this.healthDao,
  });

  final CoreFinanceRecordDAO financeDao;
  final CoreMealDAO mealDao;
  final CoreEventDAO eventDao;
  final CoreJournalDAO journalDao;
  final CoreHealthMetricDAO healthDao;

  @override
  Future<AggregationResult> calculateSum({
    Map<String, dynamic>? filters,
    TimeRange? timeRange,
  }) async {
    // Focus on financial data for sum calculations
    final financeRecords = await _getFilteredFinanceRecords(filters, timeRange);
    
    double totalAmount = 0.0;
    final dataPoints = <DataPoint>[];
    
    for (final record in financeRecords) {
      // Only sum expenses by default, unless specified otherwise
      if (record.type == 'expense' || filters?['type'] == 'income') {
        totalAmount += record.amount;
        
        dataPoints.add(DataPoint(
          id: record.id,
          value: record.amount,
          description: '${record.type == 'expense' ? 'Expense' : 'Income'}: ${record.notes ?? 'Unnamed'} - ¥${record.amount.toStringAsFixed(2)}',
          timestamp: record.time,
          category: record.category,
          metadata: {
            'type': record.type,
            'currency': record.currency,
            'category': record.category,
          },
        ));
      }
    }
    
    // Add meal data if requested
    if (filters?['include_meals'] == true) {
      final meals = await _getFilteredMeals(filters, timeRange);
      for (final meal in meals) {
        if (meal.caloriesInt != null) {
          totalAmount += meal.caloriesInt!.toDouble();
          
          dataPoints.add(DataPoint(
            id: meal.id,
            value: meal.caloriesInt!.toDouble(),
            description: 'Meal: ${meal.name} - ${meal.caloriesInt} calories',
            timestamp: meal.time,
            category: 'nutrition',
            metadata: {
              'type': 'calories',
              'location': meal.location,
            },
          ));
        }
      }
    }
    
    return AggregationResult(
      value: totalAmount,
      dataPoints: dataPoints,
      metadata: {
        'aggregation_type': 'sum',
        'currency': 'CNY',
        'record_count': dataPoints.length,
      },
    );
  }

  @override
  Future<AggregationResult> calculateAverage({
    Map<String, dynamic>? filters,
    TimeRange? timeRange,
  }) async {
    final sumResult = await calculateSum(filters: filters, timeRange: timeRange);
    
    if (sumResult.dataPoints.isEmpty) {
      return AggregationResult(
        value: 0.0,
        dataPoints: [],
        metadata: {'aggregation_type': 'average', 'record_count': 0},
      );
    }
    
    final average = sumResult.value / sumResult.dataPoints.length;
    
    return AggregationResult(
      value: average,
      dataPoints: sumResult.dataPoints,
      metadata: {
        'aggregation_type': 'average',
        'total': sumResult.value,
        'record_count': sumResult.dataPoints.length,
      },
    );
  }

  @override
  Future<AggregationResult> calculateCount({
    Map<String, dynamic>? filters,
    TimeRange? timeRange,
  }) async {
    final dataPoints = <DataPoint>[];
    double totalCount = 0;
    
    // Count across different data types based on filters
    final domains = filters?['domains'] as List<String>? ?? [
      'finance', 'meals', 'events', 'journals', 'health'
    ];
    
    for (final domain in domains) {
      switch (domain) {
        case 'finance':
          final records = await _getFilteredFinanceRecords(filters, timeRange);
          totalCount += records.length;
          for (final record in records) {
            dataPoints.add(DataPoint(
              id: record.id,
              value: 1.0,
              description: '${record.type}: ${record.notes ?? 'Unnamed'} - ¥${record.amount.toStringAsFixed(2)}',
              timestamp: record.time,
              category: record.category,
            ));
          }
          break;
          
        case 'meals':
          final meals = await _getFilteredMeals(filters, timeRange);
          totalCount += meals.length;
          for (final meal in meals) {
            dataPoints.add(DataPoint(
              id: meal.id,
              value: 1.0,
              description: 'Meal: ${meal.name}',
              timestamp: meal.time,
              category: 'nutrition',
            ));
          }
          break;
          
        case 'events':
          final events = await _getFilteredEvents(filters, timeRange);
          totalCount += events.length;
          for (final event in events) {
            dataPoints.add(DataPoint(
              id: event.id,
              value: 1.0,
              description: 'Event: ${event.title}',
              timestamp: event.date,
              category: 'event',
            ));
          }
          break;
          
        case 'journals':
          final journals = await _getFilteredJournals(filters, timeRange);
          totalCount += journals.length;
          for (final journal in journals) {
            dataPoints.add(DataPoint(
              id: journal.id,
              value: 1.0,
              description: 'Journal entry',
              timestamp: journal.createdAt,
              category: 'journal',
            ));
          }
          break;
          
        case 'health':
          final healthMetrics = await _getFilteredHealthMetrics(filters, timeRange);
          totalCount += healthMetrics.length;
          for (final metric in healthMetrics) {
            dataPoints.add(DataPoint(
              id: metric.id,
              value: 1.0,
              description: 'Health: ${metric.metricType} - ${metric.value} ${metric.unit}',
              timestamp: metric.time,
              category: 'health',
            ));
          }
          break;
      }
    }
    
    return AggregationResult(
      value: totalCount,
      dataPoints: dataPoints,
      metadata: {
        'aggregation_type': 'count',
        'domains': domains,
        'record_count': totalCount.toInt(),
      },
    );
  }

  /// Calculate spending by category
  Future<Map<String, double>> calculateSpendingByCategory({
    TimeRange? timeRange,
  }) async {
    final financeRecords = await _getFilteredFinanceRecords(
      {'type': 'expense'}, 
      timeRange,
    );
    
    final spendingByCategory = <String, double>{};
    
    for (final record in financeRecords) {
      final category = record.category ?? 'other';
      spendingByCategory[category] = (spendingByCategory[category] ?? 0) + record.amount;
    }
    
    return spendingByCategory;
  }

  /// Calculate daily averages
  Future<Map<String, double>> calculateDailyAverages({
    TimeRange? timeRange,
  }) async {
    final results = <String, double>{};
    
    // Calculate daily spending average
    final financeRecords = await _getFilteredFinanceRecords(
      {'type': 'expense'}, 
      timeRange,
    );
    
    if (financeRecords.isNotEmpty) {
      final totalSpending = financeRecords.fold<double>(0, (sum, r) => sum + r.amount);
      final dayCount = _calculateDayCount(financeRecords.map((r) => r.time).toList());
      results['daily_spending'] = totalSpending / dayCount;
    }
    
    // Calculate daily calories average
    final meals = await _getFilteredMeals({}, timeRange);
    final mealsWithCalories = meals.where((m) => m.caloriesInt != null).toList();
    
    if (mealsWithCalories.isNotEmpty) {
      final totalCalories = mealsWithCalories.fold<int>(0, (sum, m) => sum + m.caloriesInt!);
      final dayCount = _calculateDayCount(mealsWithCalories.map((m) => m.time).toList());
      results['daily_calories'] = totalCalories / dayCount;
    }
    
    return results;
  }

  /// Calculate trends over time
  Future<List<TrendPoint>> calculateTrends({
    required String metric,
    required String period, // 'daily', 'weekly', 'monthly'
    TimeRange? timeRange,
  }) async {
    final trendPoints = <TrendPoint>[];
    
    switch (metric) {
      case 'spending':
        final records = await _getFilteredFinanceRecords({'type': 'expense'}, timeRange);
        final grouped = _groupByPeriod(
          records.map((r) => (r.time, r.amount)).toList(),
          period,
        );
        
        for (final entry in grouped.entries) {
          trendPoints.add(TrendPoint(
            period: entry.key,
            value: entry.value.fold<double>(0, (sum, amount) => sum + amount),
            count: entry.value.length,
          ));
        }
        break;
        
      case 'meals':
        final meals = await _getFilteredMeals({}, timeRange);
        final grouped = _groupByPeriod(
          meals.map((m) => (m.time, 1.0)).toList(),
          period,
        );
        
        for (final entry in grouped.entries) {
          trendPoints.add(TrendPoint(
            period: entry.key,
            value: entry.value.length.toDouble(),
            count: entry.value.length,
          ));
        }
        break;
    }
    
    return trendPoints..sort((a, b) => a.period.compareTo(b.period));
  }

  // Helper methods for filtering data

  Future<List<CoreFinanceRecord>> _getFilteredFinanceRecords(
    Map<String, dynamic>? filters,
    TimeRange? timeRange,
  ) async {
    // This would use the actual DAO methods with proper filtering
    // For now, return all records and filter in memory
    final allRecords = await financeDao.getAll();
    
    return allRecords.where((record) {
      // Time range filter
      if (timeRange != null && timeRange.start != null && timeRange.end != null) {
        if (record.time.isBefore(timeRange.start!) || record.time.isAfter(timeRange.end!)) {
          return false;
        }
      }
      
      // Type filter
      if (filters?['type'] != null && record.type != filters!['type']) {
        return false;
      }
      
      // Category filter
      if (filters?['category'] != null && record.category != filters!['category']) {
        return false;
      }
      
      return true;
    }).toList();
  }

  Future<List<CoreMeal>> _getFilteredMeals(
    Map<String, dynamic>? filters,
    TimeRange? timeRange,
  ) async {
    final allMeals = await mealDao.getAll();
    
    return allMeals.where((meal) {
      if (timeRange != null && timeRange.start != null && timeRange.end != null) {
        if (meal.time.isBefore(timeRange.start!) || meal.time.isAfter(timeRange.end!)) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  Future<List<CoreEvent>> _getFilteredEvents(
    Map<String, dynamic>? filters,
    TimeRange? timeRange,
  ) async {
    final allEvents = await eventDao.getAll();
    
    return allEvents.where((event) {
      if (timeRange != null && timeRange.start != null && timeRange.end != null) {
        if (event.date.isBefore(timeRange.start!) || event.date.isAfter(timeRange.end!)) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  Future<List<CoreJournal>> _getFilteredJournals(
    Map<String, dynamic>? filters,
    TimeRange? timeRange,
  ) async {
    final allJournals = await journalDao.getAll();
    
    return allJournals.where((journal) {
      if (timeRange != null && timeRange.start != null && timeRange.end != null) {
        if (journal.createdAt.isBefore(timeRange.start!) || journal.createdAt.isAfter(timeRange.end!)) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  Future<List<CoreHealthMetric>> _getFilteredHealthMetrics(
    Map<String, dynamic>? filters,
    TimeRange? timeRange,
  ) async {
    final allMetrics = await healthDao.getAll();
    
    return allMetrics.where((metric) {
      if (timeRange != null && timeRange.start != null && timeRange.end != null) {
        if (metric.time.isBefore(timeRange.start!) || metric.time.isAfter(timeRange.end!)) {
          return false;
        }
      }
      
      // Metric type filter
      if (filters?['metric_type'] != null && metric.metricType != filters!['metric_type']) {
        return false;
      }
      
      return true;
    }).toList();
  }

  // Helper utility methods

  int _calculateDayCount(List<DateTime> dates) {
    if (dates.isEmpty) return 1;
    
    final sortedDates = dates.toList()..sort();
    final startDate = DateTime(sortedDates.first.year, sortedDates.first.month, sortedDates.first.day);
    final endDate = DateTime(sortedDates.last.year, sortedDates.last.month, sortedDates.last.day);
    
    return endDate.difference(startDate).inDays + 1;
  }

  Map<DateTime, List<double>> _groupByPeriod(
    List<(DateTime, double)> data,
    String period,
  ) {
    final grouped = <DateTime, List<double>>{};
    
    for (final (date, value) in data) {
      DateTime periodKey;
      
      switch (period) {
        case 'daily':
          periodKey = DateTime(date.year, date.month, date.day);
          break;
        case 'weekly':
          final weekStart = date.subtract(Duration(days: date.weekday - 1));
          periodKey = DateTime(weekStart.year, weekStart.month, weekStart.day);
          break;
        case 'monthly':
          periodKey = DateTime(date.year, date.month);
          break;
        default:
          periodKey = DateTime(date.year, date.month, date.day);
      }
      
      grouped.putIfAbsent(periodKey, () => []).add(value);
    }
    
    return grouped;
  }
}

/// Trend point for time series analysis
@immutable
class TrendPoint {
  const TrendPoint({
    required this.period,
    required this.value,
    required this.count,
  });

  final DateTime period;
  final double value;
  final int count;
}

/// Extended aggregation operations for specific use cases
extension AggregationExtensions on DefaultDataAggregator {
  
  /// Calculate comprehensive spending analysis
  Future<SpendingAnalysis> analyzeSpending({TimeRange? timeRange}) async {
    final totalResult = await calculateSum(
      filters: {'type': 'expense'},
      timeRange: timeRange,
    );
    
    final avgResult = await calculateAverage(
      filters: {'type': 'expense'}, 
      timeRange: timeRange,
    );
    
    final categoryBreakdown = await calculateSpendingByCategory(timeRange: timeRange);
    final dailyAverages = await calculateDailyAverages(timeRange: timeRange);
    
    return SpendingAnalysis(
      totalSpent: totalResult.value,
      averagePerTransaction: avgResult.value,
      dailyAverage: dailyAverages['daily_spending'] ?? 0.0,
      categoryBreakdown: categoryBreakdown,
      transactionCount: totalResult.dataPoints.length,
      timeRange: timeRange,
    );
  }

  /// Calculate comprehensive nutrition analysis
  Future<NutritionAnalysis> analyzeNutrition({TimeRange? timeRange}) async {
    final mealCountResult = await calculateCount(
      filters: {'domains': ['meals']},
      timeRange: timeRange,
    );
    
    final calorieResult = await calculateSum(
      filters: {'include_meals': true},
      timeRange: timeRange,
    );
    
    final dailyAverages = await calculateDailyAverages(timeRange: timeRange);
    
    return NutritionAnalysis(
      totalMeals: mealCountResult.value.toInt(),
      totalCalories: calorieResult.value.toInt(),
      dailyCalorieAverage: dailyAverages['daily_calories'] ?? 0.0,
      timeRange: timeRange,
    );
  }
}

/// Comprehensive nutrition analysis result
@immutable
class NutritionAnalysis {
  const NutritionAnalysis({
    required this.totalMeals,
    required this.totalCalories,
    required this.dailyCalorieAverage,
    this.timeRange,
  });

  final int totalMeals;
  final int totalCalories;
  final double dailyCalorieAverage;
  final TimeRange? timeRange;

  String toSummaryText() {
    final buffer = StringBuffer();
    buffer.writeln('🍽️ **Nutrition Analysis**');
    buffer.writeln('• Total meals: $totalMeals');
    buffer.writeln('• Total calories: $totalCalories kcal');
    buffer.writeln('• Daily average: ${dailyCalorieAverage.toStringAsFixed(0)} kcal');
    
    return buffer.toString();
  }
}
