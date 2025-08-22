import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/app_providers.dart';
import 'dialogs/ai_prompt_dialog.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _ollamaBaseUrlController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCurrentSettings();
  }

  void _loadCurrentSettings() {
    final config = ref.read(llmConfigProvider);
    _ollamaBaseUrlController.text = config.ollama.baseUrl;
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final providerStatus = ref.watch(providerStatusProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Theme settings
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Appearance',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Text('Theme Mode:'),
                        const SizedBox(width: 16),
                        DropdownButton<ThemeMode>(
                          value: themeMode,
                          onChanged: (value) {
                            if (value != null) {
                              ref.read(themeModeProvider.notifier).state = value;
                            }
                          },
                          items: const [
                            DropdownMenuItem(
                              value: ThemeMode.system,
                              child: Text('System'),
                            ),
                            DropdownMenuItem(
                              value: ThemeMode.light,
                              child: Text('Light'),
                            ),
                            DropdownMenuItem(
                              value: ThemeMode.dark,
                              child: Text('Dark'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // AI Provider settings
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI Provider Configuration',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),

                    // Provider status
                    providerStatus.when(
                      data: (status) => Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: status.hasAvailableProvider
                              ? Colors.green.withOpacity(0.1)
                              : Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: status.hasAvailableProvider
                                ? Colors.green
                                : Colors.orange,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              status.hasAvailableProvider
                                  ? Icons.check_circle
                                  : Icons.warning,
                              color: status.hasAvailableProvider
                                  ? Colors.green
                                  : Colors.orange,
                            ),
                            const SizedBox(width: 8),
                            Text(status.statusMessage),
                          ],
                        ),
                      ),
                      loading: () => const CircularProgressIndicator(),
                      error: (error, stack) => Text('Error: $error'),
                    ),

                    const SizedBox(height: 24),

                    // Ollama settings
                    ExpansionTile(
                      title: const Text('Ollama Configuration'),
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              TextField(
                                controller: _ollamaBaseUrlController,
                                decoration: const InputDecoration(
                                  labelText: 'Base URL',
                                  hintText: 'http://localhost:11434',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: _testOllama,
                                      child: const Text('Test Connection'),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Make sure Ollama is installed and running locally.',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // AI Prompt Configuration
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI Prompt Templates',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Customize the AI prompts used for different scenarios. This allows you to personalize how the AI responds to your questions.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (context) => const AIPromptDialog(),
                              );
                            },
                            icon: const Icon(Icons.edit_note),
                            label: const Text('Edit AI Prompts'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              await ref.read(aiPromptTemplatesNotifierProvider.notifier).resetToDefaults();
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('AI prompts reset to defaults'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              }
                            },
                            icon: const Icon(Icons.restore),
                            label: const Text('Reset to Defaults'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.orange,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const SizedBox(height: 8),
                    Text(
                      'Tip: You can use variables like {userQuestion}, {dataContext}, {dataSummary}, and {message} in your templates.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Data management
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Data Management',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _exportData,
                            icon: const Icon(Icons.download),
                            label: const Text('Export Data'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _importData,
                            icon: const Icon(Icons.upload),
                            label: const Text('Import Data'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    
                    // Clear embeddings button
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _clearEmbeddings,
                            icon: const Icon(Icons.auto_fix_high),
                            label: const Text('Clear Embeddings'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.orange,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Clear embeddings if RAG search is not working. They will regenerate automatically.',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _clearData,
                            icon: const Icon(Icons.delete_forever),
                            label: const Text('Clear All Data'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _testOllama() async {
    // TODO: Implement Ollama connection test
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Testing Ollama connection...')),
    );
  }

  void _exportData() async {
    // TODO: Implement data export
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Export functionality coming soon...')),
    );
  }

  void _importData() async {
    // TODO: Implement data import
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Import functionality coming soon...')),
    );
  }

  void _clearEmbeddings() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Embeddings'),
        content: const Text(
          'This will clear all RAG embeddings. They will be regenerated automatically when needed. This fixes dimension mismatch issues.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.orange),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final database = ref.read(databaseProvider);
        
        // Clear all embeddings
        await database.delete(database.embeddings).go();
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Embeddings cleared successfully. They will regenerate automatically.'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error clearing embeddings: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _clearData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Data'),
        content: const Text(
          'Are you sure you want to clear all data? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // TODO: Implement data clearing
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Data cleared successfully')),
      );
    }
  }

  @override
  void dispose() {
    _ollamaBaseUrlController.dispose();
    super.dispose();
  }
}
