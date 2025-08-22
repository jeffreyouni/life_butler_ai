import '../domain/domain_data_retriever.dart';

/// Abstract interface for accessing data across domains
/// This allows core package to access data without depending on data package
abstract class DataAccessDelegate {
  /// Get finance records as indexable records
  Future<List<IndexableRecord>> getFinanceRecords(DateTime? startDate, DateTime? endDate);
  
  /// Get meal records as indexable records
  Future<List<IndexableRecord>> getMealRecords(DateTime? startDate, DateTime? endDate);
  
  /// Get journal records as indexable records
  Future<List<IndexableRecord>> getJournalRecords(DateTime? startDate, DateTime? endDate);
  
  /// Get health metric records as indexable records
  Future<List<IndexableRecord>> getHealthRecords(DateTime? startDate, DateTime? endDate);
  
  /// Get event records as indexable records
  Future<List<IndexableRecord>> getEventRecords(DateTime? startDate, DateTime? endDate);
  
  /// Get education records as indexable records
  Future<List<IndexableRecord>> getEducationRecords(DateTime? startDate, DateTime? endDate);
  
  /// Get career records as indexable records
  Future<List<IndexableRecord>> getCareerRecords(DateTime? startDate, DateTime? endDate);
  
  /// Get task/habit records as indexable records
  Future<List<IndexableRecord>> getTaskRecords(DateTime? startDate, DateTime? endDate);
  
  /// Get relation records as indexable records
  Future<List<IndexableRecord>> getRelationRecords(DateTime? startDate, DateTime? endDate);
  
  /// Get media log records as indexable records
  Future<List<IndexableRecord>> getMediaRecords(DateTime? startDate, DateTime? endDate);
  
  /// Get travel log records as indexable records
  Future<List<IndexableRecord>> getTravelRecords(DateTime? startDate, DateTime? endDate);
}
