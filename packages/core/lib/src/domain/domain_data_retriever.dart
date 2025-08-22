import '../data/data_access_delegate.dart';
import '../utils/logger.dart';

/// Abstract interface for retrieving domain data across all life domains
abstract class DomainDataRetriever {
  /// Get all domain records that should be indexed for RAG
  Future<List<IndexableRecord>> getAllIndexableRecords({
    DateTime? startDate,
    DateTime? endDate,
    List<String>? domains,
  });

  /// Get records for specific domains
  Future<List<IndexableRecord>> getRecordsForDomains(
    List<String> domains, {
    DateTime? startDate,
    DateTime? endDate,
  });

  /// Check if data exists in any domain
  Future<Map<String, int>> getDomainDataCounts();
}

/// Represents a structured data record that can be converted to searchable text
class IndexableRecord {
  final String id;
  final String domain;
  final String objectType;
  final DateTime timestamp;
  final Map<String, dynamic> structuredData;
  final String? userId;

  const IndexableRecord({
    required this.id,
    required this.domain,
    required this.objectType,
    required this.timestamp,
    required this.structuredData,
    this.userId,
  });

  /// Convert structured data to searchable text for embedding
  String toSearchableText() {
    final buffer = StringBuffer();
    
    // Add domain context prefix
    buffer.writeln('DOMAIN: ${domain.toUpperCase()}');
    
    // Add timestamp context
    buffer.writeln('DATE: ${timestamp.toIso8601String().split('T')[0]}');
    
    // Add structured fields based on domain
    switch (domain.toLowerCase()) {
      case 'finance_records':
        _serializeFinanceRecord(buffer);
        break;
      case 'meals':
        _serializeMealRecord(buffer);
        break;
      case 'journals':
        _serializeJournalRecord(buffer);
        break;
      case 'health_metrics':
        _serializeHealthRecord(buffer);
        break;
      case 'events':
        _serializeEventRecord(buffer);
        break;
      case 'education':
        _serializeEducationRecord(buffer);
        break;
      case 'career':
        _serializeCareerRecord(buffer);
        break;
      case 'tasks_habits':
        _serializeTaskRecord(buffer);
        break;
      case 'relations':
        _serializeRelationRecord(buffer);
        break;
      case 'media_logs':
        _serializeMediaRecord(buffer);
        break;
      case 'travel_logs':
        _serializeTravelRecord(buffer);
        break;
      default:
        _serializeGenericRecord(buffer);
    }
    
    return buffer.toString().trim();
  }

  void _serializeFinanceRecord(StringBuffer buffer) {
    final type = structuredData['type'] ?? 'unknown';
    final amount = structuredData['amount'] ?? 0.0;
    final currency = structuredData['currency'] ?? 'USD';
    final category = structuredData['category'] ?? 'uncategorized';
    final notes = structuredData['notes'] ?? '';
    
    buffer.writeln('TYPE: ${type.toUpperCase()}');
    buffer.writeln('AMOUNT: $amount $currency');
    buffer.writeln('CATEGORY: $category');
    if (notes.isNotEmpty) {
      buffer.writeln('DESCRIPTION: $notes');
    }
    
    // Add searchable keywords for better retrieval
    final keywords = <String>[];
    keywords.add(type == 'expense' ? 'spending cost expense payment 支出 花费 消费' : 'income revenue earning 收入 收益');
    keywords.add(category.toLowerCase());
    if (notes.isNotEmpty) keywords.add(notes.toLowerCase());
    buffer.writeln('KEYWORDS: ${keywords.join(' ')}');
  }

  void _serializeMealRecord(StringBuffer buffer) {
    final name = structuredData['name'] ?? 'Unknown meal';
    final items = structuredData['itemsJson'] ?? '[]';
    final calories = structuredData['caloriesInt'] ?? 0;
    final location = structuredData['location'] ?? '';
    final notes = structuredData['notes'] ?? '';
    
    buffer.writeln('MEAL: $name');
    if (items != '[]') {
      buffer.writeln('ITEMS: $items');
    }
    if (calories > 0) {
      buffer.writeln('CALORIES: $calories');
    }
    if (location.isNotEmpty) {
      buffer.writeln('LOCATION: $location');
    }
    if (notes.isNotEmpty) {
      buffer.writeln('NOTES: $notes');
    }
    
    buffer.writeln('KEYWORDS: food, meal, eating, 餐, 食物, 吃, 卡路里');
  }

  void _serializeJournalRecord(StringBuffer buffer) {
    final content = structuredData['contentMd'] ?? '';
    final mood = structuredData['moodInt'] ?? 0;
    final topics = structuredData['topicsJson'] ?? '[]';
    
    if (content.isNotEmpty) {
      buffer.writeln('CONTENT: $content');
    }
    if (mood > 0) {
      buffer.writeln('MOOD_SCORE: $mood');
    }
    if (topics != '[]') {
      buffer.writeln('TOPICS: $topics');
    }
    
    buffer.writeln('KEYWORDS: journal, diary, thoughts, mood, 日记, 心情, 情绪, 感想');
  }

  void _serializeHealthRecord(StringBuffer buffer) {
    final metricType = structuredData['metricType'] ?? 'unknown';
    final value = structuredData['valueNum'] ?? 0.0;
    final unit = structuredData['unit'] ?? '';
    final notes = structuredData['notes'] ?? '';
    
    buffer.writeln('METRIC: $metricType');
    buffer.writeln('VALUE: $value $unit');
    if (notes.isNotEmpty) {
      buffer.writeln('NOTES: $notes');
    }
    
    buffer.writeln('KEYWORDS: health, fitness, metric, 健康, 身体, 指标');
  }

  void _serializeEventRecord(StringBuffer buffer) {
    final title = structuredData['title'] ?? 'Untitled event';
    final description = structuredData['description'] ?? '';
    final location = structuredData['location'] ?? '';
    final tags = structuredData['tagsJson'] ?? '[]';
    
    buffer.writeln('TITLE: $title');
    if (description.isNotEmpty) {
      buffer.writeln('DESCRIPTION: $description');
    }
    if (location.isNotEmpty) {
      buffer.writeln('LOCATION: $location');
    }
    if (tags != '[]') {
      buffer.writeln('TAGS: $tags');
    }
    
    buffer.writeln('KEYWORDS: event, activity, 事件, 活动');
  }

  void _serializeEducationRecord(StringBuffer buffer) {
    final schoolName = structuredData['schoolName'] ?? '';
    final degree = structuredData['degree'] ?? '';
    final major = structuredData['major'] ?? '';
    final notes = structuredData['notes'] ?? '';
    
    if (schoolName.isNotEmpty) {
      buffer.writeln('SCHOOL: $schoolName');
    }
    if (degree.isNotEmpty) {
      buffer.writeln('DEGREE: $degree');
    }
    if (major.isNotEmpty) {
      buffer.writeln('MAJOR: $major');
    }
    if (notes.isNotEmpty) {
      buffer.writeln('NOTES: $notes');
    }
    
    buffer.writeln('KEYWORDS: education, school, study, learning, 教育, 学习, 学校');
  }

  void _serializeCareerRecord(StringBuffer buffer) {
    final company = structuredData['company'] ?? '';
    final role = structuredData['role'] ?? '';
    final achievements = structuredData['achievementsJson'] ?? '[]';
    final notes = structuredData['notes'] ?? '';
    
    if (company.isNotEmpty) {
      buffer.writeln('COMPANY: $company');
    }
    if (role.isNotEmpty) {
      buffer.writeln('ROLE: $role');
    }
    if (achievements != '[]') {
      buffer.writeln('ACHIEVEMENTS: $achievements');
    }
    if (notes.isNotEmpty) {
      buffer.writeln('NOTES: $notes');
    }
    
    buffer.writeln('KEYWORDS: work, career, job, employment, 工作, 职业, 事业');
  }

  void _serializeTaskRecord(StringBuffer buffer) {
    final title = structuredData['title'] ?? 'Untitled task';
    final type = structuredData['type'] ?? 'task';
    final status = structuredData['status'] ?? 'pending';
    final notes = structuredData['notes'] ?? '';
    
    buffer.writeln('TITLE: $title');
    buffer.writeln('TYPE: $type');
    buffer.writeln('STATUS: $status');
    if (notes.isNotEmpty) {
      buffer.writeln('NOTES: $notes');
    }
    
    buffer.writeln('KEYWORDS: task, habit, routine, productivity, 任务, 习惯, 例行');
  }

  void _serializeRelationRecord(StringBuffer buffer) {
    final personName = structuredData['personName'] ?? '';
    final relationType = structuredData['relationType'] ?? '';
    final notes = structuredData['notes'] ?? '';
    
    if (personName.isNotEmpty) {
      buffer.writeln('PERSON: $personName');
    }
    if (relationType.isNotEmpty) {
      buffer.writeln('RELATION: $relationType');
    }
    if (notes.isNotEmpty) {
      buffer.writeln('NOTES: $notes');
    }
    
    buffer.writeln('KEYWORDS: relationship, social, people, contact, 关系, 社交, 人际');
  }

  void _serializeMediaRecord(StringBuffer buffer) {
    final title = structuredData['title'] ?? 'Untitled media';
    final mediaType = structuredData['mediaType'] ?? '';
    final progress = structuredData['progress'] ?? '';
    final rating = structuredData['rating'] ?? 0;
    final notes = structuredData['notes'] ?? '';
    
    buffer.writeln('TITLE: $title');
    if (mediaType.isNotEmpty) {
      buffer.writeln('TYPE: $mediaType');
    }
    if (progress.isNotEmpty) {
      buffer.writeln('PROGRESS: $progress');
    }
    if (rating > 0) {
      buffer.writeln('RATING: $rating');
    }
    if (notes.isNotEmpty) {
      buffer.writeln('NOTES: $notes');
    }
    
    buffer.writeln('KEYWORDS: media, entertainment, 媒体, 娱乐');
  }

  void _serializeTravelRecord(StringBuffer buffer) {
    final place = structuredData['place'] ?? '';
    final cost = structuredData['cost'] ?? 0.0;
    final notes = structuredData['notes'] ?? '';
    
    if (place.isNotEmpty) {
      buffer.writeln('PLACE: $place');
    }
    if (cost > 0) {
      buffer.writeln('COST: $cost');
    }
    if (notes.isNotEmpty) {
      buffer.writeln('NOTES: $notes');
    }
    
    buffer.writeln('KEYWORDS: travel, trip, journey, 旅行, 出行');
  }

  void _serializeGenericRecord(StringBuffer buffer) {
    // Fallback serialization for unknown domain types
    structuredData.forEach((key, value) {
      if (value != null && value.toString().isNotEmpty) {
        buffer.writeln('$key: $value');
      }
    });
  }
}

/// Implementation that works with the data layer
class DataLayerDomainRetriever implements DomainDataRetriever {
  final DataAccessDelegate _dataAccess;
  static final _logger = Logger('DomainDataRetriever');

  DataLayerDomainRetriever(this._dataAccess);

  @override
  Future<List<IndexableRecord>> getAllIndexableRecords({
    DateTime? startDate,
    DateTime? endDate,
    List<String>? domains,
  }) async {
    final targetDomains = domains ?? [
      'finance_records', 'meals', 'journals', 'health_metrics', 'events',
      'education', 'career', 'tasks_habits', 'relations', 'media_logs', 'travel_logs'
    ];

    final allRecords = <IndexableRecord>[];
    
    for (final domain in targetDomains) {
      try {
        final domainRecords = await _getRecordsForDomain(domain, startDate, endDate);
        allRecords.addAll(domainRecords);
      } catch (e) {
        _logger.info('Warning: Failed to retrieve records from domain $domain: $e');

      }
    }

    return allRecords;
  }

  @override
  Future<List<IndexableRecord>> getRecordsForDomains(
    List<String> domains, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    return getAllIndexableRecords(
      startDate: startDate,
      endDate: endDate,
      domains: domains,
    );
  }

  @override
  Future<Map<String, int>> getDomainDataCounts() async {
    final counts = <String, int>{};
    final domains = [
      'finance_records', 'meals', 'journals', 'health_metrics', 'events',
      'education', 'career', 'tasks_habits', 'relations', 'media_logs', 'travel_logs'
    ];

    for (final domain in domains) {
      try {
        final records = await _getRecordsForDomain(domain, null, null);
        counts[domain] = records.length;
      } catch (e) {
        counts[domain] = 0;
      }
    }

    return counts;
  }

  Future<List<IndexableRecord>> _getRecordsForDomain(
    String domain,
    DateTime? startDate,
    DateTime? endDate,
  ) async {
    switch (domain) {
      case 'finance_records':
        return await _dataAccess.getFinanceRecords(startDate, endDate);
      case 'meals':
        return await _dataAccess.getMealRecords(startDate, endDate);
      case 'journals':
        return await _dataAccess.getJournalRecords(startDate, endDate);
      case 'health_metrics':
        return await _dataAccess.getHealthRecords(startDate, endDate);
      case 'events':
        return await _dataAccess.getEventRecords(startDate, endDate);
      case 'education':
        return await _dataAccess.getEducationRecords(startDate, endDate);
      case 'career':
        return await _dataAccess.getCareerRecords(startDate, endDate);
      case 'tasks_habits':
        return await _dataAccess.getTaskRecords(startDate, endDate);
      case 'relations':
        return await _dataAccess.getRelationRecords(startDate, endDate);
      case 'media_logs':
        return await _dataAccess.getMediaRecords(startDate, endDate);
      case 'travel_logs':
        return await _dataAccess.getTravelRecords(startDate, endDate);
      default:
        return [];
    }
  }
}
