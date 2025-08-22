import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/app_providers.dart';

class EducationScreen extends ConsumerWidget {
  const EducationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final educationAsync = ref.watch(educationProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Education & Learning'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              // TODO: Add new education record
            },
            tooltip: 'Add Education',
          ),
        ],
      ),
      body: educationAsync.when(
        data: (educationRecords) {
          if (educationRecords.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.school, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No education records yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Track your educational journey and achievements',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: educationRecords.length,
            itemBuilder: (context, index) {
              final education = educationRecords[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 8.0),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _getEducationColor(education.degree),
                    child: Icon(
                      _getEducationIcon(education.degree),
                      color: Colors.white,
                    ),
                  ),
                  title: Text(
                    education.schoolName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (education.degree != null && education.degree!.isNotEmpty)
                        Text(
                          education.degree!,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      if (education.major != null && education.major!.isNotEmpty)
                        Text(
                          'Major: ${education.major}',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      Text(
                        '${_formatDate(education.startDate)} - ${education.endDate != null ? _formatDate(education.endDate!) : 'Present'}',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      if (education.notes != null && education.notes!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text(
                            education.notes!,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                    ],
                  ),
                  isThreeLine: true,
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
              Text('Error loading education records: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.refresh(educationProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getEducationColor(String? degree) {
    if (degree == null) return Colors.grey;
    
    switch (degree.toLowerCase()) {
      case 'bachelor':
      case 'bachelor\'s':
      case 'bs':
      case 'ba':
        return Colors.blue;
      case 'master':
      case 'master\'s':
      case 'ms':
      case 'ma':
        return Colors.green;
      case 'phd':
      case 'doctorate':
      case 'doctoral':
        return Colors.purple;
      case 'high school':
      case 'diploma':
        return Colors.orange;
      case 'certificate':
      case 'certification':
        return Colors.teal;
      default:
        return Colors.indigo;
    }
  }

  IconData _getEducationIcon(String? degree) {
    if (degree == null) return Icons.school;
    
    switch (degree.toLowerCase()) {
      case 'bachelor':
      case 'bachelor\'s':
      case 'bs':
      case 'ba':
        return Icons.school;
      case 'master':
      case 'master\'s':
      case 'ms':
      case 'ma':
        return Icons.school_outlined;
      case 'phd':
      case 'doctorate':
      case 'doctoral':
        return Icons.science;
      case 'high school':
      case 'diploma':
        return Icons.account_balance;
      case 'certificate':
      case 'certification':
        return Icons.card_membership;
      default:
        return Icons.school;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.year}';
  }
}
