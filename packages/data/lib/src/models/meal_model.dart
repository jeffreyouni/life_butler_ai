import 'package:core/core.dart';
import 'package:meta/meta.dart';

@immutable
class MealModel extends BaseModel {
  const MealModel({
    required super.id,
    required super.userId,
    required super.createdAt,
    required super.updatedAt,
    super.deletedAt,
    required this.name,
    this.items = const [],
    this.caloriesInt,
    required this.time,
    this.photoUrl,
    this.location,
    this.notes,
  });

  final String name;
  final List<String> items;
  final int? caloriesInt;
  final DateTime time;
  final String? photoUrl;
  final String? location;
  final String? notes;

  @override
  String get objectType => 'meals';

  @override
  String get searchableContent {
    final buffer = StringBuffer();
    
    // Meal with semantic labels
    buffer.writeln('Meal:');
    buffer.writeln('Name: $name');
    buffer.writeln('Date: ${time.toIso8601String().split('T')[0]}');
    buffer.writeln('Time: ${time.hour}:${time.minute.toString().padLeft(2, '0')}');
    
    if (items.isNotEmpty) {
      buffer.writeln('Items: ${items.join(', ')}');
    }
    
    if (caloriesInt != null) {
      buffer.writeln('Calories: $caloriesInt kcal');
    }
    
    if (location != null && location!.isNotEmpty) {
      buffer.writeln('Location: $location');
    }
    
    if (notes != null && notes!.isNotEmpty) {
      buffer.writeln('Notes: $notes');
    }
    
    return buffer.toString().trim();
  }

  @override
  String get displayTitle => name;

  @override
  List<String> get tags {
    final mealTags = <String>[];
    
    // Add meal type based on time
    final hour = time.hour;
    if (hour >= 5 && hour < 11) {
      mealTags.add('breakfast');
    } else if (hour >= 11 && hour < 15) {
      mealTags.add('lunch');
    } else if (hour >= 17 && hour < 22) {
      mealTags.add('dinner');
    } else {
      mealTags.add('snack');
    }

    // Add location type
    if (location != null) {
      if (location!.toLowerCase().contains('restaurant') || 
          location!.toLowerCase().contains('cafe')) {
        mealTags.add('restaurant');
      } else if (location!.toLowerCase().contains('home')) {
        mealTags.add('home-cooked');
      }
    }

    // Add food type tags based on items
    final itemsText = items.join(' ').toLowerCase();
    if (itemsText.contains('rice') || itemsText.contains('noodle')) {
      mealTags.add('asian');
    }
    if (itemsText.contains('bread') || itemsText.contains('sandwich')) {
      mealTags.add('western');
    }
    if (itemsText.contains('vegetable') || itemsText.contains('salad')) {
      mealTags.add('healthy');
    }

    return mealTags;
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'items_json': items,
      'calories_int': caloriesInt,
      'time': time.toIso8601String(),
      'photo_url': photoUrl,
      'location': location,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'deleted_at': deletedAt?.toIso8601String(),
    };
  }

  factory MealModel.fromMap(Map<String, dynamic> map) {
    return MealModel(
      id: map['id'],
      userId: map['user_id'],
      name: map['name'],
      items: List<String>.from(map['items_json'] ?? []),
      caloriesInt: map['calories_int'],
      time: DateTime.parse(map['time']),
      photoUrl: map['photo_url'],
      location: map['location'],
      notes: map['notes'],
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
      deletedAt: map['deleted_at'] != null ? DateTime.parse(map['deleted_at']) : null,
    );
  }

  MealModel copyWith({
    String? name,
    List<String>? items,
    int? caloriesInt,
    DateTime? time,
    String? photoUrl,
    String? location,
    String? notes,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return MealModel(
      id: id,
      userId: userId,
      name: name ?? this.name,
      items: items ?? this.items,
      caloriesInt: caloriesInt ?? this.caloriesInt,
      time: time ?? this.time,
      photoUrl: photoUrl ?? this.photoUrl,
      location: location ?? this.location,
      notes: notes ?? this.notes,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }
}
