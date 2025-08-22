import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:core/core.dart';
import 'package:providers_llm/providers_llm.dart';

import '../providers/app_providers.dart';
import '../services/intelligent_chat_processor.dart';
import 'dialogs/ai_prompt_dialog.dart';

/// Enhanced AI screen with intelligent request routing
class EnhancedAIScreen extends ConsumerStatefulWidget {
  const EnhancedAIScreen({super.key});

  @override
  ConsumerState<EnhancedAIScreen> createState() => _EnhancedAIScreenState();
}

class _EnhancedAIScreenState extends ConsumerState<EnhancedAIScreen> {
  static final _logger = Logger('EnhancedAIScreen');
  
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  bool _useStreamingOutput = true;

  // Intelligent chat processor
  late IntelligentChatProcessor _chatProcessor;

  @override
  void initState() {
    super.initState();
    _initializeComponents();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _initializeComponents() {
    // Initialize chat processor when providers are ready
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        // Use the intelligent chat processor from providers
        _chatProcessor = await ref.read(intelligentChatProcessorProvider.future);
        
        _logger.info('✅ Intelligent chat processor initialized successfully');
      } catch (e) {
        _logger.error('❌ Failed to initialize chat processor: $e');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final providerStatus = ref.watch(providerStatusProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Assistant'),
        centerTitle: true,
        actions: [
          // Processing mode toggle
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _useStreamingOutput ? Icons.auto_awesome : Icons.calculate,
                  size: 20,
                ),
                const SizedBox(width: 4),
                Text(
                  _useStreamingOutput ? 'Smart' : 'Calc',
                  style: const TextStyle(fontSize: 12),
                ),
                Switch(
                  value: _useStreamingOutput,
                  onChanged: (value) {
                    setState(() {
                      _useStreamingOutput = value;
                    });
                  },
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_note),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => const AIPromptDialog(),
              );
            },
            tooltip: 'Edit AI Prompts',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(providerStatusProvider);
            },
            tooltip: 'Refresh Provider Status',
          ),
        ],
      ),
      body: Column(
        children: [
          // Status banners
          _buildStatusBanners(providerStatus),

          // Chat messages
          Expanded(
            child: _messages.isEmpty
                ? _buildWelcomeScreen()
                : ListView.builder(
                    controller: _scrollController,
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      return _buildMessageBubble(message);
                    },
                  ),
          ),

          // Loading indicator
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: LinearProgressIndicator(),
            ),

          // Input area
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildStatusBanners(AsyncValue<ProviderStatus> providerStatus) {
    return Column(
      children: [
        // Provider status
        providerStatus.when(
          data: (status) => status.hasAvailableProvider
              ? Container()
              : Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  color: Theme.of(context).colorScheme.errorContainer,
                  child: Text(
                    'No AI provider available. Smart routing will use calculation mode.',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onErrorContainer,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
          loading: () => Container(),
          error: (error, stack) => Container(),
        ),

        // Request routing status
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(6),
          color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
          child: Text(
            _useStreamingOutput 
                ? '🧠 Smart Routing: Calculation + Generation' 
                : '🔢 Calculation Mode: Aggregation Focus',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onPrimaryContainer,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  Widget _buildWelcomeScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.psychology,
            size: 64,
            color: Theme.of(context).colorScheme.secondary,
          ),
          const SizedBox(height: 16),
          Text(
            'Enhanced AI Assistant',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Ask me anything - I\'ll route your request optimally!',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 16),
          
          // Sample queries categorized by processing type
          _buildSampleQuerySection('Calculation Queries', [
            'How much did I spend this month?',
            'What\'s my average meal calories?',
            'Count my journal entries this week',
          ], Icons.calculate),
          
          const SizedBox(height: 16),
          
          _buildSampleQuerySection('Generation Queries', [
            'Why am I spending so much on food?',
            'Give me advice on my sleep habits',
            'Explain my mood patterns',
          ], Icons.auto_awesome),

          const SizedBox(height: 16),
          
          _buildSampleQuerySection('Hybrid Queries', [
            'Analyze my spending and suggest improvements',
            'Show spending trends and explain them',
            'Calculate calories and recommend diet changes',
          ], Icons.merge_type),
        ],
      ),
    );
  }

  Widget _buildSampleQuerySection(String title, List<String> queries, IconData icon) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: queries.map((query) => _buildSampleQuery(query)).toList(),
        ),
      ],
    );
  }

  Widget _buildSampleQuery(String query) {
    return ActionChip(
      label: Text(query, style: const TextStyle(fontSize: 12)),
      onPressed: () {
        _messageController.text = query;
        _sendMessage();
      },
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: const InputDecoration(
                hintText: 'Ask me anything about your life data...',
                border: OutlineInputBorder(),
              ),
              maxLines: null,
              onSubmitted: (value) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          FilledButton.icon(
            onPressed: _isLoading ? null : _sendMessage,
            icon: const Icon(Icons.send),
            label: const Text('Send'),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final isUser = message.isUser;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.secondary,
              child: Icon(
                message.processingType != null 
                    ? _getProcessingIcon(message.processingType!)
                    : Icons.psychology, 
                color: Colors.white
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isUser
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Processing type indicator for AI messages
                  if (!isUser && message.processingType != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _getProcessingTypeLabel(message.processingType!),
                        style: TextStyle(
                          fontSize: 10,
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  
                  // Message content
                  isUser
                      ? Text(
                          message.content,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onPrimary,
                          ),
                        )
                      : MarkdownBody(
                          data: message.content,
                          styleSheet: MarkdownStyleSheet.fromTheme(
                            Theme.of(context),
                          ).copyWith(
                            p: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                ],
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: const Icon(Icons.person, color: Colors.white),
            ),
          ],
        ],
      ),
    );
  }

  IconData _getProcessingIcon(ProcessingPath processingType) {
    switch (processingType) {
      case ProcessingPath.calculation:
        return Icons.calculate;
      case ProcessingPath.retrieval:
        return Icons.auto_awesome;
      case ProcessingPath.hybrid:
        return Icons.merge_type;
    }
  }

  String _getProcessingTypeLabel(ProcessingPath processingType) {
    switch (processingType) {
      case ProcessingPath.calculation:
        return 'CALCULATION';
      case ProcessingPath.retrieval:
        return 'GENERATION';
      case ProcessingPath.hybrid:
        return 'HYBRID';
    }
  }

  void _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    _logger.debug('📤 USER MESSAGE SENT: $message');

    setState(() {
      _messages.add(ChatMessage(content: message, isUser: true));
      _messageController.clear();
      _isLoading = true;
    });

    _scrollToBottom();

    try {
      // Process the query using intelligent chat processor
      final response = await _chatProcessor.processQuery(message);
      
      _logger.debug('🧠 Chat response generated');
      _logger.debug('📊 Confidence: ${(response.confidence * 100).toStringAsFixed(1)}%');
      _logger.debug('🌐 Language: ${response.language}');
      _logger.debug('🎯 Processing path: ${response.processingPath}');

      if (mounted) {
        setState(() {
          _messages.add(ChatMessage(
            content: response.answer,
            isUser: false,
            processingType: response.processingPath,
            confidence: response.confidence,
            processingTime: response.processingTime,
            language: response.language,
          ));
          _isLoading = false;
        });
      }

      _scrollToBottom();
      
    } catch (e) {
      _logger.error('❌ Chat processing error: $e');
      if (mounted) {
        setState(() {
          _messages.add(ChatMessage(
            content: 'I apologize, but I encountered an error: $e',
            isUser: false,
          ));
          _isLoading = false;
        });
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeOut,
        );
      }
    });
  }
}

class ChatMessage {
  final String content;
  final bool isUser;
  final ProcessingPath? processingType;
  final double? confidence;
  final Duration? processingTime;
  final String? language;

  ChatMessage({
    required this.content, 
    required this.isUser,
    this.processingType,
    this.confidence,
    this.processingTime,
    this.language,
  });
}
