import 'model_provider.dart';
import 'providers/ollama_provider.dart';
import 'config.dart';

/// Provider selection strategy
enum ProviderStrategy {
  ollamaOnly,   // Use Ollama only
}

/// Service for selecting and managing model providers
class ProviderSelector {
  ProviderSelector({
    required this.config,
    this.strategy = ProviderStrategy.ollamaOnly,
  });

  final LLMConfig config;
  final ProviderStrategy strategy;

  ModelProvider? _primaryProvider;
  ModelProvider? _currentProvider;

  /// Get the current active provider
  Future<ModelProvider?> getCurrentProvider() async {
    if (_currentProvider != null) {
      // Check if current provider is still available
      if (await _currentProvider!.isAvailable) {
        return _currentProvider;
      } else {
        _currentProvider = null;
      }
    }

    return await _selectProvider();
  }

  /// Select the best available provider based on strategy
  Future<ModelProvider?> _selectProvider() async {
    await _initializeProviders();

    switch (strategy) {
      case ProviderStrategy.ollamaOnly:
        if (_primaryProvider != null && await _primaryProvider!.isAvailable) {
          _currentProvider = _primaryProvider;
          return _currentProvider;
        }
        break;
    }

    return null;
  }

  /// Initialize providers based on configuration
  Future<void> _initializeProviders() async {
    if (_primaryProvider == null && config.ollama.isConfigured) {
      _primaryProvider = OllamaProvider(
        baseUrl: config.ollama.baseUrl,
        chatModel: config.ollama.chatModel,
        embeddingModel: config.ollama.embeddingModel,
      );
    }
  }

  /// Get provider status information
  Future<ProviderStatus> getProviderStatus() async {
    await _initializeProviders();

    final ollamaAvailable = _primaryProvider != null 
        ? await _primaryProvider!.isAvailable 
        : false;

    return ProviderStatus(
      ollamaAvailable: ollamaAvailable,
      currentProvider: _currentProvider?.name,
      strategy: strategy,
    );
  }

  /// Force refresh of provider availability
  Future<void> refresh() async {
    _currentProvider = null;
    await getCurrentProvider();
  }

  /// Test all configured providers
  Future<Map<String, bool>> testAllProviders() async {
    await _initializeProviders();
    
    final results = <String, bool>{};
    
    if (_primaryProvider != null) {
      results['ollama'] = await _primaryProvider!.testConnection();
    }
    
    return results;
  }
}

/// Status information about providers
class ProviderStatus {
  const ProviderStatus({
    required this.ollamaAvailable,
    required this.currentProvider,
    required this.strategy,
  });

  final bool ollamaAvailable;
  final String? currentProvider;
  final ProviderStrategy strategy;

  bool get hasAvailableProvider => ollamaAvailable;

  String get statusMessage {
    if (!hasAvailableProvider) {
      return 'No LLM providers available. Please start Ollama.';
    }

    if (currentProvider != null) {
      return 'Using $currentProvider';
    }

    return 'Available: Ollama';
  }
}
