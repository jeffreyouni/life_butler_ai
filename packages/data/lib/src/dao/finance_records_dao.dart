import 'package:drift/drift.dart';
import '../database/database.dart';
import '../database/tables.dart';
import '../models/finance_record_model.dart';

part 'finance_records_dao.g.dart';

@DriftAccessor(tables: [FinanceRecords])
class FinanceRecordsDao extends DatabaseAccessor<LifeButlerDatabase> with _$FinanceRecordsDaoMixin {
  FinanceRecordsDao(LifeButlerDatabase db) : super(db);

  Future<List<FinanceRecordModel>> getAllFinanceRecords() async {
    final query = select(financeRecords)
      ..orderBy([(f) => OrderingTerm.desc(f.time)]);
    
    final rows = await query.get();
    return rows.map((row) => FinanceRecordModel.fromDrift(row)).toList();
  }

  Future<List<FinanceRecordModel>> getFinanceRecordsByType(String type) async {
    final query = select(financeRecords)
      ..where((f) => f.type.equals(type))
      ..orderBy([(f) => OrderingTerm.desc(f.time)]);
    
    final rows = await query.get();
    return rows.map((row) => FinanceRecordModel.fromDrift(row)).toList();
  }

  Future<List<FinanceRecordModel>> getFinanceRecordsByCategory(String category) async {
    final query = select(financeRecords)
      ..where((f) => f.category.equals(category))
      ..orderBy([(f) => OrderingTerm.desc(f.time)]);
    
    final rows = await query.get();
    return rows.map((row) => FinanceRecordModel.fromDrift(row)).toList();
  }

  Future<FinanceRecordModel?> getFinanceRecordById(String id) async {
    final query = select(financeRecords)..where((f) => f.id.equals(id));
    final row = await query.getSingleOrNull();
    return row != null ? FinanceRecordModel.fromDrift(row) : null;
  }

  Future<String> insertFinanceRecord(FinanceRecordModel record) async {
    final companion = FinanceRecordsCompanion(
      id: Value(record.id),
      userId: Value(record.userId),
      type: Value(record.type),
      amount: Value(record.amount),
      currency: Value(record.currency),
      time: Value(record.time),
      category: Value(record.category),
      tagsJson: Value(record.tags.isNotEmpty ? {'tags': record.tags} : {}),
      notes: Value(record.notes),
      createdAt: Value(record.createdAt),
      updatedAt: Value(record.updatedAt),
    );
    
    await into(financeRecords).insert(companion);
    return record.id;
  }

  Future<bool> updateFinanceRecord(FinanceRecordModel record) async {
    final companion = FinanceRecordsCompanion(
      userId: Value(record.userId),
      type: Value(record.type),
      amount: Value(record.amount),
      currency: Value(record.currency),
      time: Value(record.time),
      category: Value(record.category),
      tagsJson: Value(record.tags.isNotEmpty ? {'tags': record.tags} : {}),
      notes: Value(record.notes),
      updatedAt: Value(DateTime.now()),
    );
    
    return await (update(financeRecords)..where((f) => f.id.equals(record.id))).write(companion) > 0;
  }

  Future<bool> deleteFinanceRecord(String id) async {
    return await (delete(financeRecords)..where((f) => f.id.equals(id))).go() > 0;
  }

  Future<double> getTotalByTypeAndDateRange(String type, DateTime startDate, DateTime endDate) async {
    final query = selectOnly(financeRecords)
      ..where(financeRecords.type.equals(type) & 
              financeRecords.time.isBetweenValues(startDate, endDate))
      ..addColumns([financeRecords.amount.sum()]);
    
    final result = await query.getSingle();
    return result.read(financeRecords.amount.sum()) ?? 0.0;
  }

  Future<List<FinanceRecordModel>> searchFinanceRecords(String searchTerm) async {
    final query = select(financeRecords)
      ..where((f) => 
        f.category.contains(searchTerm) |
        f.notes.contains(searchTerm)
      )
      ..orderBy([(f) => OrderingTerm.desc(f.time)]);
    
    final rows = await query.get();
    return rows.map((row) => FinanceRecordModel.fromDrift(row)).toList();
  }
}
