import 'package:meta/meta.dart';

/// Configuration for LLM providers
@immutable
class LLMConfig {
  const LLMConfig({
    required this.ollama,
  });

  final OllamaConfig ollama;

  /// Create config from environment variables
  factory LLMConfig.fromEnvironment(Map<String, String> env) {
    return LLMConfig(
      ollama: OllamaConfig(
        baseUrl: env['OLLAMA_BASE_URL'] ?? 'http://localhost:11434',
        chatModel: env['OLLAMA_CHAT_MODEL'] ?? 'mistral',
        embeddingModel: env['OLLAMA_EMBED_MODEL'] ?? 'nomic-embed-text',
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'ollama': ollama.toMap(),
    };
  }
}

@immutable
class OllamaConfig {
  const OllamaConfig({
    required this.baseUrl,
    required this.chatModel,
    required this.embeddingModel,
  });

  final String baseUrl;
  final String chatModel;
  final String embeddingModel;

  bool get isConfigured => baseUrl.isNotEmpty;

  Map<String, dynamic> toMap() {
    return {
      'base_url': baseUrl,
      'chat_model': chatModel,
      'embedding_model': embeddingModel,
    };
  }

  OllamaConfig copyWith({
    String? baseUrl,
    String? chatModel,
    String? embeddingModel,
  }) {
    return OllamaConfig(
      baseUrl: baseUrl ?? this.baseUrl,
      chatModel: chatModel ?? this.chatModel,
      embeddingModel: embeddingModel ?? this.embeddingModel,
    );
  }
}
