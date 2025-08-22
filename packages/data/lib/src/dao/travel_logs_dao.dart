import 'package:drift/drift.dart';
import '../database/database.dart';
import '../models/travel_log_model.dart';

part 'travel_logs_dao.g.dart';

@DriftAccessor(tables: [TravelLogs])
class TravelLogsDao extends DatabaseAccessor<LifeButlerDatabase> with _$TravelLogsDaoMixin {
  TravelLogsDao(LifeButlerDatabase db) : super(db);

  Future<List<TravelLogModel>> getAllTravelLogs() async {
    final query = select(travelLogs)
      ..orderBy([(t) => OrderingTerm.desc(t.startDate)]);
    
    final rows = await query.get();
    return rows.map((row) => TravelLogModel.fromDrift(row)).toList();
  }

  Future<List<TravelLogModel>> getTravelLogsByDestination(String destination) async {
    final query = select(travelLogs)
      ..where((t) => t.destination.contains(destination))
      ..orderBy([(t) => OrderingTerm.desc(t.startDate)]);
    
    final rows = await query.get();
    return rows.map((row) => TravelLogModel.fromDrift(row)).toList();
  }

  Future<TravelLogModel?> getTravelLogById(int id) async {
    final query = select(travelLogs)..where((t) => t.id.equals(id));
    final row = await query.getSingleOrNull();
    return row != null ? TravelLogModel.fromDrift(row) : null;
  }

  Future<int> insertTravelLog(TravelLogModel travelLog) async {
    final companion = TravelLogsCompanion(
      userId: Value(travelLog.userId),
      destination: Value(travelLog.destination),
      purpose: Value(travelLog.purpose ?? ''),
      startDate: Value(travelLog.startDate),
      endDate: Value(travelLog.endDate),
      transportation: Value(travelLog.transportation ?? ''),
      accommodation: Value(travelLog.accommodation ?? ''),
      budget: Value(travelLog.budget),
      actualCost: Value(travelLog.actualCost),
      activities: Value(travelLog.activities ?? ''),
      highlights: Value(travelLog.highlights ?? ''),
      companions: Value(travelLog.companions ?? ''),
      photos: Value(travelLog.photos ?? ''),
      rating: Value(travelLog.rating),
      notes: Value(travelLog.notes ?? ''),
      isActive: Value(travelLog.isActive),
      createdAt: Value(travelLog.createdAt),
      updatedAt: Value(travelLog.updatedAt),
    );
    
    return await into(travelLogs).insert(companion);
  }

  Future<bool> updateTravelLog(TravelLogModel travelLog) async {
    final companion = TravelLogsCompanion(
      userId: Value(travelLog.userId),
      destination: Value(travelLog.destination),
      purpose: Value(travelLog.purpose ?? ''),
      startDate: Value(travelLog.startDate),
      endDate: Value(travelLog.endDate),
      transportation: Value(travelLog.transportation ?? ''),
      accommodation: Value(travelLog.accommodation ?? ''),
      budget: Value(travelLog.budget),
      actualCost: Value(travelLog.actualCost),
      activities: Value(travelLog.activities ?? ''),
      highlights: Value(travelLog.highlights ?? ''),
      companions: Value(travelLog.companions ?? ''),
      photos: Value(travelLog.photos ?? ''),
      rating: Value(travelLog.rating),
      notes: Value(travelLog.notes ?? ''),
      isActive: Value(travelLog.isActive),
      updatedAt: Value(DateTime.now()),
    );
    
    return await (update(travelLogs)..where((t) => t.id.equals(travelLog.id))).write(companion) > 0;
  }

  Future<bool> deleteTravelLog(int id) async {
    return await (delete(travelLogs)..where((t) => t.id.equals(id))).go() > 0;
  }

  Future<List<TravelLogModel>> getTravelLogsByRating(double minRating) async {
    final query = select(travelLogs)
      ..where((t) => t.rating.isBiggerOrEqualValue(minRating))
      ..orderBy([(t) => OrderingTerm.desc(t.rating)]);
    
    final rows = await query.get();
    return rows.map((row) => TravelLogModel.fromDrift(row)).toList();
  }

  Future<List<TravelLogModel>> searchTravelLogs(String searchTerm) async {
    final query = select(travelLogs)
      ..where((t) => 
        t.destination.contains(searchTerm) |
        t.activities.contains(searchTerm) |
        t.highlights.contains(searchTerm) |
        t.notes.contains(searchTerm)
      )
      ..orderBy([(t) => OrderingTerm.desc(t.startDate)]);
    
    final rows = await query.get();
    return rows.map((row) => TravelLogModel.fromDrift(row)).toList();
  }
}
