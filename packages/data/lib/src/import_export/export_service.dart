import 'dart:convert';
import 'dart:io';
import '../database/database.dart';

class ExportService {
  final LifeButlerDatabase _database;

  ExportService(this._database);

  /// Export all user data to JSON format
  Future<Map<String, dynamic>> exportAllData({int? userId}) async {
    final exportData = <String, dynamic>{
      'exportTimestamp': DateTime.now().toIso8601String(),
      'version': '1.0.0',
      'data': <String, dynamic>{},
    };

    try {
      // Export Events
      final events = await _database.eventsDao.getAllEvents();
      exportData['data']['events'] = events.map((e) => e.toJson()).toList();

      // Export Meals
      final meals = await _database.mealsDao.getAllMeals();
      exportData['data']['meals'] = meals.map((m) => m.toJson()).toList();

      // Export Journals
      final journals = await _database.journalsDao.getAllJournals();
      exportData['data']['journals'] = journals.map((j) => j.toJson()).toList();

      // Export Health Metrics
      final healthMetrics = await _database.healthMetricsDao.getAllHealthMetrics();
      exportData['data']['healthMetrics'] = healthMetrics.map((h) => h.toJson()).toList();

      // Export Finance Records
      final financeRecords = await _database.financeDao.getAllFinanceRecords();
      exportData['data']['financeRecords'] = financeRecords.map((f) => f.toJson()).toList();

      // Export Users (if applicable)
      final users = await _database.usersDao.getAllUsers();
      exportData['data']['users'] = users.map((u) => u.toJson()).toList();

      return exportData;
    } catch (e) {
      throw Exception('Failed to export data: $e');
    }
  }

  /// Export data to JSON file
  Future<String> exportToFile(String filePath, {int? userId}) async {
    try {
      final data = await exportAllData(userId: userId);
      final jsonString = const JsonEncoder.withIndent('  ').convert(data);
      
      final file = File(filePath);
      await file.writeAsString(jsonString);
      
      return filePath;
    } catch (e) {
      throw Exception('Failed to export to file: $e');
    }
  }

  /// Export specific domain data
  Future<Map<String, dynamic>> exportDomain(String domain, {int? userId}) async {
    try {
      switch (domain.toLowerCase()) {
        case 'events':
          final events = await _database.eventsDao.getAllEvents();
          return {
            'domain': 'events',
            'data': events.map((e) => e.toJson()).toList(),
            'count': events.length,
          };
        
        case 'meals':
          final meals = await _database.mealsDao.getAllMeals();
          return {
            'domain': 'meals',
            'data': meals.map((m) => m.toJson()).toList(),
            'count': meals.length,
          };
        
        case 'journals':
          final journals = await _database.journalsDao.getAllJournals();
          return {
            'domain': 'journals',
            'data': journals.map((j) => j.toJson()).toList(),
            'count': journals.length,
          };
        
        case 'health':
          final healthMetrics = await _database.healthMetricsDao.getAllHealthMetrics();
          return {
            'domain': 'health',
            'data': healthMetrics.map((h) => h.toJson()).toList(),
            'count': healthMetrics.length,
          };
        
        case 'finance':
          final financeRecords = await _database.financeDao.getAllFinanceRecords();
          return {
            'domain': 'finance',
            'data': financeRecords.map((f) => f.toJson()).toList(),
            'count': financeRecords.length,
          };
        
        default:
          throw ArgumentError('Unsupported domain: $domain');
      }
    } catch (e) {
      throw Exception('Failed to export domain $domain: $e');
    }
  }

  /// Get export statistics
  Future<Map<String, int>> getExportStats({int? userId}) async {
    try {
      final stats = <String, int>{};
      
      final events = await _database.eventsDao.getAllEvents();
      stats['events'] = events.length;
      
      final meals = await _database.mealsDao.getAllMeals();
      stats['meals'] = meals.length;
      
      final journals = await _database.journalsDao.getAllJournals();
      stats['journals'] = journals.length;
      
      final healthMetrics = await _database.healthMetricsDao.getAllHealthMetrics();
      stats['healthMetrics'] = healthMetrics.length;
      
      final financeRecords = await _database.financeDao.getAllFinanceRecords();
      stats['financeRecords'] = financeRecords.length;
      
      return stats;
    } catch (e) {
      throw Exception('Failed to get export stats: $e');
    }
  }
}
