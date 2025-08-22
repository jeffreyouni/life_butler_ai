import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/app_providers.dart';

class FinanceScreen extends ConsumerWidget {
  const FinanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final financeAsync = ref.watch(financeRecordsProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Finance Records'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              // TODO: Add new finance record
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Add finance record functionality coming soon')),
              );
            },
            tooltip: 'Add Transaction',
          ),
        ],
      ),
      body: financeAsync.when(
        data: (records) {
          if (records.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.account_balance_wallet, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No financial records yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Track income and expenses to analyze spending patterns',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }
          
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: records.length,
            itemBuilder: (context, index) {
              final record = records[index];
              List<String> tags = [];
              
              // Parse tags JSON
              try {
                final parsed = record.tagsJson;
                if (parsed['tags'] is List) {
                  tags = List<String>.from(parsed['tags']);
                }
                            } catch (e) {
                // Fallback if JSON parsing fails
              }
              
              final isIncome = record.type == 'income';
              
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isIncome ? Colors.green.shade100 : Colors.red.shade100,
                    child: Icon(
                      isIncome ? Icons.arrow_upward : Icons.arrow_downward,
                      color: isIncome ? Colors.green.shade700 : Colors.red.shade700,
                    ),
                  ),
                  title: Text(
                    '${record.currency ?? 'CNY'} ${record.amount.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isIncome ? Colors.green.shade700 : Colors.red.shade700,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '💼 ${record.category ?? 'Other'}',
                        style: const TextStyle(fontSize: 14),
                      ),
                      if (record.notes != null)
                        Text(
                          record.notes!,
                          style: const TextStyle(fontSize: 14),
                        ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            '📅 ${_formatDate(record.time)}',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
                          ),
                          if (tags.isNotEmpty) ...[
                            const SizedBox(width: 12),
                            Text(
                              '🏷️ ${tags.take(2).join(', ')}',
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
                    // TODO: Show record details
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
              Text('Error loading finance records: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.refresh(financeRecordsProvider),
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
}
