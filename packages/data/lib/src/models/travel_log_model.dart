import 'package:core/core.dart';
import 'package:meta/meta.dart';

@immutable
class TravelLogModel extends BaseModel {
  const TravelLogModel({
    required super.id,
    required super.userId,
    required super.createdAt,
    required super.updatedAt,
    super.deletedAt,
    required this.place,
    required this.startDate,
    this.endDate,
    this.companions = const [],
    this.cost,
    this.notes,
  });

  final String place;
  final DateTime startDate;
  final DateTime? endDate;
  final List<String> companions;
  final double? cost;
  final String? notes;

  @override
  String get objectType => 'travel_logs';

  @override
  String get searchableContent {
    final buffer = StringBuffer();
    
    // Travel log with semantic labels
    buffer.writeln('Travel Log:');
    buffer.writeln('Destination: $place');
    buffer.writeln('Start Date: ${startDate.toIso8601String().split('T')[0]}');
    
    if (endDate != null) {
      buffer.writeln('End Date: ${endDate!.toIso8601String().split('T')[0]}');
    }
    
    if (companions.isNotEmpty) {
      buffer.writeln('Companions: ${companions.join(', ')}');
    }
    
    if (cost != null) {
      buffer.writeln('Cost: \$${cost!.toStringAsFixed(2)}');
    }
    
    if (notes != null && notes!.isNotEmpty) {
      buffer.writeln('Notes: $notes');
    }
    
    return buffer.toString().trim();
  }

  @override
  String get displayTitle => 'Trip to $place';

  @override
  List<String> get tags {
    final travelTags = <String>['travel', 'trip'];
    travelTags.add(place);
    travelTags.addAll(companions);
    return travelTags;
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'place': place,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'companions_json': companions,
      'cost': cost,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'deleted_at': deletedAt?.toIso8601String(),
    };
  }

  factory TravelLogModel.fromMap(Map<String, dynamic> map) {
    return TravelLogModel(
      id: map['id'],
      userId: map['user_id'],
      place: map['place'],
      startDate: DateTime.parse(map['start_date']),
      endDate: map['end_date'] != null ? DateTime.parse(map['end_date']) : null,
      companions: List<String>.from(map['companions_json'] ?? []),
      cost: map['cost']?.toDouble(),
      notes: map['notes'],
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
      deletedAt: map['deleted_at'] != null ? DateTime.parse(map['deleted_at']) : null,
    );
  }

  TravelLogModel copyWith({
    String? place,
    DateTime? startDate,
    DateTime? endDate,
    List<String>? companions,
    double? cost,
    String? notes,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return TravelLogModel(
      id: id,
      userId: userId,
      place: place ?? this.place,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      companions: companions ?? this.companions,
      cost: cost ?? this.cost,
      notes: notes ?? this.notes,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }
}
