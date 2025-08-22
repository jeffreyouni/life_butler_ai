import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'dart:io';

import 'tables.dart';

part 'database.g.dart';

@DriftDatabase(tables: [
  Users,
  Events,
  Education,
  Career,
  Meals,
  Journals,
  HealthMetrics,
  FinanceRecords,
  TasksHabits,
  Relations,
  MediaLogs,
  TravelLogs,
  Attachments,
  Embeddings,
])
class LifeButlerDatabase extends _$LifeButlerDatabase {
  LifeButlerDatabase({String? path}) : super(_openConnection(path));

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
        await _createIndexes();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        // Handle database upgrades here
        if (from < 2) {
          // Future migrations
        }
      },
    );
  }

  /// Create database indexes for better performance
  Future<void> _createIndexes() async {
    // User-based indexes
    await customStatement('CREATE INDEX IF NOT EXISTS idx_events_user_id ON events(user_id)');
    await customStatement('CREATE INDEX IF NOT EXISTS idx_education_user_id ON education(user_id)');
    await customStatement('CREATE INDEX IF NOT EXISTS idx_career_user_id ON career(user_id)');
    await customStatement('CREATE INDEX IF NOT EXISTS idx_meals_user_id ON meals(user_id)');
    await customStatement('CREATE INDEX IF NOT EXISTS idx_journals_user_id ON journals(user_id)');
    await customStatement('CREATE INDEX IF NOT EXISTS idx_health_metrics_user_id ON health_metrics(user_id)');
    await customStatement('CREATE INDEX IF NOT EXISTS idx_finance_records_user_id ON finance_records(user_id)');
    await customStatement('CREATE INDEX IF NOT EXISTS idx_tasks_habits_user_id ON tasks_habits(user_id)');
    await customStatement('CREATE INDEX IF NOT EXISTS idx_relations_user_id ON relations(user_id)');
    await customStatement('CREATE INDEX IF NOT EXISTS idx_media_logs_user_id ON media_logs(user_id)');
    await customStatement('CREATE INDEX IF NOT EXISTS idx_travel_logs_user_id ON travel_logs(user_id)');

    // Time-based indexes
    await customStatement('CREATE INDEX IF NOT EXISTS idx_events_date ON events(date)');
    await customStatement('CREATE INDEX IF NOT EXISTS idx_meals_time ON meals(time)');
    await customStatement('CREATE INDEX IF NOT EXISTS idx_health_metrics_time ON health_metrics(time)');
    await customStatement('CREATE INDEX IF NOT EXISTS idx_finance_records_time ON finance_records(time)');
    await customStatement('CREATE INDEX IF NOT EXISTS idx_media_logs_time ON media_logs(time)');

    // Type-based indexes
    await customStatement('CREATE INDEX IF NOT EXISTS idx_health_metrics_type ON health_metrics(metric_type)');
    await customStatement('CREATE INDEX IF NOT EXISTS idx_finance_records_type ON finance_records(type)');
    await customStatement('CREATE INDEX IF NOT EXISTS idx_tasks_habits_type ON tasks_habits(type)');
    await customStatement('CREATE INDEX IF NOT EXISTS idx_media_logs_type ON media_logs(media_type)');

    // Embedding indexes
    await customStatement('CREATE INDEX IF NOT EXISTS idx_embeddings_object ON embeddings(object_type, object_id)');
    await customStatement('CREATE INDEX IF NOT EXISTS idx_attachments_object ON attachments(object_type, object_id)');

    // Soft delete indexes
    await customStatement('CREATE INDEX IF NOT EXISTS idx_events_deleted_at ON events(deleted_at)');
    await customStatement('CREATE INDEX IF NOT EXISTS idx_education_deleted_at ON education(deleted_at)');
    await customStatement('CREATE INDEX IF NOT EXISTS idx_career_deleted_at ON career(deleted_at)');
    await customStatement('CREATE INDEX IF NOT EXISTS idx_meals_deleted_at ON meals(deleted_at)');
    await customStatement('CREATE INDEX IF NOT EXISTS idx_journals_deleted_at ON journals(deleted_at)');
    await customStatement('CREATE INDEX IF NOT EXISTS idx_health_metrics_deleted_at ON health_metrics(deleted_at)');
    await customStatement('CREATE INDEX IF NOT EXISTS idx_finance_records_deleted_at ON finance_records(deleted_at)');
    await customStatement('CREATE INDEX IF NOT EXISTS idx_tasks_habits_deleted_at ON tasks_habits(deleted_at)');
    await customStatement('CREATE INDEX IF NOT EXISTS idx_relations_deleted_at ON relations(deleted_at)');
    await customStatement('CREATE INDEX IF NOT EXISTS idx_media_logs_deleted_at ON media_logs(deleted_at)');
    await customStatement('CREATE INDEX IF NOT EXISTS idx_travel_logs_deleted_at ON travel_logs(deleted_at)');
  }

  /// Clear all data from the database
  Future<void> clearAllData() async {
    await transaction(() async {
      // Clear in reverse order to handle foreign key constraints
      await delete(embeddings).go();
      await delete(attachments).go();
      await delete(travelLogs).go();
      await delete(mediaLogs).go();
      await delete(relations).go();
      await delete(tasksHabits).go();
      await delete(financeRecords).go();
      await delete(healthMetrics).go();
      await delete(journals).go();
      await delete(meals).go();
      await delete(career).go();
      await delete(education).go();
      await delete(events).go();
      await delete(users).go();
    });
  }

  /// Get database statistics
  Future<Map<String, int>> getDatabaseStats() async {
    final stats = <String, int>{};

    stats['users'] = await (select(users).get()).then((rows) => rows.length);
    stats['events'] = await (select(events).get()).then((rows) => rows.length);
    stats['education'] = await (select(education).get()).then((rows) => rows.length);
    stats['career'] = await (select(career).get()).then((rows) => rows.length);
    stats['meals'] = await (select(meals).get()).then((rows) => rows.length);
    stats['journals'] = await (select(journals).get()).then((rows) => rows.length);
    stats['health_metrics'] = await (select(healthMetrics).get()).then((rows) => rows.length);
    stats['finance_records'] = await (select(financeRecords).get()).then((rows) => rows.length);
    stats['tasks_habits'] = await (select(tasksHabits).get()).then((rows) => rows.length);
    stats['relations'] = await (select(relations).get()).then((rows) => rows.length);
    stats['media_logs'] = await (select(mediaLogs).get()).then((rows) => rows.length);
    stats['travel_logs'] = await (select(travelLogs).get()).then((rows) => rows.length);
    stats['attachments'] = await (select(attachments).get()).then((rows) => rows.length);
    stats['embeddings'] = await (select(embeddings).get()).then((rows) => rows.length);

    return stats;
  }
}

LazyDatabase _openConnection(String? path) {
  return LazyDatabase(() async {
    if (path != null) {
      final file = File(path);
      return NativeDatabase.createInBackground(file);
    }

    // Default path
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'life_butler.db'));
    return NativeDatabase.createInBackground(file);
  });
}
