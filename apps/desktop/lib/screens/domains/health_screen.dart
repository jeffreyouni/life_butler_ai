import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/app_providers.dart';

class HealthScreen extends ConsumerWidget {
  const HealthScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final healthMetricsAsync = ref.watch(healthMetricsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Health Metrics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              // TODO: Add new health metric
            },
            tooltip: 'Add Metric',
          ),
        ],
      ),
      body: healthMetricsAsync.when(
        data: (metrics) {
          if (metrics.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.favorite, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No health data recorded yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Track weight, sleep, exercise and other health metrics',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: metrics.length,
            itemBuilder: (context, index) {
              final metric = metrics[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 8.0),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _getMetricColor(metric.metricType),
                    child: Icon(
                      _getMetricIcon(metric.metricType),
                      color: Colors.white,
                    ),
                  ),
                  title: Text(
                    '${metric.metricType}: ${metric.valueNum} ${metric.unit}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Recorded: ${_formatDate(metric.time)}',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      if (metric.notes != null && metric.notes!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text(
                            metric.notes!,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                    ],
                  ),
                  isThreeLine: metric.notes != null && metric.notes!.isNotEmpty,
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error loading health metrics: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.refresh(healthMetricsProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getMetricColor(String metricType) {
    switch (metricType.toLowerCase()) {
      case 'weight':
        return Colors.blue;
      case 'height':
        return Colors.green;
      case 'blood_pressure':
      case 'blood pressure':
        return Colors.red;
      case 'heart_rate':
      case 'heart rate':
        return Colors.pink;
      case 'steps':
        return Colors.orange;
      case 'sleep':
        return Colors.purple;
      case 'exercise':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  IconData _getMetricIcon(String metricType) {
    switch (metricType.toLowerCase()) {
      case 'weight':
        return Icons.monitor_weight;
      case 'height':
        return Icons.height;
      case 'blood_pressure':
      case 'blood pressure':
        return Icons.favorite;
      case 'heart_rate':
      case 'heart rate':
        return Icons.favorite_border;
      case 'steps':
        return Icons.directions_walk;
      case 'sleep':
        return Icons.bed;
      case 'exercise':
        return Icons.fitness_center;
      default:
        return Icons.health_and_safety;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
