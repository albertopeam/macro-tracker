import 'dart:convert';

class Food {
  final int? id;
  final String name;
  final String category;
  final double proteinPer100g;
  final double carbsPer100g;
  final double fatPer100g;
  final double caloriesPer100g;
  final List<String> aliases;

  const Food({
    this.id,
    required this.name,
    required this.category,
    required this.proteinPer100g,
    required this.carbsPer100g,
    required this.fatPer100g,
    required this.caloriesPer100g,
    this.aliases = const [],
  });

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'name': name,
        'category': category,
        'protein_per_100g': proteinPer100g,
        'carbs_per_100g': carbsPer100g,
        'fat_per_100g': fatPer100g,
        'calories_per_100g': caloriesPer100g,
        'aliases': jsonEncode(aliases),
      };

  factory Food.fromMap(Map<String, dynamic> map) {
    List<String> parseAliases(dynamic raw) {
      if (raw == null || raw.toString().isEmpty) return [];
      try {
        final decoded = jsonDecode(raw.toString());
        if (decoded is List) return decoded.cast<String>();
      } catch (_) {}
      return raw.toString().split(',').map((s) => s.trim()).toList();
    }

    return Food(
      id: map['id'] as int?,
      name: map['name'] as String,
      category: map['category'] as String,
      proteinPer100g: (map['protein_per_100g'] as num).toDouble(),
      carbsPer100g: (map['carbs_per_100g'] as num).toDouble(),
      fatPer100g: (map['fat_per_100g'] as num).toDouble(),
      caloriesPer100g: (map['calories_per_100g'] as num).toDouble(),
      aliases: parseAliases(map['aliases']),
    );
  }

  @override
  String toString() => 'Food($name)';
}
