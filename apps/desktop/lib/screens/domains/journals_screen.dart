import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/app_providers.dart';

class JournalsScreen extends ConsumerWidget {
  const JournalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final journalsAsync = ref.watch(journalsProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Journals & Notes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              // TODO: Add new journal entry
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Add journal functionality coming soon')),
              );
            },
            tooltip: 'New Entry',
          ),
        ],
      ),
      body: journalsAsync.when(
        data: (journals) {
          if (journals.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.book, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No journal entries yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Start writing to track your thoughts and mood',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }
          
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: journals.length,
            itemBuilder: (context, index) {
              final journal = journals[index];
              List<String> topics = [];
              
              // Parse topics JSON
              try {
                final parsed = journal.topicsJson;
                if (parsed['topics'] is List) {
                  topics = List<String>.from(parsed['topics']);
                }
                            } catch (e) {
                // Fallback if JSON parsing fails
              }
              
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _getMoodColor(journal.moodInt),
                    child: Icon(
                      _getMoodIcon(journal.moodInt),
                      color: Colors.white,
                    ),
                  ),
                  title: Text(
                    _formatDate(journal.createdAt),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        journal.contentMd.length > 100
                            ? '${journal.contentMd.substring(0, 100)}...'
                            : journal.contentMd,
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (journal.moodInt != null)
                            Text(
                              '😊 Mood: ${journal.moodInt}/10',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 12,
                              ),
                            ),
                          if (topics.isNotEmpty) ...[
                            const SizedBox(width: 12),
                            Text(
                              '🏷️ ${topics.take(2).join(', ')}${topics.length > 2 ? '...' : ''}',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                  isThreeLine: true,
                  onTap: () {
                    // TODO: Show journal details
                  },
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error loading journals: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.refresh(journalsProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
  
  Color _getMoodColor(int? mood) {
    if (mood == null) return Colors.grey;
    if (mood >= 8) return Colors.green;
    if (mood >= 6) return Colors.lightGreen;
    if (mood >= 4) return Colors.orange;
    return Colors.red;
  }
  
  IconData _getMoodIcon(int? mood) {
    if (mood == null) return Icons.help_outline;
    if (mood >= 8) return Icons.sentiment_very_satisfied;
    if (mood >= 6) return Icons.sentiment_satisfied;
    if (mood >= 4) return Icons.sentiment_neutral;
    return Icons.sentiment_dissatisfied;
  }
}
