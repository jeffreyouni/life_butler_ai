import 'package:core/core.dart';
import 'package:meta/meta.dart';

@immutable
class HealthMetricModel extends BaseModel {
  const HealthMetricModel({
    required super.id,
    required super.userId,
    required super.createdAt,
    required super.updatedAt,
    super.deletedAt,
    required this.metricType,
    required this.valueNum,
    required this.unit,
    required this.time,
    this.notes,
  });

  final String metricType;
  final double valueNum;
  final String unit;
  final DateTime time;
  final String? notes;

  @override
  String get objectType => 'health_metrics';

  @override
  String get searchableContent {
    final buffer = StringBuffer();
    
    // Health metric with semantic labels
    buffer.writeln('Health Metric:');
    buffer.writeln('Type: $metricType');
    buffer.writeln('Value: $valueNum $unit');
    buffer.writeln('Date: ${time.toIso8601String().split('T')[0]}');
    
    if (notes != null && notes!.isNotEmpty) {
      buffer.writeln('Notes: $notes');
    }
    
    return buffer.toString().trim();
  }

  @override
  String get displayTitle => '$metricType: $valueNum $unit';

  @override
  List<String> get tags {
    final healthTags = <String>['health', 'metric'];
    healthTags.add(metricType);
    healthTags.add(unit);
    return healthTags;
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'metric_type': metricType,
      'value_num': valueNum,
      'unit': unit,
      'time': time.toIso8601String(),
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'deleted_at': deletedAt?.toIso8601String(),
    };
  }

  factory HealthMetricModel.fromMap(Map<String, dynamic> map) {
    return HealthMetricModel(
      id: map['id'],
      userId: map['user_id'],
      metricType: map['metric_type'],
      valueNum: map['value_num'].toDouble(),
      unit: map['unit'],
      time: DateTime.parse(map['time']),
      notes: map['notes'],
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
      deletedAt: map['deleted_at'] != null ? DateTime.parse(map['deleted_at']) : null,
    );
  }

  HealthMetricModel copyWith({
    String? metricType,
    double? valueNum,
    String? unit,
    DateTime? time,
    String? notes,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return HealthMetricModel(
      id: id,
      userId: userId,
      metricType: metricType ?? this.metricType,
      valueNum: valueNum ?? this.valueNum,
      unit: unit ?? this.unit,
      time: time ?? this.time,
      notes: notes ?? this.notes,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }
}
