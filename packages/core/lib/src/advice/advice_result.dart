import 'package:meta/meta.dart';
import 'safety_checker.dart';

@immutable
class AdviceResult {
  const AdviceResult({
    required this.query,
    required this.advice,
    required this.reasoning,
    required this.citations,
    required this.actionItems,
    required this.safetyResult,
    required this.confidence,
    this.timeframe,
  });

  final String query;
  final String advice;
  final String reasoning;
  final List<String> citations;
  final List<ActionItem> actionItems;
  final SafetyResult safetyResult;
  final double confidence; // 0.0 to 1.0
  final String? timeframe;

  /// Format the complete advice response
  String formatResponse() {
    final buffer = StringBuffer();

    // Main advice
    buffer.writeln('## Advice');
    buffer.writeln(advice);
    buffer.writeln();

    // Reasoning
    if (reasoning.isNotEmpty) {
      buffer.writeln('## Analysis');
      buffer.writeln(reasoning);
      buffer.writeln();
    }

    // Action items
    if (actionItems.isNotEmpty) {
      buffer.writeln('## Action Plan');
      for (int i = 0; i < actionItems.length; i++) {
        final item = actionItems[i];
        buffer.writeln('${i + 1}. ${item.title}');
        if (item.description.isNotEmpty) {
          buffer.writeln('   ${item.description}');
        }
        if (item.timeframe != null) {
          buffer.writeln('   ⏱️ ${item.timeframe}');
        }
        if (item.priority != null) {
          buffer.writeln('   🎯 Priority: ${item.priority}');
        }
        buffer.writeln();
      }
    }

    // Citations
    if (citations.isNotEmpty) {
      buffer.writeln('## Sources');
      for (int i = 0; i < citations.length; i++) {
        buffer.writeln('• ${citations[i]}');
      }
      buffer.writeln();
    }

    // Safety disclaimers
    if (safetyResult.hasAnyWarning) {
      buffer.writeln('## Important Notices');
      for (final warning in safetyResult.warnings) {
        buffer.writeln(warning.disclaimer);
        buffer.writeln();
      }
    }

    // Confidence
    buffer.writeln('---');
    buffer.writeln('*Confidence: ${(confidence * 100).toStringAsFixed(0)}%*');

    return buffer.toString();
  }

  Map<String, dynamic> toMap() {
    return {
      'query': query,
      'advice': advice,
      'reasoning': reasoning,
      'citations': citations,
      'action_items': actionItems.map((item) => item.toMap()).toList(),
      'safety_warnings': safetyResult.warnings.map((w) => w.name).toList(),
      'confidence': confidence,
      'timeframe': timeframe,
    };
  }
}

@immutable
class ActionItem {
  const ActionItem({
    required this.title,
    required this.description,
    this.timeframe,
    this.priority,
    this.category,
    this.isHabit = false,
  });

  final String title;
  final String description;
  final String? timeframe;
  final ActionPriority? priority;
  final String? category;
  final bool isHabit;

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'timeframe': timeframe,
      'priority': priority?.name,
      'category': category,
      'is_habit': isHabit,
    };
  }

  factory ActionItem.fromMap(Map<String, dynamic> map) {
    return ActionItem(
      title: map['title'],
      description: map['description'],
      timeframe: map['timeframe'],
      priority: map['priority'] != null
          ? ActionPriority.values.byName(map['priority'])
          : null,
      category: map['category'],
      isHabit: map['is_habit'] ?? false,
    );
  }

  /// Convert to task/habit format for database insertion
  Map<String, dynamic> toTaskHabitMap() {
    return {
      'title': title,
      'type': isHabit ? 'habit' : 'task',
      'description': description,
      'status': 'pending',
      'priority': priority?.name ?? 'medium',
      'category': category,
      'schedule_json': timeframe != null ? {'timeframe': timeframe} : {},
      'notes': 'Generated from AI advice for query: "${ActionItem._truncateQuery}"',
    };
  }

  static String _truncateQuery = '';
  static void _setQueryContext(String query) {
    _truncateQuery = query.length > 100 ? '${query.substring(0, 100)}...' : query;
  }
}

enum ActionPriority {
  low,
  medium,
  high,
  urgent,
}

/// Advice categories for better organization
enum AdviceCategory {
  health,
  finance,
  productivity,
  relationships,
  learning,
  lifestyle,
  general,
}

extension AdviceCategoryExtension on AdviceCategory {
  String get displayName {
    switch (this) {
      case AdviceCategory.health:
        return 'Health & Wellness';
      case AdviceCategory.finance:
        return 'Financial';
      case AdviceCategory.productivity:
        return 'Productivity';
      case AdviceCategory.relationships:
        return 'Relationships';
      case AdviceCategory.learning:
        return 'Learning & Growth';
      case AdviceCategory.lifestyle:
        return 'Lifestyle';
      case AdviceCategory.general:
        return 'General';
    }
  }

  String get icon {
    switch (this) {
      case AdviceCategory.health:
        return '🏃';
      case AdviceCategory.finance:
        return '💰';
      case AdviceCategory.productivity:
        return '⚡';
      case AdviceCategory.relationships:
        return '👥';
      case AdviceCategory.learning:
        return '📚';
      case AdviceCategory.lifestyle:
        return '🌟';
      case AdviceCategory.general:
        return '💡';
    }
  }
}
