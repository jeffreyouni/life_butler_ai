import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/core.dart' show Logger;

import '../providers/app_providers.dart';
import '../services/app_initializer.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  static final _logger = Logger('DashboardScreen');
  
  @override
  void initState() {
    super.initState();
    // Embedding initialization is handled by main.dart - no need to duplicate here
  }

  @override
  Widget build(BuildContext context) {
    final providerStatus = ref.watch(providerStatusProvider);
    final embeddingStatus = ref.watch(embeddingStatusProvider);
    final eventsAsync = ref.watch(eventsProvider);
    final mealsAsync = ref.watch(mealsProvider);
    final journalsAsync = ref.watch(journalsProvider);
    final financeAsync = ref.watch(financeRecordsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome to Life Butler AI',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Your personal life memory and advice system',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Provider status card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI Provider Status',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    providerStatus.when(
                      data: (status) => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildStatusRow('Ollama', status.ollamaAvailable),
                          const SizedBox(height: 8),
                          Text(
                            status.statusMessage,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                      loading: () => const CircularProgressIndicator(),
                      error: (error, stack) => Text('Error: $error'),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Embedding status card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Embedding Generation Status',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    _buildEmbeddingStatusContent(context, embeddingStatus),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Quick stats
            Expanded(
              child: GridView.count(
                crossAxisCount: 4,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  eventsAsync.when(
                    data: (events) => _buildStatCard(
                      context,
                      'Events',
                      '${events.length}',
                      Icons.event,
                      Colors.blue,
                    ),
                    loading: () => _buildLoadingCard(context, 'Events', Icons.event, Colors.blue),
                    error: (e, _) => _buildStatCard(context, 'Events', '?', Icons.event, Colors.blue),
                  ),
                  mealsAsync.when(
                    data: (meals) => _buildStatCard(
                      context,
                      'Meals',
                      '${meals.length}',
                      Icons.restaurant,
                      Colors.orange,
                    ),
                    loading: () => _buildLoadingCard(context, 'Meals', Icons.restaurant, Colors.orange),
                    error: (e, _) => _buildStatCard(context, 'Meals', '?', Icons.restaurant, Colors.orange),
                  ),
                  journalsAsync.when(
                    data: (journals) => _buildStatCard(
                      context,
                      'Journals',
                      '${journals.length}',
                      Icons.book,
                      Colors.green,
                    ),
                    loading: () => _buildLoadingCard(context, 'Journals', Icons.book, Colors.green),
                    error: (e, _) => _buildStatCard(context, 'Journals', '?', Icons.book, Colors.green),
                  ),
                  financeAsync.when(
                    data: (records) => _buildStatCard(
                      context,
                      'Finance',
                      '${records.length}',
                      Icons.account_balance_wallet,
                      Colors.red,
                    ),
                    loading: () => _buildLoadingCard(context, 'Finance', Icons.account_balance_wallet, Colors.red),
                    error: (e, _) => _buildStatCard(context, 'Finance', '?', Icons.account_balance_wallet, Colors.red),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusRow(String name, bool available) {
    return Row(
      children: [
        Icon(
          available ? Icons.check_circle : Icons.cancel,
          color: available ? Colors.green : Colors.red,
          size: 16,
        ),
        const SizedBox(width: 8),
        Text(name),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String count,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              count,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: color,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmbeddingStatusContent(BuildContext context, EmbeddingStatusData status) {
    if (status.isComplete) {
      return Row(
        children: [
          const Icon(
            Icons.check_circle,
            color: Colors.green,
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            'Embeddings generated successfully',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      );
    }

    if (status.isGenerating) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Generating embeddings...',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (status.isGenerating) ...[
            LinearProgressIndicator(
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
            ),
            const SizedBox(height: 4),
            Text(
              'Generating embeddings...',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ] else if (status.isComplete) ...[
            Row(
              children: [
                const Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  'Embedding generation completed',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ],
      );
    }

    return Row(
      children: [
        Icon(
          Icons.hourglass_empty,
          color: Colors.grey[600],
          size: 16,
        ),
        const SizedBox(width: 8),
        Text(
          'Embeddings not yet generated',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}
