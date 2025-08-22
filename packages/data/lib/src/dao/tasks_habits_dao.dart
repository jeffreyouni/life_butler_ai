import 'package:drift/drift.dart';
import '../database/database.dart';
import '../models/task_habit_model.dart';

part 'tasks_habits_dao.g.dart';

@DriftAccessor(tables: [TasksHabits])
class TasksHabitsDao extends DatabaseAccessor<LifeButlerDatabase> with _$TasksHabitsDaoMixin {
  TasksHabitsDao(LifeButlerDatabase db) : super(db);

  Future<List<TaskHabitModel>> getAllTasksHabits() async {
    final query = select(tasksHabits)
      ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]);
    
    final rows = await query.get();
    return rows.map((row) => TaskHabitModel.fromDrift(row)).toList();
  }

  Future<List<TaskHabitModel>> getTasksHabitsByType(String type) async {
    final query = select(tasksHabits)
      ..where((t) => t.type.equals(type))
      ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]);
    
    final rows = await query.get();
    return rows.map((row) => TaskHabitModel.fromDrift(row)).toList();
  }

  Future<List<TaskHabitModel>> getActiveTasksHabits() async {
    final query = select(tasksHabits)
      ..where((t) => t.isActive.equals(true))
      ..orderBy([(t) => OrderingTerm.desc(t.priority)]);
    
    final rows = await query.get();
    return rows.map((row) => TaskHabitModel.fromDrift(row)).toList();
  }

  Future<TaskHabitModel?> getTaskHabitById(int id) async {
    final query = select(tasksHabits)..where((t) => t.id.equals(id));
    final row = await query.getSingleOrNull();
    return row != null ? TaskHabitModel.fromDrift(row) : null;
  }

  Future<int> insertTaskHabit(TaskHabitModel taskHabit) async {
    final companion = TasksHabitsCompanion(
      userId: Value(taskHabit.userId),
      type: Value(taskHabit.type),
      title: Value(taskHabit.title),
      description: Value(taskHabit.description ?? ''),
      priority: Value(taskHabit.priority),
      status: Value(taskHabit.status),
      category: Value(taskHabit.category ?? ''),
      dueDate: Value(taskHabit.dueDate),
      frequency: Value(taskHabit.frequency ?? ''),
      streakCount: Value(taskHabit.streakCount),
      completedDates: Value(taskHabit.completedDates ?? ''),
      tags: Value(taskHabit.tags ?? ''),
      notes: Value(taskHabit.notes ?? ''),
      isActive: Value(taskHabit.isActive),
      createdAt: Value(taskHabit.createdAt),
      updatedAt: Value(taskHabit.updatedAt),
    );
    
    return await into(tasksHabits).insert(companion);
  }

  Future<bool> updateTaskHabit(TaskHabitModel taskHabit) async {
    final companion = TasksHabitsCompanion(
      userId: Value(taskHabit.userId),
      type: Value(taskHabit.type),
      title: Value(taskHabit.title),
      description: Value(taskHabit.description ?? ''),
      priority: Value(taskHabit.priority),
      status: Value(taskHabit.status),
      category: Value(taskHabit.category ?? ''),
      dueDate: Value(taskHabit.dueDate),
      frequency: Value(taskHabit.frequency ?? ''),
      streakCount: Value(taskHabit.streakCount),
      completedDates: Value(taskHabit.completedDates ?? ''),
      tags: Value(taskHabit.tags ?? ''),
      notes: Value(taskHabit.notes ?? ''),
      isActive: Value(taskHabit.isActive),
      updatedAt: Value(DateTime.now()),
    );
    
    return await (update(tasksHabits)..where((t) => t.id.equals(taskHabit.id))).write(companion) > 0;
  }

  Future<bool> deleteTaskHabit(int id) async {
    return await (delete(tasksHabits)..where((t) => t.id.equals(id))).go() > 0;
  }

  Future<List<TaskHabitModel>> getTasksHabitsByPriority(int minPriority) async {
    final query = select(tasksHabits)
      ..where((t) => t.priority.isBiggerOrEqualValue(minPriority))
      ..orderBy([(t) => OrderingTerm.desc(t.priority)]);
    
    final rows = await query.get();
    return rows.map((row) => TaskHabitModel.fromDrift(row)).toList();
  }

  Future<List<TaskHabitModel>> searchTasksHabits(String searchTerm) async {
    final query = select(tasksHabits)
      ..where((t) => 
        t.title.contains(searchTerm) |
        t.description.contains(searchTerm) |
        t.notes.contains(searchTerm)
      )
      ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]);
    
    final rows = await query.get();
    return rows.map((row) => TaskHabitModel.fromDrift(row)).toList();
  }
}
