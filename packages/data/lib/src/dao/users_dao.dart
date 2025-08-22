import 'package:drift/drift.dart';
import '../database/database.dart';
import '../database/tables.dart';

part 'users_dao.g.dart';

@DriftAccessor(tables: [Users])
class UsersDao extends DatabaseAccessor<LifeButlerDatabase> with _$UsersDaoMixin {
  UsersDao(LifeButlerDatabase db) : super(db);

  Future<List<User>> getAllUsers() async {
    final query = select(users)
      ..orderBy([(u) => OrderingTerm.desc(u.createdAt)]);
    
    return await query.get();
  }

  Future<User?> getUserById(String id) async {
    final query = select(users)..where((u) => u.id.equals(id));
    return await query.getSingleOrNull();
  }

  Future<User?> getUserByEmail(String email) async {
    final query = select(users)..where((u) => u.email.equals(email));
    return await query.getSingleOrNull();
  }

  Future<User?> getActiveUser() async {
    final query = select(users)
      ..limit(1);
    return await query.getSingleOrNull();
  }

  Future<int> insertUser(UsersCompanion userData) async {
    return await into(users).insert(userData);
  }

  Future<bool> updateUser(String id, UsersCompanion userData) async {
    return await (update(users)..where((u) => u.id.equals(id))).write(userData) > 0;
  }

  Future<bool> deleteUser(String id) async {
    return await (delete(users)..where((u) => u.id.equals(id))).go() > 0;
  }
}
