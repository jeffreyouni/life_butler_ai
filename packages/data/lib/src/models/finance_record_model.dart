import 'package:core/core.dart';
import 'package:meta/meta.dart';

@immutable
class FinanceRecordModel extends BaseModel {
  const FinanceRecordModel({
    required super.id,
    required super.userId,
    required super.createdAt,
    required super.updatedAt,
    super.deletedAt,
    required this.type,
    required this.amount,
    this.currency = 'USD',
    required this.time,
    this.category,
    List<String> tags = const [],
    this.notes,
  }) : _tags = tags;

  final String type; // 'income' or 'expense'
  final double amount;
  final String currency;
  final DateTime time;
  final String? category;
  final List<String> _tags;
  final String? notes;

  @override
  String get objectType => 'finance_records';

  @override
  String get searchableContent {
    final buffer = StringBuffer();
    
    // Finance record with semantic labels
    buffer.writeln('Financial Transaction:');
    buffer.writeln('Type: ${type == 'income' ? 'Income' : 'Expense'}');
    buffer.writeln('Amount: $amount $currency');
    buffer.writeln('Date: ${time.toIso8601String().split('T')[0]}');
    
    if (category != null && category!.isNotEmpty) {
      buffer.writeln('Category: $category');
    }
    
    if (notes != null && notes!.isNotEmpty) {
      buffer.writeln('Notes: $notes');
    }
    
    if (_tags.isNotEmpty) {
      buffer.writeln('Tags: ${_tags.join(', ')}');
    }
    
    return buffer.toString().trim();
  }

  @override
  String get displayTitle => '${type == 'income' ? '+' : '-'}$amount $currency${category != null ? ' ($category)' : ''}';

  @override
  List<String> get tags {
    final recordTags = <String>[];
    recordTags.addAll(_tags); // Use private field
    recordTags.add(type);
    if (category != null) {
      recordTags.add(category!);
    }
    return recordTags;
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'type': type,
      'amount': amount,
      'currency': currency,
      'time': time.toIso8601String(),
      'category': category,
      'tags_json': _tags,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'deleted_at': deletedAt?.toIso8601String(),
    };
  }

  factory FinanceRecordModel.fromMap(Map<String, dynamic> map) {
    return FinanceRecordModel(
      id: map['id'],
      userId: map['user_id'],
      type: map['type'],
      amount: map['amount'].toDouble(),
      currency: map['currency'] ?? 'USD',
      time: DateTime.parse(map['time']),
      category: map['category'],
      tags: List<String>.from(map['tags_json'] ?? []),
      notes: map['notes'],
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
      deletedAt: map['deleted_at'] != null ? DateTime.parse(map['deleted_at']) : null,
    );
  }

  factory FinanceRecordModel.fromDrift(dynamic row) {
    return FinanceRecordModel(
      id: row.id,
      userId: row.userId,
      type: row.type,
      amount: row.amount,
      currency: row.currency,
      time: row.time,
      category: row.category,
      tags: row.tagsJson != null ? List<String>.from(row.tagsJson) : [],
      notes: row.notes,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
      deletedAt: row.deletedAt,
    );
  }
}
