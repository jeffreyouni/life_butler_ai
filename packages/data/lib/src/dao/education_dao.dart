import 'package:drift/drift.dart';
import '../database/database.dart';
import '../database/tables.dart';

part 'education_dao.g.dart';

@DriftAccessor(tables: [Education])
class EducationDao extends DatabaseAccessor<LifeButlerDatabase> with _$EducationDaoMixin {
  EducationDao(LifeButlerDatabase db) : super(db);

  Future<List<EducationData>> getAllEducation() async {
    final query = select(education)
      ..orderBy([(e) => OrderingTerm.desc(e.startDate)]);
    
    return await query.get();
  }

  Future<List<EducationData>> getEducationBySchoolName(String schoolName) async {
    final query = select(education)
      ..where((e) => e.schoolName.contains(schoolName))
      ..orderBy([(e) => OrderingTerm.desc(e.startDate)]);
    
    return await query.get();
  }

  Future<EducationData?> getEducationById(String id) async {
    final query = select(education)..where((e) => e.id.equals(id));
    return await query.getSingleOrNull();
  }

  Future<int> insertEducation(EducationCompanion educationData) async {
    return await into(education).insert(educationData);
  }

  Future<bool> updateEducation(String id, EducationCompanion educationData) async {
    return await (update(education)..where((e) => e.id.equals(id))).write(educationData) > 0;
  }

  Future<bool> deleteEducation(String id) async {
    return await (delete(education)..where((e) => e.id.equals(id))).go() > 0;
  }

  Future<List<EducationData>> searchEducation(String searchTerm) async {
    final query = select(education)
      ..where((e) => 
        e.schoolName.contains(searchTerm) |
        e.degree.contains(searchTerm) |
        e.major.contains(searchTerm) |
        e.notes.contains(searchTerm)
      )
      ..orderBy([(e) => OrderingTerm.desc(e.startDate)]);
    
    return await query.get();
  }
}
