/// Data layer with drift ORM, DAOs, migrations, and import/export
library data;

// Database
export 'src/database/database.dart';
export 'src/database/tables.dart';

// Domain models
export 'src/models/event_model.dart';
export 'src/models/education_model.dart';
export 'src/models/career_model.dart';
export 'src/models/meal_model.dart';
export 'src/models/journal_model.dart';
export 'src/models/health_metric_model.dart';
export 'src/models/finance_record_model.dart';
export 'src/models/task_habit_model.dart';
export 'src/models/relation_model.dart';
export 'src/models/media_log_model.dart';
export 'src/models/travel_log_model.dart';
export 'src/models/attachment_model.dart';
export 'src/models/embedding_model.dart';
export 'src/models/user_model.dart';

// Repositories
export 'src/repositories/drift_embedding_repository.dart';
export 'src/repositories/simple_chunk_processor.dart';

