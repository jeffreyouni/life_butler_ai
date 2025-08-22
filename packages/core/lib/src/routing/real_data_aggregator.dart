import 'package:meta/meta.dart';
import 'package:data/data.dart';
import 'package:drift/drift.dart';
import 'request_processor.dart';
import '../query/query_context.dart';
import 'data_aggregator.dart';
import 'spending_analysis.dart';
import '../utils/logger.dart';

/// Real data aggregator that connects to the actual database
class RealDataAggregator implements DataAggregator {
  static final _logger = Logger('RealDataAggregator');
  
  const RealDataAggregator({
    required this.database,
  });

  final LifeButlerDatabase database;

  @override
  Future<AggregationResult> calculateSum({
    Map<String, dynamic>? filters,
    TimeRange? timeRange,
  }) async {
    double totalAmount = 0.0;
    final dataPoints = <DataPoint>[];

    try {
      // Get finance records from the actual database
      final financeRecords = await _getFilteredFinanceRecords(filters, timeRange);
      
      for (final record in financeRecords) {
        totalAmount += record.amount;
        
        dataPoints.add(DataPoint(
          id: record.id,
          value: record.amount,
          description: '${_getTransactionTypeLabel(record.type)}: ${record.notes ?? 'Unnamed'} - ${record.currency ?? '¥'}${record.amount.toStringAsFixed(2)}',
          timestamp: record.time,
          category: record.category,
          metadata: {
            'type': record.type,
            'currency': record.currency,
            'category': record.category,
          },
        ));
      }

      // Include meal data if requested
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
          'record_count': dataPoints.length,
          'time_range': _formatTimeRange(timeRange),
          'filters_applied': filters?.keys.toList() ?? [],
        },
      );
    } catch (e) {
      _logger.error('❌ Error in calculateSum: $e');
      return AggregationResult(
        value: 0.0,
        dataPoints: [],
        metadata: {
          'error': e.toString(),
          'aggregation_type': 'sum',
        },
      );
    }
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
        metadata: {
          'aggregation_type': 'average',
          'record_count': 0,
        },
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
        'time_range': _formatTimeRange(timeRange),
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

    try {
      // Determine which domains to count
      final domains = filters?['domains'] as List<String>? ?? ['finance'];

      for (final domain in domains) {
        switch (domain) {
          case 'finance':
            final records = await _getFilteredFinanceRecords(filters, timeRange);
            totalCount += records.length;
            for (final record in records) {
              dataPoints.add(DataPoint(
                id: record.id,
                value: 1.0,
                description: '${_getTransactionTypeLabel(record.type)}: ${record.notes ?? 'Unnamed'} - ${record.currency ?? '¥'}${record.amount.toStringAsFixed(2)}',
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
                category: 'schedule',
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
                category: 'thoughts',
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
          'time_range': _formatTimeRange(timeRange),
        },
      );
    } catch (e) {
      _logger.error('❌ Error in calculateCount: $e');
      return AggregationResult(
        value: 0.0,
        dataPoints: [],
        metadata: {
          'error': e.toString(),
          'aggregation_type': 'count',
        },
      );
    }
  }

  /// Get filtered finance records from database
  Future<List<FinanceRecord>> _getFilteredFinanceRecords(
    Map<String, dynamic>? filters,
    TimeRange? timeRange,
  ) async {
    try {
      // Get all finance records
      final query = database.select(database.financeRecords);
      
      // Apply time range filter
      if (timeRange != null && timeRange.start != null && timeRange.end != null) {
        query.where((f) => 
          f.deletedAt.isNull() & 
          f.time.isBetweenValues(timeRange.start!, timeRange.end!));
      } else if (timeRange != null && timeRange.start != null) {
        query.where((f) => 
          f.deletedAt.isNull() & 
          f.time.isBiggerOrEqualValue(timeRange.start!));
      } else if (timeRange != null && timeRange.end != null) {
        query.where((f) => 
          f.deletedAt.isNull() & 
          f.time.isSmallerOrEqualValue(timeRange.end!));
      } else {
        query.where((f) => f.deletedAt.isNull());
      }
      
      // Apply type filter
      if (filters?['type'] != null) {
        query.where((f) => f.type.equals(filters!['type']));
      }
      
      // Apply category filter
      if (filters?['category'] != null) {
        query.where((f) => f.category.equals(filters!['category']));
      }
      
      return await query.get();
    } catch (e) {
      _logger.error('❌ Error getting finance records: $e');
      return [];
    }
  }

  /// Get filtered meal records from database
  Future<List<Meal>> _getFilteredMeals(
    Map<String, dynamic>? filters,
    TimeRange? timeRange,
  ) async {
    try {
      final query = database.select(database.meals);
      
      if (timeRange != null && timeRange.start != null && timeRange.end != null) {
        query.where((m) => 
          m.deletedAt.isNull() & 
          m.time.isBetweenValues(timeRange.start!, timeRange.end!));
      } else if (timeRange != null && timeRange.start != null) {
        query.where((m) => 
          m.deletedAt.isNull() & 
          m.time.isBiggerOrEqualValue(timeRange.start!));
      } else if (timeRange != null && timeRange.end != null) {
        query.where((m) => 
          m.deletedAt.isNull() & 
          m.time.isSmallerOrEqualValue(timeRange.end!));
      } else {
        query.where((m) => m.deletedAt.isNull());
      }
      
      return await query.get();
    } catch (e) {
      _logger.error('❌ Error getting meals: $e');
      return [];
    }
  }

  /// Get filtered event records from database
  Future<List<Event>> _getFilteredEvents(
    Map<String, dynamic>? filters,
    TimeRange? timeRange,
  ) async {
    try {
      final query = database.select(database.events);
      
      if (timeRange != null && timeRange.start != null && timeRange.end != null) {
        query.where((e) => 
          e.deletedAt.isNull() & 
          e.date.isBetweenValues(timeRange.start!, timeRange.end!));
      } else if (timeRange != null && timeRange.start != null) {
        query.where((e) => 
          e.deletedAt.isNull() & 
          e.date.isBiggerOrEqualValue(timeRange.start!));
      } else if (timeRange != null && timeRange.end != null) {
        query.where((e) => 
          e.deletedAt.isNull() & 
          e.date.isSmallerOrEqualValue(timeRange.end!));
      } else {
        query.where((e) => e.deletedAt.isNull());
      }
      
      return await query.get();
    } catch (e) {
      _logger.error('❌ Error getting events: $e');
      return [];
    }
  }

  /// Get filtered journal records from database
  Future<List<Journal>> _getFilteredJournals(
    Map<String, dynamic>? filters,
    TimeRange? timeRange,
  ) async {
    try {
      final query = database.select(database.journals);
      
      if (timeRange != null && timeRange.start != null && timeRange.end != null) {
        query.where((j) => 
          j.deletedAt.isNull() & 
          j.createdAt.isBetweenValues(timeRange.start!, timeRange.end!));
      } else if (timeRange != null && timeRange.start != null) {
        query.where((j) => 
          j.deletedAt.isNull() & 
          j.createdAt.isBiggerOrEqualValue(timeRange.start!));
      } else if (timeRange != null && timeRange.end != null) {
        query.where((j) => 
          j.deletedAt.isNull() & 
          j.createdAt.isSmallerOrEqualValue(timeRange.end!));
      } else {
        query.where((j) => j.deletedAt.isNull());
      }
      
      return await query.get();
    } catch (e) {
      _logger.error('❌ Error getting journals: $e');
      return [];
    }
  }

  /// Helper methods
  String _getTransactionTypeLabel(String type) {
    switch (type) {
      case 'expense':
        return '支出';
      case 'income':
        return '收入';
      default:
        return type;
    }
  }

  String? _formatTimeRange(TimeRange? timeRange) {
    if (timeRange == null || timeRange.start == null || timeRange.end == null) return null;
    return '${timeRange.start!.toIso8601String().split('T')[0]} to ${timeRange.end!.toIso8601String().split('T')[0]}';
  }

  /// Extended analysis methods
  
  /// Calculate spending by category
  Future<Map<String, double>> calculateSpendingByCategory({
    TimeRange? timeRange,
  }) async {
    final categoryTotals = <String, double>{};
    
    try {
      final records = await _getFilteredFinanceRecords({'type': 'expense'}, timeRange);
      
      for (final record in records) {
        final category = record.category ?? 'Uncategorized';
        categoryTotals[category] = (categoryTotals[category] ?? 0.0) + record.amount;
      }
    } catch (e) {
      _logger.error('❌ Error calculating spending by category: $e');
    }
    
    return categoryTotals;
  }

  /// Calculate daily averages
  Future<Map<String, double>> calculateDailyAverages({
    TimeRange? timeRange,
  }) async {
    final averages = <String, double>{};
    
    try {
      // Calculate daily spending average
      final spendingResult = await calculateSum(
        filters: {'type': 'expense'},
        timeRange: timeRange,
      );
      
      if (timeRange != null && timeRange.start != null && timeRange.end != null && spendingResult.value > 0) {
        final days = timeRange.end!.difference(timeRange.start!).inDays + 1;
        averages['daily_spending'] = spendingResult.value / days;
      }
      
      // Calculate daily calorie average
      final calorieResult = await calculateSum(
        filters: {'include_meals': true},
        timeRange: timeRange,
      );
      
      if (timeRange != null && calorieResult.dataPoints.isNotEmpty) {
        final mealDays = calorieResult.dataPoints
            .map((p) => DateTime(p.timestamp.year, p.timestamp.month, p.timestamp.day))
            .toSet()
            .length;
        averages['daily_calories'] = calorieResult.value / mealDays;
      }
      
    } catch (e) {
      _logger.error('❌ Error calculating daily averages: $e');
    }
    
    return averages;
  }

  /// Comprehensive spending analysis
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
}
