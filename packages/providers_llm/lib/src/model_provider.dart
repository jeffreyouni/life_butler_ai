import 'package:meta/meta.dart';
import 'package:core/core.dart' show Logger;
import 'message.dart';

/// Abstract interface for LLM providers
abstract class ModelProvider {
  /// Provider name for identification
  String get name;

  /// Whether the provider is currently available
  Future<bool> get isAvailable;

  /// Generate embeddings for the given texts
  Future<List<List<double>>> embed(List<String> texts);

  /// Generate a chat response
  Future<String> chat(
    List<Message> messages, {
    double temperature = 0.7,
    int? maxTokens,
    List<String>? stop,
  });

  /// Stream a chat response (for real-time responses)
  Stream<String> chatStream(
    List<Message> messages, {
    double temperature = 0.7,
    int? maxTokens,
    List<String>? stop,
  });

  /// Test the provider connection
  Future<bool> testConnection();

  /// Get model information
  Future<ModelInfo> getModelInfo();
}

/// Information about a model
@immutable
class ModelInfo {
  const ModelInfo({
    required this.name,
    required this.maxTokens,
    required this.embeddingDimensions,
    this.description,
    this.version,
  });

  final String name;
  final int maxTokens;
  final int embeddingDimensions;
  final String? description;
  final String? version;
}

/// Base class for model providers with common functionality
abstract class BaseModelProvider implements ModelProvider {
  static final _logger = Logger('BaseModelProvider');
  
  const BaseModelProvider();

  /// Helper method to format messages for API calls
  List<Map<String, dynamic>> formatMessages(List<Message> messages) {
    return messages.map((msg) => msg.toMap()).toList();
  }

  /// Helper method to validate temperature
  double validateTemperature(double temperature) {
    return temperature.clamp(0.0, 2.0);
  }

  /// Helper method to handle API errors
  String handleApiError(Object error, StackTrace stackTrace) {
    _logger.info('API Error: $error');
    _logger.info('Stack trace: $stackTrace');
    return 'I apologize, but I encountered an error while processing your request. Please try again.';
  }

  @override
  Stream<String> chatStream(
    List<Message> messages, {
    double temperature = 0.7,
    int? maxTokens,
    List<String>? stop,
  }) async* {
    // Default implementation: just yield the complete response at once
    final response = await chat(
      messages,
      temperature: temperature,
      maxTokens: maxTokens,
      stop: stop,
    );
    yield response;
  }
}
