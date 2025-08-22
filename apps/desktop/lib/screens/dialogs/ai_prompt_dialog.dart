import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/app_providers.dart';

class AIPromptDialog extends ConsumerStatefulWidget {
  const AIPromptDialog({super.key});

  @override
  ConsumerState<AIPromptDialog> createState() => _AIPromptDialogState();
}

class _AIPromptDialogState extends ConsumerState<AIPromptDialog> {
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, String> _promptLabels = {
    'system_prompt': 'System prompt',
    'user_message_template': 'User message template',
    'rag_prompt_template': 'RAG search prompt template',
    'no_data_message': 'No-data message',
    'ai_unavailable_message': 'AI unavailable message',
  };
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    // Initialize empty controllers first
    for (final key in _promptLabels.keys) {
      _controllers[key] = TextEditingController();
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final prompts = ref.watch(aiPromptTemplatesProvider);
    
    // Only initialize controllers once when dialog first loads and prompts are available
    if (!_initialized && prompts.isNotEmpty) {
      for (final entry in prompts.entries) {
        _controllers[entry.key]?.text = entry.value;
      }
      _initialized = true;
    }
    
    // If prompts are still empty, show loading indicator
    if (prompts.isEmpty) {
      return Dialog(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.8,
          height: MediaQuery.of(context).size.height * 0.8,
          padding: const EdgeInsets.all(16),
          child: const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Loading AI prompt templates...'),
              ],
            ),
          ),
        ),
      );
    }
    
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  Icons.edit_note,
                  size: 28,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Text(
                  'AI Prompt Management',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 16),

            // Instructions
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 20,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Prompt Instructions',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• Use variables in the user message template: {userQuestion} and {dataContext}\n'
                    '• AI-unavailable message can use: {dataSummary}\n'
                    '• No-data message can use: {message}\n'
                    '• Changes take effect immediately',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Prompt editors
            Expanded(
              child: DefaultTabController(
                length: _promptLabels.length,
                child: Column(
                  children: [
                    TabBar(
                      isScrollable: true,
                      tabs: _promptLabels.values
                          .map((label) => Tab(text: label))
                          .toList(),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: TabBarView(
                        children: _promptLabels.entries.map((entry) {
                          return _buildPromptEditor(entry.key, entry.value);
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Action buttons
            Row(
              children: [
                TextButton.icon(
                  onPressed: _resetToDefaults,
                  icon: const Icon(Icons.restore),
                  label: const Text('Reset to defaults'),
                  style: TextButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.error,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: _savePrompts,
                  icon: const Icon(Icons.save),
                  label: const Text('Save'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPromptEditor(String key, String label) {
    final controller = _controllers[key]!;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(width: 8),
            Text(
              '(${controller.text.length} chars)',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Expanded(
          child: TextField(
            controller: controller,
            maxLines: null,
            expands: true,
            textAlignVertical: TextAlignVertical.top,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              hintText: 'Enter $label...',
              contentPadding: const EdgeInsets.all(16),
            ),
            style: const TextStyle(fontSize: 14),
            onChanged: (value) {
              setState(() {}); // Update character count
            },
          ),
        ),
        const SizedBox(height: 8),
        if (key == 'user_message_template')
          Text(
            'Available variables: {userQuestion}, {dataContext}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontStyle: FontStyle.italic,
            ),
          )
        else if (key == 'ai_unavailable_message')
          Text(
            'Available variables: {dataSummary}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontStyle: FontStyle.italic,
            ),
          )
        else if (key == 'no_data_message')
          Text(
            'Available variables: {message}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontStyle: FontStyle.italic,
            ),
          ),
      ],
    );
  }

  void _resetToDefaults() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset prompts'),
        content: const Text('Are you sure you want to reset all prompts to their default values? This will discard your custom changes.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(aiPromptTemplatesNotifierProvider.notifier).resetToDefaults();
      
      // Update controllers with default values
      final defaultPrompts = ref.read(aiPromptTemplatesProvider);
      for (final entry in defaultPrompts.entries) {
        _controllers[entry.key]?.text = entry.value;
      }
      
      setState(() {});
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Prompts reset to defaults'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  void _savePrompts() async {
    // Save all prompts
    for (final entry in _controllers.entries) {
      await ref.read(aiPromptTemplatesNotifierProvider.notifier).updatePrompt(
        entry.key,
        entry.value.text,
      );
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('AI prompts saved'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.of(context).pop();
    }
  }
}
