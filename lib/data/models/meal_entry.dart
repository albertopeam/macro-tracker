enum MealType { breakfast, lunch, dinner, snack }

extension MealTypeExtension on MealType {
  String get displayName {
    switch (this) {
      case MealType.breakfast:
        return 'Breakfast';
      case MealType.lunch:
        return 'Lunch';
      case MealType.dinner:
        return 'Dinner';
      case MealType.snack:
        return 'Extra';
    }
  }

  String get dbValue => name;

  static MealType fromDb(String value) =>
      MealType.values.firstWhere(
        (e) => e.name == value,
        orElse: () {
          print('Unknown meal type in DB: "$value", defaulting to snack');
          return MealType.snack;
        },
      );
}

class MealEntry {
  final String id;
  final String date;
  final MealType mealType;
  final int foodId;
  final String foodName;
  final double grams;
  final double protein;
  final double carbs;
  final double fat;
  final double calories;
  final DateTime createdAt;

  const MealEntry({
    required this.id,
    required this.date,
    required this.mealType,
    required this.foodId,
    required this.foodName,
    required this.grams,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.calories,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'date': date,
        'meal_type': mealType.dbValue,
        'food_id': foodId,
        'food_name': foodName,
        'grams': grams,
        'protein': protein,
        'carbs': carbs,
        'fat': fat,
        'calories': calories,
        'created_at': createdAt.toIso8601String(),
      };

  factory MealEntry.fromMap(Map<String, dynamic> map) => MealEntry(
        id: map['id'] as String,
        date: map['date'] as String,
        mealType:
            MealTypeExtension.fromDb(map['meal_type'] as String),
        foodId: map['food_id'] as int,
        foodName: map['food_name'] as String,
        grams: (map['grams'] as num).toDouble(),
        protein: (map['protein'] as num).toDouble(),
        carbs: (map['carbs'] as num).toDouble(),
        fat: (map['fat'] as num).toDouble(),
        calories: (map['calories'] as num).toDouble(),
        createdAt: _parseDate(map['created_at'] as String),
      );

  static DateTime _parseDate(String value) {
    try {
      return DateTime.parse(value);
    } catch (_) {
      return DateTime.now();
    }
  }

  MealEntry copyWith({double? grams, double? protein, double? carbs, double? fat, double? calories}) =>
      MealEntry(
        id: id,
        date: date,
        mealType: mealType,
        foodId: foodId,
        foodName: foodName,
        grams: grams ?? this.grams,
        protein: protein ?? this.protein,
        carbs: carbs ?? this.carbs,
        fat: fat ?? this.fat,
        calories: calories ?? this.calories,
        createdAt: createdAt,
      );
}
