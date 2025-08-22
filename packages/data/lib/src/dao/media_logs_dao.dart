import 'package:drift/drift.dart';
import '../database/database.dart';
import '../models/media_log_model.dart';

part 'media_logs_dao.g.dart';

@DriftAccessor(tables: [MediaLogs])
class MediaLogsDao extends DatabaseAccessor<LifeButlerDatabase> with _$MediaLogsDaoMixin {
  MediaLogsDao(LifeButlerDatabase db) : super(db);

  Future<List<MediaLogModel>> getAllMediaLogs() async {
    final query = select(mediaLogs)
      ..orderBy([(m) => OrderingTerm.desc(m.createdAt)]);
    
    final rows = await query.get();
    return rows.map((row) => MediaLogModel.fromDrift(row)).toList();
  }

  Future<List<MediaLogModel>> getMediaLogsByType(String mediaType) async {
    final query = select(mediaLogs)
      ..where((m) => m.mediaType.equals(mediaType))
      ..orderBy([(m) => OrderingTerm.desc(m.createdAt)]);
    
    final rows = await query.get();
    return rows.map((row) => MediaLogModel.fromDrift(row)).toList();
  }

  Future<MediaLogModel?> getMediaLogById(int id) async {
    final query = select(mediaLogs)..where((m) => m.id.equals(id));
    final row = await query.getSingleOrNull();
    return row != null ? MediaLogModel.fromDrift(row) : null;
  }

  Future<int> insertMediaLog(MediaLogModel mediaLog) async {
    final companion = MediaLogsCompanion(
      userId: Value(mediaLog.userId),
      mediaType: Value(mediaLog.mediaType),
      title: Value(mediaLog.title),
      creator: Value(mediaLog.creator ?? ''),
      genre: Value(mediaLog.genre ?? ''),
      releaseYear: Value(mediaLog.releaseYear),
      duration: Value(mediaLog.duration),
      rating: Value(mediaLog.rating),
      review: Value(mediaLog.review ?? ''),
      status: Value(mediaLog.status),
      startDate: Value(mediaLog.startDate),
      endDate: Value(mediaLog.endDate),
      platform: Value(mediaLog.platform ?? ''),
      tags: Value(mediaLog.tags ?? ''),
      notes: Value(mediaLog.notes ?? ''),
      isActive: Value(mediaLog.isActive),
      createdAt: Value(mediaLog.createdAt),
      updatedAt: Value(mediaLog.updatedAt),
    );
    
    return await into(mediaLogs).insert(companion);
  }

  Future<bool> updateMediaLog(MediaLogModel mediaLog) async {
    final companion = MediaLogsCompanion(
      userId: Value(mediaLog.userId),
      mediaType: Value(mediaLog.mediaType),
      title: Value(mediaLog.title),
      creator: Value(mediaLog.creator ?? ''),
      genre: Value(mediaLog.genre ?? ''),
      releaseYear: Value(mediaLog.releaseYear),
      duration: Value(mediaLog.duration),
      rating: Value(mediaLog.rating),
      review: Value(mediaLog.review ?? ''),
      status: Value(mediaLog.status),
      startDate: Value(mediaLog.startDate),
      endDate: Value(mediaLog.endDate),
      platform: Value(mediaLog.platform ?? ''),
      tags: Value(mediaLog.tags ?? ''),
      notes: Value(mediaLog.notes ?? ''),
      isActive: Value(mediaLog.isActive),
      updatedAt: Value(DateTime.now()),
    );
    
    return await (update(mediaLogs)..where((m) => m.id.equals(mediaLog.id))).write(companion) > 0;
  }

  Future<bool> deleteMediaLog(int id) async {
    return await (delete(mediaLogs)..where((m) => m.id.equals(id))).go() > 0;
  }

  Future<List<MediaLogModel>> getMediaLogsByRating(double minRating) async {
    final query = select(mediaLogs)
      ..where((m) => m.rating.isBiggerOrEqualValue(minRating))
      ..orderBy([(m) => OrderingTerm.desc(m.rating)]);
    
    final rows = await query.get();
    return rows.map((row) => MediaLogModel.fromDrift(row)).toList();
  }

  Future<List<MediaLogModel>> searchMediaLogs(String searchTerm) async {
    final query = select(mediaLogs)
      ..where((m) => 
        m.title.contains(searchTerm) |
        m.creator.contains(searchTerm) |
        m.review.contains(searchTerm) |
        m.notes.contains(searchTerm)
      )
      ..orderBy([(m) => OrderingTerm.desc(m.createdAt)]);
    
    final rows = await query.get();
    return rows.map((row) => MediaLogModel.fromDrift(row)).toList();
  }
}
