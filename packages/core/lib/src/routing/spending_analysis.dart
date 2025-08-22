import '../query/query_context.dart';

/// Analysis result for spending patterns
class SpendingAnalysis {
  const SpendingAnalysis({
    required this.totalSpent,
    required this.averagePerTransaction,
    required this.dailyAverage,
    required this.categoryBreakdown,
    required this.transactionCount,
    this.timeRange,
  });

  final double totalSpent;
  final double averagePerTransaction;
  final double dailyAverage;
  final Map<String, double> categoryBreakdown;
  final int transactionCount;
  final TimeRange? timeRange;

  String toSummaryText() {
    final buffer = StringBuffer();
    buffer.writeln('💰 **支出分析**');
    buffer.writeln('• 总支出: ¥${totalSpent.toStringAsFixed(2)}');
    buffer.writeln('• 平均每笔: ¥${averagePerTransaction.toStringAsFixed(2)}');
    buffer.writeln('• 日均支出: ¥${dailyAverage.toStringAsFixed(2)}');
    buffer.writeln('• 交易笔数: $transactionCount');

    if (categoryBreakdown.isNotEmpty) {
      buffer.writeln('\n**分类明细:**');
      final sortedCategories = categoryBreakdown.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      
      for (final entry in sortedCategories.take(5)) {
        final percentage = (entry.value / totalSpent * 100).toStringAsFixed(1);
        buffer.writeln('• ${entry.key}: ¥${entry.value.toStringAsFixed(2)} ($percentage%)');
      }
    }

    if (timeRange != null) {
      buffer.writeln('\n**时间范围**: ${_formatTimeRange(timeRange!)}');
    }

    return buffer.toString();
  }

  String _formatTimeRange(TimeRange range) {
    if (range.start != null && range.end != null) {
      return '${range.start!.month}/${range.start!.day} - ${range.end!.month}/${range.end!.day}';
    } else if (range.start != null) {
      return '从 ${range.start!.month}/${range.start!.day}';
    } else if (range.end != null) {
      return '到 ${range.end!.month}/${range.end!.day}';
    }
    return '全部时间';
  }
}
