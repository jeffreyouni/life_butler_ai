import 'package:drift/drift.dart';
import '../database/database.dart';
import '../database/tables.dart';

part 'career_dao.g.dart';

@DriftAccessor(tables: [Career])
class CareerDao extends DatabaseAccessor<LifeButlerDatabase> with _$CareerDaoMixin {
  CareerDao(LifeButlerDatabase db) : super(db);

  Future<List<CareerData>> getAllCareers() async {
    final query = select(career)
      ..orderBy([(c) => OrderingTerm.desc(c.startDate)]);
    
    return await query.get();
  }

  Future<List<CareerData>> getCareersByCompany(String company) async {
    final query = select(career)
      ..where((c) => c.company.contains(company))
      ..orderBy([(c) => OrderingTerm.desc(c.startDate)]);
    
    return await query.get();
  }

  Future<CareerData?> getCareerById(String id) async {
    final query = select(career)..where((c) => c.id.equals(id));
    return await query.getSingleOrNull();
  }

  Future<int> insertCareer(CareerCompanion careerData) async {
    return await into(career).insert(careerData);
  }

  Future<bool> updateCareer(String id, CareerCompanion careerData) async {
    return await (update(career)..where((c) => c.id.equals(id))).write(careerData) > 0;
  }

  Future<bool> deleteCareer(String id) async {
    return await (delete(career)..where((c) => c.id.equals(id))).go() > 0;
  }

  Future<List<CareerData>> searchCareers(String searchTerm) async {
    final query = select(career)
      ..where((c) => 
        c.role.contains(searchTerm) |
        c.company.contains(searchTerm) |
        c.notes.contains(searchTerm)
      )
      ..orderBy([(c) => OrderingTerm.desc(c.startDate)]);
    
    return await query.get();
  }
}
