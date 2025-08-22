import 'dart:developer' as developer;

/// Logger utility for the Life Butler AI project
/// Provides consistent logging across all packages with different levels
class Logger {
  Logger(this.name);

  final String name;

  /// Log a debug message
  void debug(String message) {
    developer.log('[DEBUG] $message', name: name, level: 500);
  }

  /// Log an info message
  void info(String message) {
    developer.log('[INFO] $message', name: name, level: 800);
  }

  /// Log a warning message
  void warning(String message) {
    developer.log('[WARNING] $message', name: name, level: 900);
  }

  /// Log an error message
  void error(String message, [Object? error, StackTrace? stackTrace]) {
    developer.log(
      '[ERROR] $message',
      name: name,
      error: error,
      stackTrace: stackTrace,
      level: 1000,
    );
  }

  /// Log a verbose message (for detailed debugging)
  void verbose(String message) {
    developer.log('[VERBOSE] $message', name: name, level: 300);
  }

  /// Create a child logger with a sub-name
  Logger child(String subName) {
    return Logger('$name.$subName');
  }
}

/// Global logger instances for different components
class Loggers {
  static final app = Logger('App');
  static final database = Logger('Database');
  static final ai = Logger('AI');
  static final router = Logger('Router');
  static final rag = Logger('RAG');
  static final embedding = Logger('Embedding');
  static final ollama = Logger('Ollama');
  static final ui = Logger('UI');
}
