import 'package:drift/drift.dart';
import '../database/database.dart';
import '../database/tables.dart';

part 'health_metrics_dao.g.dart';

@DriftAccessor(tables: [HealthMetrics])
class HealthMetricsDao extends DatabaseAccessor<LifeButlerDatabase> with _$HealthMetricsDaoMixin {
  HealthMetricsDao(LifeButlerDatabase db) : super(db);

  Future<List<HealthMetric>> getAllHealthMetrics() async {
    final query = select(healthMetrics)
      ..orderBy([(h) => OrderingTerm.desc(h.time)]);
    
    return await query.get();
  }

  Future<List<HealthMetric>> getHealthMetricsByType(String metricType) async {
    final query = select(healthMetrics)
      ..where((h) => h.metricType.equals(metricType))
      ..orderBy([(h) => OrderingTerm.desc(h.time)]);
    
    return await query.get();
  }

  Future<HealthMetric?> getHealthMetricById(String id) async {
    final query = select(healthMetrics)..where((h) => h.id.equals(id));
    return await query.getSingleOrNull();
  }

  Future<String> insertHealthMetric(HealthMetricsCompanion healthMetricData) async {
    await into(healthMetrics).insert(healthMetricData);
    return healthMetricData.id.value;
  }

  Future<bool> updateHealthMetric(String id, HealthMetricsCompanion healthMetricData) async {
    return await (update(healthMetrics)..where((h) => h.id.equals(id))).write(healthMetricData) > 0;
  }

  Future<bool> deleteHealthMetric(String id) async {
    return await (delete(healthMetrics)..where((h) => h.id.equals(id))).go() > 0;
  }

  Future<List<HealthMetric>> getHealthMetricsByDateRange(DateTime startDate, DateTime endDate) async {
    final query = select(healthMetrics)
      ..where((h) => h.time.isBetweenValues(startDate, endDate))
      ..orderBy([(h) => OrderingTerm.desc(h.time)]);
    
    return await query.get();
  }

  Future<List<HealthMetric>> searchHealthMetrics(String searchTerm) async {
    final query = select(healthMetrics)
      ..where((h) => 
        h.metricType.contains(searchTerm) |
        h.unit.contains(searchTerm) |
        h.notes.contains(searchTerm)
      )
      ..orderBy([(h) => OrderingTerm.desc(h.time)]);
    
    return await query.get();
  }
}
