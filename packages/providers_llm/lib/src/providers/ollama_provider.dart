import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:core/core.dart' show Logger;
import '../model_provider.dart';
import '../message.dart';

/// Ollama local LLM provider
class OllamaProvider extends BaseModelProvider {
  OllamaProvider({
    this.baseUrl = 'http://localhost:11434',
    this.chatModel = 'mistral',
    this.embeddingModel = 'nomic-embed-text',
    this.timeout = const Duration(minutes: 10),
  });

  final String baseUrl;
  final String chatModel;
  final String embeddingModel;
  final Duration timeout;
  
  static final _logger = Logger('Ollama');

  @override
  String get name => 'Ollama';

  /// Get appropriate context size for the model
  int get contextSize {
    // Set context size based on model type
    if (chatModel.contains('mistral')) {
      return 32768; // Mistral supports very large context
    } else if (chatModel.contains('llama3') || chatModel.contains('llama-3')) {
      return 8192;
    } else if (chatModel.contains('nomic-embed') || embeddingModel.contains('nomic-embed')) {
      return 2048;
    }
    return 8192; // Better default for most modern models
  }

  @override
  Future<bool> get isAvailable async {
    try {
      return await testConnection();
    } catch (e) {
      return false;
    }
  }

  @override
  Future<List<List<double>>> embed(List<String> texts) async {
    if (texts.isEmpty) return [];

    try {
      // For the nomic-embed-text model, process texts individually to avoid context issues
      // The "decode: cannot decode batches with this context" error occurs when batch processing
      // Use individual processing by default as it's more reliable
      return await _embedIndividually(texts);
    } catch (e) {
      _logger.error('Critical Ollama embedding error', e);
      _logger.warning('Texts count: ${texts.length}');
      _logger.warning('Using zero vector fallback for all texts');
      // Return zero vectors as fallback to prevent crashes
      return List.generate(texts.length, (_) => List.filled(768, 0.0));
    }
  }

  /// Fallback method to process embeddings individually
  Future<List<List<double>>> _embedIndividually(List<String> texts) async {
    final embeddings = <List<double>>[];
    
    for (int i = 0; i < texts.length; i++) {
      final text = texts[i];
      try {
        // Truncate text to prevent context issues
        final truncatedText = text.length > 1000 ? text.substring(0, 1000) : text;
        
        final requestBody = {
          'model': embeddingModel,
          'input': truncatedText,
          'options': {
            'num_ctx': 512,  // Use smaller context window to avoid "decode" error
            'temperature': 0.0,
            'num_predict': 0, // Don't predict, just embed
          },
        };

        
        _logger.debug('Embedding API request ${i + 1}/${texts.length}: URL=$baseUrl/api/embed, Model=$embeddingModel, InputLength=${truncatedText.length}');
        _logger.verbose('Input preview: ${truncatedText.substring(0, truncatedText.length.clamp(0, 100))}...');
        _logger.verbose('Request body: ${json.encode(requestBody)}');
        
        final response = await http.post(
          Uri.parse('$baseUrl/api/embed'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode(requestBody),
        ).timeout(const Duration(seconds: 30));

        
        _logger.debug('Embedding API response ${i + 1}/${texts.length}: StatusCode=${response.statusCode}, BodyLength=${response.body.length}');
        _logger.verbose('Response headers: ${response.headers}');

        if (response.statusCode != 200) {
          _logger.error('Ollama embedding API error: ${response.statusCode}');
          _logger.error('Error response body: ${response.body}');
          _logger.warning('Using zero vector fallback for text: ${truncatedText.substring(0, truncatedText.length.clamp(0, 50))}...');
          embeddings.add(List.filled(768, 0.0)); // Default embedding size for nomic-embed-text
          continue;
        }

        final data = json.decode(response.body);
        _logger.debug('Ollama embedding API success ${i + 1}/${texts.length}');
        _logger.verbose('Response keys: ${data.keys.toList()}');
        _logger.debug('Full response:');
        _logger.verbose(response.body);

        final embeddingData = data['embeddings'] ?? data['embedding'];
        _logger.verbose('EmbeddingData type: ${embeddingData.runtimeType}');
        
        if (embeddingData is List && embeddingData.isNotEmpty) {
          _logger.verbose('EmbeddingData length: ${embeddingData.length}');
          _logger.verbose('First element type: ${embeddingData[0].runtimeType}');
          
          List<double> embedding;
          if (embeddingData[0] is List) {
            // Multiple embeddings returned, take the first one
            embedding = (embeddingData[0] as List).map((e) => (e as num).toDouble()).toList();
            _logger.verbose('Parsed as multiple embeddings, took first: ${embedding.length}D');
          } else {
            // Single embedding returned as flat array
            embedding = embeddingData.map((e) => (e as num).toDouble()).toList();
            _logger.verbose('Parsed as single embedding: ${embedding.length}D');
          }
          
          // Verify the embedding is valid
          final isZero = embedding.every((v) => v == 0.0);
          final vectorSum = embedding.fold(0.0, (a, b) => a + b);
          _logger.verbose('Embedding stats: length=${embedding.length}, sum=${vectorSum.toStringAsFixed(6)}, isZero=$isZero');
          
          if (isZero) {
            _logger.warning('Generated embedding is a zero vector!');
          }
          
          embeddings.add(embedding);
        } else {
          _logger.error('Invalid embedding data format: Type=${embeddingData.runtimeType}, Value=$embeddingData');
          _logger.warning('Using zero vector fallback');
          embeddings.add(List.filled(768, 0.0));
        }
        
        // Add small delay between requests to prevent overwhelming Ollama
        await Future.delayed(const Duration(milliseconds: 50));
        
      } catch (e) {
        _logger.error('Exception processing embedding for text: ${text.substring(0, text.length.clamp(0, 50))}...', e);
        _logger.warning('Using zero vector fallback');
        embeddings.add(List.filled(768, 0.0));
      }
    }
    
    return embeddings;
  }

  @override
  Future<String> chat(
    List<Message> messages, {
    double temperature = 0.7,
    int? maxTokens,
    List<String>? stop,
  }) async {
    try {
      // Convert messages to Ollama format
      final prompt = _messagesToPrompt(messages);

      final requestBody = {
        'model': chatModel,
        'prompt': prompt,
        'stream': false,
        'options': {
          'temperature': validateTemperature(temperature),
          'num_ctx': contextSize, // Use dynamic context size based on model
          if (maxTokens != null) 'num_predict': maxTokens,
          if (stop != null && stop.isNotEmpty) 'stop': stop,
        },
      };

      
      _logger.debug('Chat API request: URL=$baseUrl/api/generate, Model=$chatModel, Temperature=${validateTemperature(temperature)}');
      _logger.debug('Chat config: MaxTokens=$maxTokens, ContextSize=$contextSize, StopWords=$stop');
      _logger.debug('Prompt length: ${prompt.length} chars');
      _logger.verbose('Prompt preview: ${prompt.substring(0, prompt.length.clamp(0, 200))}...');
      _logger.debug('Full Request body:');
      _logger.verbose(json.encode(requestBody));

      final response = await http.post(
        Uri.parse('$baseUrl/api/generate'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestBody),
      ).timeout(timeout);

      
      _logger.debug('Chat API response: StatusCode=${response.statusCode}, BodyLength=${response.body.length}');
      _logger.verbose('Response headers: ${response.headers}');
      _logger.verbose('Response body: ${response.body}');

      if (response.statusCode != 200) {
        _logger.error('Ollama chat API error: ${response.statusCode}');
        _logger.error('Error body: ${response.body}');
        throw Exception('Ollama API error: ${response.statusCode} ${response.body}');
      }

      final data = json.decode(response.body);
      final aiResponse = data['response'] ?? '';
      
      
      _logger.debug('Chat API success: ResponseLength=${aiResponse.length} chars');
      _logger.verbose('Response keys: ${data.keys.toList()}');
      _logger.verbose('AI response: $aiResponse');
      _logger.verbose('Additional data: ${data..remove('response')}');
      
      return aiResponse;
    } catch (e, stackTrace) {
      _logger.error('Ollama chat API exception', e, stackTrace);
      return handleApiError(e, stackTrace);
    }
  }

  @override
  Stream<String> chatStream(
    List<Message> messages, {
    double temperature = 0.7,
    int? maxTokens,
    List<String>? stop,
  }) async* {
    try {
      final prompt = _messagesToPrompt(messages);

      final requestBody = {
        'model': chatModel,
        'prompt': prompt,
        'stream': true,
        'options': {
          'temperature': validateTemperature(temperature),
          'num_ctx': contextSize, // Use dynamic context size based on model
          if (maxTokens != null) 'num_predict': maxTokens,
          if (stop != null && stop.isNotEmpty) 'stop': stop,
        },
      };

      
      _logger.debug('Chat stream API request: URL=$baseUrl/api/generate, Model=$chatModel, StreamMode=true');
      _logger.debug('Stream config: Temperature=${validateTemperature(temperature)}, MaxTokens=$maxTokens, ContextSize=$contextSize');
      _logger.debug('Prompt length: ${prompt.length} chars');
      _logger.verbose('Prompt preview: ${prompt.substring(0, prompt.length.clamp(0, 200))}...');

      final request = http.Request('POST', Uri.parse('$baseUrl/api/generate'));
      request.headers['Content-Type'] = 'application/json';
      request.body = json.encode(requestBody);

      final streamedResponse = await http.Client().send(request);

      
      _logger.debug('Chat stream response: StatusCode=${streamedResponse.statusCode}');
      _logger.verbose('Response headers: ${streamedResponse.headers}');

      if (streamedResponse.statusCode != 200) {
        _logger.error('Ollama chat stream error: ${streamedResponse.statusCode}');
        throw Exception('Ollama API error: ${streamedResponse.statusCode}');
      }

      var chunkCount = 0;
      await for (final chunk in streamedResponse.stream.transform(utf8.decoder)) {
        chunkCount++;
        _logger.verbose('Stream chunk $chunkCount: ${chunk.length} chars');
        _logger.verbose('Raw chunk: ${chunk.substring(0, chunk.length.clamp(0, 200))}...');
        
        final lines = chunk.split('\n').where((line) => line.trim().isNotEmpty);
        
        for (final line in lines) {
          try {
            final data = json.decode(line);
            _logger.verbose('Parsed JSON: ${data.keys.toList()}');
            
            final response = data['response'];
            if (response != null && response.isNotEmpty) {
              _logger.verbose('Yielding: "$response"');
              yield response;
            }
            
            // Check if this is the final chunk
            if (data['done'] == true) {
              _logger.debug('Stream completed (done=true)');
              return;
            }
          } catch (e) {
            // Skip malformed JSON chunks
            _logger.warning('Skipping malformed JSON: $e');
            continue;
          }
        }
      }
      _logger.debug('Chat stream completed');
    } catch (e, stackTrace) {
      _logger.error('Ollama chat stream exception', e, stackTrace);
      yield handleApiError(e, stackTrace);
    }
  }

  @override
  Future<bool> testConnection() async {
    try {
      // First test basic connectivity
      final tagsResponse = await http.get(
        Uri.parse('$baseUrl/api/tags'),
      ).timeout(const Duration(seconds: 10));

      if (tagsResponse.statusCode != 200) return false;

      // Then test if the embedding model is available
      try {
        final modelsData = json.decode(tagsResponse.body);
        final models = modelsData['models'] as List?;
        
        if (models != null) {
          final hasEmbeddingModel = models.any((model) => 
            model['name']?.toString().startsWith(embeddingModel) == true ||
            model['model']?.toString().startsWith(embeddingModel) == true
          );
          
          if (!hasEmbeddingModel) {
            _logger.warning('Embedding model $embeddingModel not found in Ollama');
            return false;
          }
        }
        
        // Test a simple embedding to ensure the model works
        final testResponse = await http.post(
          Uri.parse('$baseUrl/api/embed'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'model': embeddingModel,
            'input': 'test',
            'options': {
              'num_ctx': 512,
              'temperature': 0.0,
            },
          }),
        ).timeout(const Duration(seconds: 15));
        
        return testResponse.statusCode == 200;
      } catch (e) {
        _logger.warning('Could not verify embedding model: $e');
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  @override
  Future<ModelInfo> getModelInfo() async {
    try {
      // Try to get model info from Ollama
      final response = await http.post(
        Uri.parse('$baseUrl/api/show'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'name': chatModel}),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // Get context length from model info if available
        final contextLength = data['model_info']?['general.context_length'] ?? 
                             data['context_length'] ?? 
                             contextSize;
        
        return ModelInfo(
          name: chatModel,
          maxTokens: contextLength,
          embeddingDimensions: 768, // Default for nomic-embed-text
          description: data['details']?['family'] ?? 'Ollama Local Model',
        );
      }
    } catch (e) {
      // Fall back to defaults
    }

    return ModelInfo(
      name: chatModel,
      maxTokens: contextSize,
      embeddingDimensions: 768,
      description: 'Ollama Local Model',
    );
  }

  /// Convert standard messages to Ollama prompt format
  String _messagesToPrompt(List<Message> messages) {
    final buffer = StringBuffer();

    for (final message in messages) {
      switch (message.role) {
        case MessageRole.system:
          buffer.writeln('System: ${message.content}');
          break;
        case MessageRole.user:
          buffer.writeln('Human: ${message.content}');
          break;
        case MessageRole.assistant:
          buffer.writeln('Assistant: ${message.content}');
          break;
      }
    }

  buffer.write('Assistant: ');
    return buffer.toString();
  }

  /// Check if a specific model is available
  Future<bool> isModelAvailable(String modelName) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/tags'),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final models = data['models'] as List?;
        if (models != null) {
          return models.any((model) => model['name']?.toString().contains(modelName) == true);
        }
      }
    } catch (e) {
      // Ignore errors
    }
    return false;
  }

  /// Pull a model if it's not available
  Future<void> pullModel(String modelName) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/pull'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'name': modelName}),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to pull model $modelName: ${response.body}');
    }
  }
}
