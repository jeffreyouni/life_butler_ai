import 'package:data/data.dart';
import 'package:core/core.dart';

class AppDataAccessDelegateSimple implements DataAccessDelegate {
  final LifeButlerDatabase _database;

  AppDataAccessDelegateSimple(this._database);

  @override
  Future<List<IndexableRecord>> getFinanceRecords(DateTime? startDate, DateTime? endDate) async {
    // Simple query without date filtering for now to test basic functionality
    final query = _database.select(_database.financeRecords);
    final records = await query.get();
    return records.map((record) => IndexableRecord(
      id: record.id,
      domain: 'finance_records',
      objectType: 'FinanceRecord',
      timestamp: record.time,
      structuredData: record.toJson(),
    )).toList();
  }

  @override
  Future<List<IndexableRecord>> getMealRecords(DateTime? startDate, DateTime? endDate) async {
    final query = _database.select(_database.meals);
    final records = await query.get();
    return records.map((record) => IndexableRecord(
      id: record.id,
      domain: 'meals',
      objectType: 'Meal',
      timestamp: record.time,
      structuredData: record.toJson(),
    )).toList();
  }

  @override
  Future<List<IndexableRecord>> getJournalRecords(DateTime? startDate, DateTime? endDate) async {
    final query = _database.select(_database.journals);
    final records = await query.get();
    return records.map((record) => IndexableRecord(
      id: record.id,
      domain: 'journals',
      objectType: 'Journal',
      timestamp: record.createdAt,
      structuredData: record.toJson(),
    )).toList();
  }

  @override
  Future<List<IndexableRecord>> getHealthRecords(DateTime? startDate, DateTime? endDate) async {
    final query = _database.select(_database.healthMetrics);
    final records = await query.get();
    return records.map((record) => IndexableRecord(
      id: record.id,
      domain: 'health_metrics',
      objectType: 'HealthMetric',
      timestamp: record.time,
      structuredData: record.toJson(),
    )).toList();
  }

  @override
  Future<List<IndexableRecord>> getEventRecords(DateTime? startDate, DateTime? endDate) async {
    final query = _database.select(_database.events);
    final records = await query.get();
    return records.map((record) => IndexableRecord(
      id: record.id,
      domain: 'events',
      objectType: 'Event',
      timestamp: record.date,
      structuredData: record.toJson(),
    )).toList();
  }

  @override
  Future<List<IndexableRecord>> getEducationRecords(DateTime? startDate, DateTime? endDate) async {
    final query = _database.select(_database.education);
    final records = await query.get();
    return records.map((record) => IndexableRecord(
      id: record.id,
      domain: 'education',
      objectType: 'Education',
      timestamp: record.startDate,
      structuredData: record.toJson(),
    )).toList();
  }

  @override
  Future<List<IndexableRecord>> getCareerRecords(DateTime? startDate, DateTime? endDate) async {
    final query = _database.select(_database.career);
    final records = await query.get();
    return records.map((record) => IndexableRecord(
      id: record.id,
      domain: 'career',
      objectType: 'Career',
      timestamp: record.startDate,
      structuredData: record.toJson(),
    )).toList();
  }

  @override
  Future<List<IndexableRecord>> getTaskRecords(DateTime? startDate, DateTime? endDate) async {
    final query = _database.select(_database.tasksHabits);
    final records = await query.get();
    return records.map((record) => IndexableRecord(
      id: record.id,
      domain: 'tasks_habits',
      objectType: 'TaskHabit',
      timestamp: record.createdAt,
      structuredData: record.toJson(),
    )).toList();
  }

  @override
  Future<List<IndexableRecord>> getRelationRecords(DateTime? startDate, DateTime? endDate) async {
    final query = _database.select(_database.relations);
    final records = await query.get();
    return records.map((record) => IndexableRecord(
      id: record.id,
      domain: 'relations',
      objectType: 'Relation',
      timestamp: record.createdAt,
      structuredData: record.toJson(),
    )).toList();
  }

  @override
  Future<List<IndexableRecord>> getMediaRecords(DateTime? startDate, DateTime? endDate) async {
    final query = _database.select(_database.mediaLogs);
    final records = await query.get();
    return records.map((record) => IndexableRecord(
      id: record.id,
      domain: 'media_logs',
      objectType: 'MediaLog',
      timestamp: record.time,
      structuredData: record.toJson(),
    )).toList();
  }

  @override
  Future<List<IndexableRecord>> getTravelRecords(DateTime? startDate, DateTime? endDate) async {
    final query = _database.select(_database.travelLogs);
    final records = await query.get();
    return records.map((record) => IndexableRecord(
      id: record.id,
      domain: 'travel_logs',
      objectType: 'TravelLog',
      timestamp: record.startDate,
      structuredData: record.toJson(),
    )).toList();
  }
}
