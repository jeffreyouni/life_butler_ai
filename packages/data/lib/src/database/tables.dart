import 'package:drift/drift.dart';
import 'dart:convert' show json;

/// Users table
class Users extends Table {
  TextColumn get id => text()();
  TextColumn get username => text().withLength(min: 1, max: 50)();
  TextColumn get email => text().withLength(min: 1, max: 255)();
  TextColumn get preferencesJson => text().map(const JsonConverter()).withDefault(const Constant('{}'))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Events table
class Events extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get title => text().withLength(min: 1, max: 255)();
  TextColumn get description => text().nullable()();
  TextColumn get tagsJson => text().map(const JsonConverter()).withDefault(const Constant('[]'))();
  DateTimeColumn get date => dateTime()();
  TextColumn get location => text().nullable()();
  TextColumn get attachmentsJson => text().map(const JsonConverter()).withDefault(const Constant('[]'))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Education table
class Education extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get schoolName => text().withLength(min: 1, max: 255)();
  TextColumn get degree => text().nullable()();
  TextColumn get major => text().nullable()();
  DateTimeColumn get startDate => dateTime()();
  DateTimeColumn get endDate => dateTime().nullable()();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Career table
class Career extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get company => text().withLength(min: 1, max: 255)();
  TextColumn get role => text().withLength(min: 1, max: 255)();
  DateTimeColumn get startDate => dateTime()();
  DateTimeColumn get endDate => dateTime().nullable()();
  TextColumn get achievementsJson => text().map(const JsonConverter()).withDefault(const Constant('[]'))();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Meals table
class Meals extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get name => text().withLength(min: 1, max: 255)();
  TextColumn get itemsJson => text().map(const JsonConverter()).withDefault(const Constant('[]'))();
  IntColumn get caloriesInt => integer().nullable()();
  DateTimeColumn get time => dateTime()();
  TextColumn get photoUrl => text().nullable()();
  TextColumn get location => text().nullable()();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Journals table
class Journals extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get contentMd => text()();
  IntColumn get moodInt => integer().nullable()();
  TextColumn get topicsJson => text().map(const JsonConverter()).withDefault(const Constant('[]'))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Health metrics table
class HealthMetrics extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get metricType => text().withLength(min: 1, max: 100)();
  RealColumn get valueNum => real()();
  TextColumn get unit => text().withLength(min: 1, max: 20)();
  DateTimeColumn get time => dateTime()();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Finance records table
class FinanceRecords extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get type => text().withLength(min: 1, max: 20)(); // 'income' or 'expense'
  RealColumn get amount => real()();
  TextColumn get currency => text().withLength(min: 1, max: 10).withDefault(const Constant('USD'))();
  DateTimeColumn get time => dateTime()();
  TextColumn get category => text().nullable()();
  TextColumn get tagsJson => text().map(const JsonConverter()).withDefault(const Constant('[]'))();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Tasks and habits table
class TasksHabits extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get title => text().withLength(min: 1, max: 255)();
  TextColumn get type => text().withLength(min: 1, max: 20)(); // 'task' or 'habit'
  TextColumn get scheduleJson => text().map(const JsonConverter()).withDefault(const Constant('{}'))();
  TextColumn get status => text().withLength(min: 1, max: 20).withDefault(const Constant('pending'))();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Relations table
class Relations extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get personName => text().withLength(min: 1, max: 255)();
  TextColumn get relationType => text().nullable()();
  TextColumn get notes => text().nullable()();
  TextColumn get importantDatesJson => text().map(const JsonConverter()).withDefault(const Constant('{}'))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Media logs table
class MediaLogs extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get title => text().withLength(min: 1, max: 255)();
  TextColumn get mediaType => text().withLength(min: 1, max: 50)();
  TextColumn get progress => text().nullable()();
  IntColumn get rating => integer().nullable()();
  DateTimeColumn get time => dateTime()();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Travel logs table
class TravelLogs extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get place => text().withLength(min: 1, max: 255)();
  DateTimeColumn get startDate => dateTime()();
  DateTimeColumn get endDate => dateTime().nullable()();
  TextColumn get companionsJson => text().map(const JsonConverter()).withDefault(const Constant('[]'))();
  RealColumn get cost => real().nullable()();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Attachments table
class Attachments extends Table {
  TextColumn get id => text()();
  TextColumn get objectType => text().withLength(min: 1, max: 50)();
  TextColumn get objectId => text()();
  TextColumn get fileName => text().withLength(min: 1, max: 255)();
  TextColumn get mime => text().withLength(min: 1, max: 100)();
  TextColumn get localPathOrUrl => text()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Embeddings table
class Embeddings extends Table {
  TextColumn get id => text()();
  TextColumn get objectType => text().withLength(min: 1, max: 50)();
  TextColumn get objectId => text()();
  TextColumn get chunkText => text()();
  BlobColumn get vectorBlob => blob()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// JSON converter for storing JSON data in TEXT columns
class JsonConverter extends TypeConverter<Map<String, dynamic>, String> {
  const JsonConverter();

  @override
  Map<String, dynamic> fromSql(String fromDb) {
    try {
      final decoded = json.decode(fromDb);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      return {};
    } catch (e) {
      return {};
    }
  }

  @override
  String toSql(Map<String, dynamic> value) {
    return json.encode(value);
  }
}
