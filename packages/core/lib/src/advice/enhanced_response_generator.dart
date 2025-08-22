import 'package:meta/meta.dart';

/// 增强的AI回答生成器，专门处理数据质量问题
class EnhancedResponseGenerator {
  
  /// 分析数据质量并生成完整的回答
  static String generateComprehensiveResponse({
    required String query,
    required String language,
    required List<DataIssue> dataIssues,
    required Map<String, dynamic> calculationResults,
    required List<String> retrievedContext,
  }) {
    final buffer = StringBuffer();
    
    // 1. 数据质量问题报告
    if (dataIssues.isNotEmpty) {
      buffer.write(_generateDataQualityReport(dataIssues, language));
      buffer.write('\n\n');
    }
    
    // 2. 基于现有数据的分析
    if (calculationResults.isNotEmpty) {
      buffer.write(_generateDataAnalysis(calculationResults, language));
      buffer.write('\n\n');
    }
    
    // 3. 具体的改进建议
    buffer.write(_generateActionableRecommendations(dataIssues, language));
    buffer.write('\n\n');
    
    // 4. 数据完善指导
    buffer.write(_generateDataImprovementGuide(dataIssues, language));
    
    return buffer.toString();
  }
  
  static String _generateDataQualityReport(List<DataIssue> issues, String language) {
    final buffer = StringBuffer();
    
    if (language == 'zh') {
      buffer.writeln('📊 **数据质量分析报告**');
      buffer.writeln('');
      buffer.writeln('我发现您的数据中存在以下问题：');
      buffer.writeln('');
      
      for (final issue in issues) {
        switch (issue.type) {
          case DataIssueType.missingAmount:
            buffer.writeln('❌ **金额缺失**: ${issue.count}条记录缺少金额信息');
            buffer.writeln('   影响: 无法进行准确的支出统计和分析');
            break;
          case DataIssueType.zeroAmount:
            buffer.writeln('⚠️ **零金额记录**: ${issue.count}条记录金额为0');
            buffer.writeln('   可能原因: 数据录入不完整或测试数据');
            break;
          case DataIssueType.missingCategory:
            buffer.writeln('📂 **分类缺失**: ${issue.count}条记录没有分类信息');
            buffer.writeln('   影响: 无法进行分类统计和趋势分析');
            break;
          case DataIssueType.invalidDate:
            buffer.writeln('📅 **日期异常**: ${issue.count}条记录日期有问题');
            buffer.writeln('   影响: 时间趋势分析可能不准确');
            break;
          case DataIssueType.duplicateRecord:
            buffer.writeln('🔄 **重复记录**: ${issue.count}条记录可能重复');
            buffer.writeln('   影响: 统计结果可能偏高');
            break;
          case DataIssueType.inconsistentCurrency:
            buffer.writeln('💱 **货币不一致**: ${issue.count}条记录货币类型不同');
            buffer.writeln('   影响: 金额汇总可能不准确');
            break;
        }
        buffer.writeln('');
      }
    } else {
      buffer.writeln('📊 **Data Quality Analysis Report**');
      buffer.writeln('');
      buffer.writeln('I found the following issues in your data:');
      buffer.writeln('');
      
      for (final issue in issues) {
        switch (issue.type) {
          case DataIssueType.missingAmount:
            buffer.writeln('❌ **Missing Amounts**: ${issue.count} records lack amount information');
            buffer.writeln('   Impact: Cannot perform accurate expense calculations');
            break;
          case DataIssueType.zeroAmount:
            buffer.writeln('⚠️ **Zero Amounts**: ${issue.count} records have zero amounts');
            buffer.writeln('   Possible cause: Incomplete data entry or test data');
            break;
          case DataIssueType.missingCategory:
            buffer.writeln('📂 **Missing Categories**: ${issue.count} records lack category information');
            buffer.writeln('   Impact: Cannot perform category-based analysis');
            break;
          case DataIssueType.invalidDate:
            buffer.writeln('📅 **Invalid Dates**: ${issue.count} records have date issues');
            buffer.writeln('   Impact: Time trend analysis may be inaccurate');
            break;
          case DataIssueType.duplicateRecord:
            buffer.writeln('🔄 **Duplicate Records**: ${issue.count} records may be duplicated');
            buffer.writeln('   Impact: Statistics may be inflated');
            break;
          case DataIssueType.inconsistentCurrency:
            buffer.writeln('💱 **Currency Inconsistency**: ${issue.count} records have different currencies');
            buffer.writeln('   Impact: Amount totals may be inaccurate');
            break;
        }
        buffer.writeln('');
      }
    }
    
    return buffer.toString();
  }
  
  static String _generateDataAnalysis(Map<String, dynamic> results, String language) {
    final buffer = StringBuffer();
    
    if (language == 'zh') {
      buffer.writeln('📈 **基于现有数据的分析**');
      buffer.writeln('');
      
      if (results.containsKey('valid_records_count')) {
        buffer.writeln('✅ 有效记录数: ${results['valid_records_count']}条');
      }
      
      if (results.containsKey('date_range')) {
        final range = results['date_range'] as Map<String, String>;
        buffer.writeln('📅 数据时间范围: ${range['start']} 至 ${range['end']}');
      }
      
      if (results.containsKey('categories')) {
        final categories = results['categories'] as List<String>;
        buffer.writeln('📂 包含的分类: ${categories.join(', ')}');
      }
      
      if (results.containsKey('data_completeness_score')) {
        final score = results['data_completeness_score'] as double;
        buffer.writeln('📊 数据完整性评分: ${(score * 100).toStringAsFixed(1)}%');
      }
    } else {
      buffer.writeln('📈 **Analysis Based on Available Data**');
      buffer.writeln('');
      
      if (results.containsKey('valid_records_count')) {
        buffer.writeln('✅ Valid records: ${results['valid_records_count']} entries');
      }
      
      if (results.containsKey('date_range')) {
        final range = results['date_range'] as Map<String, String>;
        buffer.writeln('📅 Data time range: ${range['start']} to ${range['end']}');
      }
      
      if (results.containsKey('categories')) {
        final categories = results['categories'] as List<String>;
        buffer.writeln('📂 Categories included: ${categories.join(', ')}');
      }
      
      if (results.containsKey('data_completeness_score')) {
        final score = results['data_completeness_score'] as double;
        buffer.writeln('📊 Data completeness score: ${(score * 100).toStringAsFixed(1)}%');
      }
    }
    
    return buffer.toString();
  }
  
  static String _generateActionableRecommendations(List<DataIssue> issues, String language) {
    final buffer = StringBuffer();
    
    if (language == 'zh') {
      buffer.writeln('💡 **立即行动建议**');
      buffer.writeln('');
      
      final hasAmountIssues = issues.any((i) => 
        i.type == DataIssueType.missingAmount || i.type == DataIssueType.zeroAmount);
      
      if (hasAmountIssues) {
        buffer.writeln('1. **补充金额信息**');
        buffer.writeln('   - 检查最近的支出记录，补充缺失的金额');
        buffer.writeln('   - 确认零金额记录是否为实际免费项目');
        buffer.writeln('   - 设置提醒，确保未来记录包含准确金额');
        buffer.writeln('');
      }
      
      final hasCategoryIssues = issues.any((i) => i.type == DataIssueType.missingCategory);
      if (hasCategoryIssues) {
        buffer.writeln('2. **完善分类信息**');
        buffer.writeln('   - 为现有记录添加合适的分类标签');
        buffer.writeln('   - 建立个人化的分类体系(如：餐饮、交通、娱乐等)');
        buffer.writeln('   - 使用自动分类功能提高效率');
        buffer.writeln('');
      }
      
      buffer.writeln('3. **提高数据质量**');
      buffer.writeln('   - 每次添加记录时，确保所有必填字段都已填写');
      buffer.writeln('   - 定期检查和清理数据');
      buffer.writeln('   - 使用数据验证工具防止类似问题');
    } else {
      buffer.writeln('💡 **Immediate Action Recommendations**');
      buffer.writeln('');
      
      final hasAmountIssues = issues.any((i) => 
        i.type == DataIssueType.missingAmount || i.type == DataIssueType.zeroAmount);
      
      if (hasAmountIssues) {
        buffer.writeln('1. **Fill in Missing Amounts**');
        buffer.writeln('   - Review recent expense records and add missing amounts');
        buffer.writeln('   - Confirm if zero-amount records are actually free items');
        buffer.writeln('   - Set reminders to ensure future records include accurate amounts');
        buffer.writeln('');
      }
      
      final hasCategoryIssues = issues.any((i) => i.type == DataIssueType.missingCategory);
      if (hasCategoryIssues) {
        buffer.writeln('2. **Complete Category Information**');
        buffer.writeln('   - Add appropriate category tags to existing records');
        buffer.writeln('   - Establish a personalized categorization system');
        buffer.writeln('   - Use auto-categorization features to improve efficiency');
        buffer.writeln('');
      }
      
      buffer.writeln('3. **Improve Data Quality**');
      buffer.writeln('   - Ensure all required fields are filled when adding records');
      buffer.writeln('   - Regularly review and clean up data');
      buffer.writeln('   - Use data validation tools to prevent similar issues');
    }
    
    return buffer.toString();
  }
  
  static String _generateDataImprovementGuide(List<DataIssue> issues, String language) {
    final buffer = StringBuffer();
    
    if (language == 'zh') {
      buffer.writeln('🔧 **数据完善指南**');
      buffer.writeln('');
      buffer.writeln('为了获得更准确的分析结果，建议您：');
      buffer.writeln('');
      buffer.writeln('**短期目标 (本周内)**:');
      buffer.writeln('- 补充最近7天的缺失数据');
      buffer.writeln('- 为无分类的记录添加分类');
      buffer.writeln('- 验证金额异常的记录');
      buffer.writeln('');
      buffer.writeln('**中期目标 (本月内)**:');
      buffer.writeln('- 建立完整的个人财务记录习惯');
      buffer.writeln('- 设置自动提醒和分类规则');
      buffer.writeln('- 定期数据质量检查');
      buffer.writeln('');
      buffer.writeln('**长期目标**:');
      buffer.writeln('- 积累3-6个月的高质量数据');
      buffer.writeln('- 启用高级分析功能(趋势预测、模式识别)');
      buffer.writeln('- 建立个性化的理财洞察');
      buffer.writeln('');
      buffer.writeln('💭 **完善数据后，您可以询问**:');
      buffer.writeln('- "我的月度支出趋势如何？"');
      buffer.writeln('- "哪个分类的支出增长最快？"');
      buffer.writeln('- "给我一些节省开支的建议"');
    } else {
      buffer.writeln('🔧 **Data Improvement Guide**');
      buffer.writeln('');
      buffer.writeln('To get more accurate analysis results, I recommend:');
      buffer.writeln('');
      buffer.writeln('**Short-term goals (this week)**:');
      buffer.writeln('- Fill in missing data from the last 7 days');
      buffer.writeln('- Add categories to uncategorized records');
      buffer.writeln('- Verify records with abnormal amounts');
      buffer.writeln('');
      buffer.writeln('**Medium-term goals (this month)**:');
      buffer.writeln('- Establish complete personal finance recording habits');
      buffer.writeln('- Set up automatic reminders and categorization rules');
      buffer.writeln('- Regular data quality checks');
      buffer.writeln('');
      buffer.writeln('**Long-term goals**:');
      buffer.writeln('- Accumulate 3-6 months of high-quality data');
      buffer.writeln('- Enable advanced analysis features');
      buffer.writeln('- Build personalized financial insights');
      buffer.writeln('');
      buffer.writeln('💭 **After improving your data, you can ask**:');
      buffer.writeln('- "What are my monthly spending trends?"');
      buffer.writeln('- "Which category is growing fastest in expenses?"');
      buffer.writeln('- "Give me some money-saving suggestions"');
    }
    
    return buffer.toString();
  }
}

/// 数据问题类型
enum DataIssueType {
  missingAmount,
  zeroAmount,
  missingCategory,
  invalidDate,
  duplicateRecord,
  inconsistentCurrency,
}

/// 数据问题描述
@immutable
class DataIssue {
  final DataIssueType type;
  final int count;
  final String description;
  final List<String> affectedRecordIds;
  
  const DataIssue({
    required this.type,
    required this.count,
    required this.description,
    this.affectedRecordIds = const [],
  });
}

/// 数据质量分析器
class DataQualityAnalyzer {
  
  /// 分析财务记录的数据质量
  static List<DataIssue> analyzeFinanceRecords(List<Map<String, dynamic>> records) {
    final issues = <DataIssue>[];
    
    // 检查金额缺失
    final missingAmountRecords = records.where((r) => 
      r['amount'] == null || r['amount'] == 0.0).toList();
    
    if (missingAmountRecords.isNotEmpty) {
      issues.add(DataIssue(
        type: DataIssueType.missingAmount,
        count: missingAmountRecords.length,
        description: 'Records with missing or zero amounts',
        affectedRecordIds: missingAmountRecords.map((r) => r['id'].toString()).toList(),
      ));
    }
    
    // 检查分类缺失
    final missingCategoryRecords = records.where((r) => 
      r['category'] == null || r['category'].toString().isEmpty).toList();
    
    if (missingCategoryRecords.isNotEmpty) {
      issues.add(DataIssue(
        type: DataIssueType.missingCategory,
        count: missingCategoryRecords.length,
        description: 'Records with missing category information',
        affectedRecordIds: missingCategoryRecords.map((r) => r['id'].toString()).toList(),
      ));
    }
    
    // 检查日期异常
    final invalidDateRecords = records.where((r) {
      try {
        final date = DateTime.parse(r['date'].toString());
        final now = DateTime.now();
        // 检查日期是否在合理范围内(不能是未来日期，不能太古老)
        return date.isAfter(now) || date.isBefore(DateTime(2020));
      } catch (e) {
        return true; // 解析失败也算异常
      }
    }).toList();
    
    if (invalidDateRecords.isNotEmpty) {
      issues.add(DataIssue(
        type: DataIssueType.invalidDate,
        count: invalidDateRecords.length,
        description: 'Records with invalid or unreasonable dates',
        affectedRecordIds: invalidDateRecords.map((r) => r['id'].toString()).toList(),
      ));
    }
    
    return issues;
  }
  
  /// 计算数据完整性评分 (0.0 - 1.0)
  static double calculateCompletenessScore(List<Map<String, dynamic>> records) {
    if (records.isEmpty) return 0.0;
    
    int totalFields = 0;
    int completedFields = 0;
    
    for (final record in records) {
      // 检查关键字段
      final keyFields = ['amount', 'category', 'date', 'type'];
      
      for (final field in keyFields) {
        totalFields++;
        final value = record[field];
        if (value != null && value.toString().isNotEmpty && value != 0.0) {
          completedFields++;
        }
      }
    }
    
    return totalFields > 0 ? completedFields / totalFields : 0.0;
  }
}
