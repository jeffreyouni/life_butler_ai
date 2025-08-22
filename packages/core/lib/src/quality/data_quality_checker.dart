import 'package:data/data.dart';
import '../utils/logger.dart';

/// 数据质量检查和修复工具
class DataQualityChecker {
  static final _logger = Logger('DataQualityChecker');
  
  final LifeButlerDatabase database;
  
  DataQualityChecker(this.database);
  
  /// 执行完整的数据质量检查
  Future<DataQualityReport> performQualityCheck() async {
    final issues = <DataQualityIssue>[];
    final summary = <String, int>{};
    
    // 检查财务记录
    final financeIssues = await _checkFinanceRecords();
    issues.addAll(financeIssues);
    
    // 检查餐食记录
    final mealIssues = await _checkMealRecords();
    issues.addAll(mealIssues);
    
    // 检查事件记录
    final eventIssues = await _checkEventRecords();
    issues.addAll(eventIssues);
    
    // 生成统计摘要
    for (final issue in issues) {
      summary[issue.type] = (summary[issue.type] ?? 0) + issue.affectedRecords.length;
    }
    
    final totalRecords = await _getTotalRecordCount();
    final problemRecordCount = issues.fold(0, (sum, issue) => sum + issue.affectedRecords.length);
    final validRecords = totalRecords - problemRecordCount;
    final completenessScore = totalRecords > 0 ? validRecords.toDouble() / totalRecords.toDouble() : 0.0;
    
    return DataQualityReport(
      issues: issues,
      summary: summary,
      totalRecords: totalRecords,
      validRecords: validRecords,
      completenessScore: completenessScore,
      checkedAt: DateTime.now(),
    );
  }
  
  /// 检查财务记录的数据质量
  Future<List<DataQualityIssue>> _checkFinanceRecords() async {
    final issues = <DataQualityIssue>[];
    
    try {
      final allRecords = await database.select(database.financeRecords).get();
      
      // 检查金额缺失或为零
      final zeroAmountRecords = allRecords.where((r) => r.amount == 0.0).toList();
      if (zeroAmountRecords.isNotEmpty) {
        issues.add(DataQualityIssue(
          type: 'missing_amount',
          severity: DataQualitySeverity.high,
          domain: 'finance',
          description: '财务记录缺少金额信息',
          affectedRecords: zeroAmountRecords.map((r) => r.id).toList(),
          recommendedAction: '请为这些记录补充准确的金额信息',
          detailMessage: '发现 ${zeroAmountRecords.length} 条财务记录的金额为0或缺失，这将影响支出分析的准确性。',
        ));
      }
      
      // 检查分类缺失
      final missingCategoryRecords = allRecords.where((r) => 
        r.category == null || r.category!.isEmpty).toList();
      if (missingCategoryRecords.isNotEmpty) {
        issues.add(DataQualityIssue(
          type: 'missing_category',
          severity: DataQualitySeverity.medium,
          domain: 'finance',
          description: '财务记录缺少分类信息',
          affectedRecords: missingCategoryRecords.map((r) => r.id).toList(),
          recommendedAction: '为这些记录添加合适的分类标签',
          detailMessage: '发现 ${missingCategoryRecords.length} 条财务记录没有分类，无法进行分类统计分析。',
        ));
      }
      
      // 检查货币类型不一致
      final currencyTypes = allRecords.map((r) => r.currency ?? 'USD').toSet();
      if (currencyTypes.length > 1) {
        final inconsistentRecords = allRecords.where((r) => 
          (r.currency ?? 'USD') != 'CNY').toList();
        if (inconsistentRecords.isNotEmpty) {
          issues.add(DataQualityIssue(
            type: 'inconsistent_currency',
            severity: DataQualitySeverity.medium,
            domain: 'finance',
            description: '货币类型不统一',
            affectedRecords: inconsistentRecords.map((r) => r.id).toList(),
            recommendedAction: '统一使用一种货币类型或添加汇率转换',
            detailMessage: '发现多种货币类型：${currencyTypes.join(', ')}，可能影响总额计算。',
          ));
        }
      }
      
      // 检查异常日期
      final now = DateTime.now();
      final futureRecords = allRecords.where((r) => r.time.isAfter(now)).toList();
      if (futureRecords.isNotEmpty) {
        issues.add(DataQualityIssue(
          type: 'future_date',
          severity: DataQualitySeverity.low,
          domain: 'finance',
          description: '存在未来日期的记录',
          affectedRecords: futureRecords.map((r) => r.id).toList(),
          recommendedAction: '检查并修正这些记录的日期',
          detailMessage: '发现 ${futureRecords.length} 条记录的日期在未来，可能是输入错误。',
        ));
      }
      
    } catch (e) {
      _logger.info('检查财务记录时发生错误: $e');
    }
    
    return issues;
  }
  
  /// 检查餐食记录的数据质量
  Future<List<DataQualityIssue>> _checkMealRecords() async {
    final issues = <DataQualityIssue>[];
    
    try {
      final allRecords = await database.select(database.meals).get();
      
      // 检查缺少餐食名称
      final missingNameRecords = allRecords.where((r) => 
        r.name.isEmpty || r.name == 'Unknown meal').toList();
      if (missingNameRecords.isNotEmpty) {
        issues.add(DataQualityIssue(
          type: 'missing_meal_name',
          severity: DataQualitySeverity.medium,
          domain: 'meals',
          description: '餐食记录缺少名称',
          affectedRecords: missingNameRecords.map((r) => r.id).toList(),
          recommendedAction: '为这些餐食添加具体名称',
          detailMessage: '发现 ${missingNameRecords.length} 条餐食记录没有名称或使用默认名称。',
        ));
      }
      
      // 检查卡路里信息缺失
      final missingCaloriesRecords = allRecords.where((r) => 
        r.caloriesInt == null || r.caloriesInt == 0).toList();
      if (missingCaloriesRecords.isNotEmpty && missingCaloriesRecords.length > allRecords.length * 0.5) {
        issues.add(DataQualityIssue(
          type: 'missing_calories',
          severity: DataQualitySeverity.low,
          domain: 'meals',
          description: '大部分餐食记录缺少卡路里信息',
          affectedRecords: missingCaloriesRecords.map((r) => r.id).toList(),
          recommendedAction: '考虑添加卡路里信息以进行营养分析',
          detailMessage: '发现 ${missingCaloriesRecords.length} 条餐食记录没有卡路里信息。',
        ));
      }
      
      // 检查异常时间
      final now = DateTime.now();
      final futureMealRecords = allRecords.where((r) => r.time.isAfter(now)).toList();
      if (futureMealRecords.isNotEmpty) {
        issues.add(DataQualityIssue(
          type: 'future_date',
          severity: DataQualitySeverity.low,
          domain: 'meals',
          description: '存在未来时间的餐食记录',
          affectedRecords: futureMealRecords.map((r) => r.id).toList(),
          recommendedAction: '检查并修正这些记录的时间',
          detailMessage: '发现 ${futureMealRecords.length} 条餐食记录的时间在未来。',
        ));
      }
      
    } catch (e) {
      _logger.info('检查餐食记录时发生错误: $e');
    }
    
    return issues;
  }
  
  /// 检查事件记录的数据质量
  Future<List<DataQualityIssue>> _checkEventRecords() async {
    final issues = <DataQualityIssue>[];
    
    try {
      final allRecords = await database.select(database.events).get();
      
      // 检查缺少描述的事件
      final missingDescRecords = allRecords.where((r) => 
        r.description == null || r.description!.isEmpty).toList();
      if (missingDescRecords.isNotEmpty && missingDescRecords.length > allRecords.length * 0.3) {
        issues.add(DataQualityIssue(
          type: 'missing_event_description',
          severity: DataQualitySeverity.low,
          domain: 'events',
          description: '许多事件记录缺少详细描述',
          affectedRecords: missingDescRecords.map((r) => r.id).toList(),
          recommendedAction: '为重要事件添加详细描述',
          detailMessage: '发现 ${missingDescRecords.length} 条事件记录没有描述信息。',
        ));
      }
      
    } catch (e) {
      _logger.info('检查事件记录时发生错误: $e');
    }
    
    return issues;
  }
  
  /// 获取总记录数
  Future<int> _getTotalRecordCount() async {
    final financeCount = await database.customSelect('SELECT COUNT(*) as count FROM finance_records').getSingle();
    final mealCount = await database.customSelect('SELECT COUNT(*) as count FROM meals').getSingle();
    final eventCount = await database.customSelect('SELECT COUNT(*) as count FROM events').getSingle();
    
    return (financeCount.data['count'] as int) + 
           (mealCount.data['count'] as int) + 
           (eventCount.data['count'] as int);
  }
  
  /// 生成数据质量改进建议
  List<String> generateImprovementSuggestions(DataQualityReport report) {
    final suggestions = <String>[];
    
    if (report.completenessScore < 0.7) {
      suggestions.add('数据完整性较低(${(report.completenessScore * 100).toStringAsFixed(1)}%)，建议优先补充缺失信息');
    }
    
    final highPriorityIssues = report.issues.where((i) => i.severity == DataQualitySeverity.high).toList();
    if (highPriorityIssues.isNotEmpty) {
      suggestions.add('发现 ${highPriorityIssues.length} 个高优先级问题，建议立即处理');
    }
    
    final financeIssues = report.issues.where((i) => i.domain == 'finance').toList();
    if (financeIssues.isNotEmpty) {
      suggestions.add('财务数据存在问题，可能影响支出分析准确性');
    }
    
    suggestions.add('建议定期(每周)进行数据质量检查');
    suggestions.add('设置数据录入提醒，确保信息完整性');
    
    return suggestions;
  }
}

/// 数据质量问题定义
class DataQualityIssue {
  final String type;
  final DataQualitySeverity severity;
  final String domain;
  final String description;
  final List<String> affectedRecords;
  final String recommendedAction;
  final String detailMessage;
  
  DataQualityIssue({
    required this.type,
    required this.severity,
    required this.domain,
    required this.description,
    required this.affectedRecords,
    required this.recommendedAction,
    required this.detailMessage,
  });
}

/// 数据质量严重程度
enum DataQualitySeverity {
  low,    // 低：不影响基本功能
  medium, // 中：影响部分分析功能
  high,   // 高：严重影响分析准确性
}

/// 数据质量报告
class DataQualityReport {
  final List<DataQualityIssue> issues;
  final Map<String, int> summary;
  final int totalRecords;
  final int validRecords;
  final double completenessScore;
  final DateTime checkedAt;
  
  DataQualityReport({
    required this.issues,
    required this.summary,
    required this.totalRecords,
    required this.validRecords,
    required this.completenessScore,
    required this.checkedAt,
  });
  
  /// 生成可读的报告文本
  String generateReportText({String language = 'zh'}) {
    final buffer = StringBuffer();
    
    if (language == 'zh') {
      buffer.writeln('📋 **数据质量检查报告**');
      buffer.writeln('检查时间: ${checkedAt.toString().split('.')[0]}');
      buffer.writeln('');
      
      buffer.writeln('📊 **总体状况**');
      buffer.writeln('• 总记录数: $totalRecords');
      buffer.writeln('• 有效记录数: $validRecords');
      buffer.writeln('• 数据完整性: ${(completenessScore * 100).toStringAsFixed(1)}%');
      buffer.writeln('');
      
      if (issues.isEmpty) {
        buffer.writeln('✅ **恭喜！您的数据质量很好，没有发现明显问题。**');
      } else {
        buffer.writeln('⚠️ **发现 ${issues.length} 个问题需要处理：**');
        buffer.writeln('');
        
        // 按严重程度分组
        final highIssues = issues.where((i) => i.severity == DataQualitySeverity.high).toList();
        final mediumIssues = issues.where((i) => i.severity == DataQualitySeverity.medium).toList();
        final lowIssues = issues.where((i) => i.severity == DataQualitySeverity.low).toList();
        
        if (highIssues.isNotEmpty) {
          buffer.writeln('🔴 **高优先级问题 (${highIssues.length}个)**');
          for (final issue in highIssues) {
            buffer.writeln('• ${issue.description}');
            buffer.writeln('  影响记录: ${issue.affectedRecords.length}条');
            buffer.writeln('  建议: ${issue.recommendedAction}');
            buffer.writeln('');
          }
        }
        
        if (mediumIssues.isNotEmpty) {
          buffer.writeln('🟡 **中优先级问题 (${mediumIssues.length}个)**');
          for (final issue in mediumIssues) {
            buffer.writeln('• ${issue.description}');
            buffer.writeln('  影响记录: ${issue.affectedRecords.length}条');
            buffer.writeln('');
          }
        }
        
        if (lowIssues.isNotEmpty) {
          buffer.writeln('🟢 **低优先级问题 (${lowIssues.length}个)**');
          for (final issue in lowIssues) {
            buffer.writeln('• ${issue.description} (${issue.affectedRecords.length}条记录)');
          }
        }
      }
      
    } else {
      // English version
      buffer.writeln('📋 **Data Quality Check Report**');
      buffer.writeln('Checked at: ${checkedAt.toString().split('.')[0]}');
      buffer.writeln('');
      
      buffer.writeln('📊 **Overall Status**');
      buffer.writeln('• Total records: $totalRecords');
      buffer.writeln('• Valid records: $validRecords');
      buffer.writeln('• Data completeness: ${(completenessScore * 100).toStringAsFixed(1)}%');
      buffer.writeln('');
      
      if (issues.isEmpty) {
        buffer.writeln('✅ **Congratulations! Your data quality is good with no significant issues found.**');
      } else {
        buffer.writeln('⚠️ **Found ${issues.length} issues that need attention:**');
        // Similar structure for English...
      }
    }
    
    return buffer.toString();
  }
}
