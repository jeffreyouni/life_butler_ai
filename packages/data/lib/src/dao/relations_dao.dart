import 'package:drift/drift.dart';
import '../database/database.dart';
import '../models/relation_model.dart';

part 'relations_dao.g.dart';

@DriftAccessor(tables: [Relations])
class RelationsDao extends DatabaseAccessor<LifeButlerDatabase> with _$RelationsDaoMixin {
  RelationsDao(LifeButlerDatabase db) : super(db);

  Future<List<RelationModel>> getAllRelations() async {
    final query = select(relations)
      ..orderBy([(r) => OrderingTerm.desc(r.createdAt)]);
    
    final rows = await query.get();
    return rows.map((row) => RelationModel.fromDrift(row)).toList();
  }

  Future<List<RelationModel>> getRelationsByType(String relationType) async {
    final query = select(relations)
      ..where((r) => r.relationType.equals(relationType))
      ..orderBy([(r) => OrderingTerm.desc(r.createdAt)]);
    
    final rows = await query.get();
    return rows.map((row) => RelationModel.fromDrift(row)).toList();
  }

  Future<RelationModel?> getRelationById(int id) async {
    final query = select(relations)..where((r) => r.id.equals(id));
    final row = await query.getSingleOrNull();
    return row != null ? RelationModel.fromDrift(row) : null;
  }

  Future<int> insertRelation(RelationModel relation) async {
    final companion = RelationsCompanion(
      userId: Value(relation.userId),
      personName: Value(relation.personName),
      relationType: Value(relation.relationType),
      relationshipStatus: Value(relation.relationshipStatus ?? ''),
      contactInfo: Value(relation.contactInfo ?? ''),
      importanceLevel: Value(relation.importanceLevel),
      notes: Value(relation.notes ?? ''),
      lastContactDate: Value(relation.lastContactDate),
      birthDate: Value(relation.birthDate),
      anniversaryDate: Value(relation.anniversaryDate),
      tags: Value(relation.tags ?? ''),
      isActive: Value(relation.isActive),
      createdAt: Value(relation.createdAt),
      updatedAt: Value(relation.updatedAt),
    );
    
    return await into(relations).insert(companion);
  }

  Future<bool> updateRelation(RelationModel relation) async {
    final companion = RelationsCompanion(
      userId: Value(relation.userId),
      personName: Value(relation.personName),
      relationType: Value(relation.relationType),
      relationshipStatus: Value(relation.relationshipStatus ?? ''),
      contactInfo: Value(relation.contactInfo ?? ''),
      importanceLevel: Value(relation.importanceLevel),
      notes: Value(relation.notes ?? ''),
      lastContactDate: Value(relation.lastContactDate),
      birthDate: Value(relation.birthDate),
      anniversaryDate: Value(relation.anniversaryDate),
      tags: Value(relation.tags ?? ''),
      isActive: Value(relation.isActive),
      updatedAt: Value(DateTime.now()),
    );
    
    return await (update(relations)..where((r) => r.id.equals(relation.id))).write(companion) > 0;
  }

  Future<bool> deleteRelation(int id) async {
    return await (delete(relations)..where((r) => r.id.equals(id))).go() > 0;
  }

  Future<List<RelationModel>> getRelationsByImportance(int minImportance) async {
    final query = select(relations)
      ..where((r) => r.importanceLevel.isBiggerOrEqualValue(minImportance))
      ..orderBy([(r) => OrderingTerm.desc(r.importanceLevel)]);
    
    final rows = await query.get();
    return rows.map((row) => RelationModel.fromDrift(row)).toList();
  }

  Future<List<RelationModel>> searchRelations(String searchTerm) async {
    final query = select(relations)
      ..where((r) => 
        r.personName.contains(searchTerm) |
        r.notes.contains(searchTerm) |
        r.tags.contains(searchTerm)
      )
      ..orderBy([(r) => OrderingTerm.desc(r.createdAt)]);
    
    final rows = await query.get();
    return rows.map((row) => RelationModel.fromDrift(row)).toList();
  }
}
