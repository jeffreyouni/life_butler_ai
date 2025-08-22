import 'dart:convert';
import 'dart:io';
import '../database/database.dart';
import '../models/event_model.dart';
import '../models/meal_model.dart';
import '../models/journal_model.dart';
import '../models/health_metric_model.dart';
import '../models/finance_record_model.dart';
import '../models/user_model.dart';

class ImportService {
  final LifeButlerDatabase _database;

  ImportService(this._database);

  /// Import data from JSON format
  Future<ImportResult> importFromJson(Map<String, dynamic> jsonData) async {
    final result = ImportResult();
    
    try {
      final data = jsonData['data'] as Map<String, dynamic>? ?? {};
      
      // Import Users first
      if (data.containsKey('users')) {
        result.users = await _importUsers(data['users'] as List);
      }
      
      // Import Events
      if (data.containsKey('events')) {
        result.events = await _importEvents(data['events'] as List);
      }
      
      // Import Meals
      if (data.containsKey('meals')) {
        result.meals = await _importMeals(data['meals'] as List);
      }
      
      // Import Journals
      if (data.containsKey('journals')) {
        result.journals = await _importJournals(data['journals'] as List);
      }
      
      // Import Health Metrics
      if (data.containsKey('healthMetrics')) {
        result.healthMetrics = await _importHealthMetrics(data['healthMetrics'] as List);
      }
      
      // Import Finance Records
      if (data.containsKey('financeRecords')) {
        result.financeRecords = await _importFinanceRecords(data['financeRecords'] as List);
      }
      
      result.success = true;
      return result;
    } catch (e) {
      result.success = false;
      result.error = e.toString();
      return result;
    }
  }

  /// Import from JSON file
  Future<ImportResult> importFromFile(String filePath) async {
    try {
      final file = File(filePath);
      final jsonString = await file.readAsString();
      final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;
      
      return await importFromJson(jsonData);
    } catch (e) {
      return ImportResult()
        ..success = false
        ..error = 'Failed to read file: $e';
    }
  }

  Future<int> _importUsers(List userDataList) async {
    int count = 0;
    for (final userData in userDataList) {
      try {
        final user = UserModel.fromJson(userData as Map<String, dynamic>);
        await _database.usersDao.insertUser(user);
        count++;
      } catch (e) {
        // Log error but continue with other records
        _logger.info('Failed to import user: $e');
      }
    }
    return count;
  }

  Future<int> _importEvents(List eventDataList) async {
    int count = 0;
    for (final eventData in eventDataList) {
      try {
        final event = EventModel.fromJson(eventData as Map<String, dynamic>);
        await _database.eventsDao.insertEvent(event);
        count++;
      } catch (e) {
        _logger.info('Failed to import event: $e');
      }
    }
    return count;
  }

  Future<int> _importMeals(List mealDataList) async {
    int count = 0;
    for (final mealData in mealDataList) {
      try {
        final meal = MealModel.fromJson(mealData as Map<String, dynamic>);
        await _database.mealsDao.insertMeal(meal);
        count++;
      } catch (e) {
        _logger.info('Failed to import meal: $e');
      }
    }
    return count;
  }

  Future<int> _importJournals(List journalDataList) async {
    int count = 0;
    for (final journalData in journalDataList) {
      try {
        final journal = JournalModel.fromJson(journalData as Map<String, dynamic>);
        await _database.journalsDao.insertJournal(journal);
        count++;
      } catch (e) {
        _logger.info('Failed to import journal: $e');
      }
    }
    return count;
  }

  Future<int> _importHealthMetrics(List healthDataList) async {
    int count = 0;
    for (final healthData in healthDataList) {
      try {
        final healthMetric = HealthMetricModel.fromJson(healthData as Map<String, dynamic>);
        await _database.healthMetricsDao.insertHealthMetric(healthMetric);
        count++;
      } catch (e) {
        _logger.info('Failed to import health metric: $e');
      }
    }
    return count;
  }

  Future<int> _importFinanceRecords(List financeDataList) async {
    int count = 0;
    for (final financeData in financeDataList) {
      try {
        final financeRecord = FinanceRecordModel.fromJson(financeData as Map<String, dynamic>);
        await _database.financeDao.insertFinanceRecord(financeRecord);
        count++;
      } catch (e) {
        _logger.info('Failed to import finance record: $e');
      }
    }
    return count;
  }

  /// Validate import data format
  bool validateImportData(Map<String, dynamic> jsonData) {
    try {
      // Check for required structure
      if (!jsonData.containsKey('data')) {
        return false;
      }
      
      final data = jsonData['data'] as Map<String, dynamic>;
      
      // Check if at least one domain exists
      final supportedDomains = ['events', 'meals', 'journals', 'healthMetrics', 'financeRecords', 'users'];
      
      return supportedDomains.any((domain) => data.containsKey(domain));
    } catch (e) {
      return false;
    }
  }
}

class ImportResult {
  bool success = false;
  String? error;
  int events = 0;
  int meals = 0;
  int journals = 0;
  int healthMetrics = 0;
  int financeRecords = 0;
  int users = 0;
  
  int get totalRecords => events + meals + journals + healthMetrics + financeRecords + users;
  
  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'error': error,
      'totalRecords': totalRecords,
      'breakdown': {
        'events': events,
        'meals': meals,
        'journals': journals,
        'healthMetrics': healthMetrics,
        'financeRecords': financeRecords,
        'users': users,
      },
    };
  }
}
