import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import '../models/food.dart';
import 'food_dao.dart';
import '../../core/constants.dart';

class DbSeeder {
  static Future<void> seedIfNeeded(Database db) async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(AppStrings.dbSeededKey) == true) return;

    final dao = FoodDao(db);
    final foods = await _parseCsv();
    await dao.insertBatch(foods);
    await prefs.setBool(AppStrings.dbSeededKey, true);
  }

  static Future<List<Food>> _parseCsv() async {
    final raw = await rootBundle.loadString('assets/foods/foods.csv');
    final lines = raw.split('\n');
    final foods = <Food>[];

    for (int i = 1; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;
      final food = _parseLine(line, i);
      if (food != null) foods.add(food);
    }
    return foods;
  }

  static Food? _parseLine(String line, int lineNumber) {
    try {
      final fields = _splitCsvLine(line);
      if (fields.length < 7) return null;
      return Food(
        name: fields[0].trim(),
        category: fields[1].trim(),
        proteinPer100g: double.parse(fields[2].trim()),
        carbsPer100g: double.parse(fields[3].trim()),
        fatPer100g: double.parse(fields[4].trim()),
        caloriesPer100g: double.parse(fields[5].trim()),
        aliases: fields.length > 6
            ? fields[6]
                .trim()
                .split(',')
                .map((s) => s.trim())
                .where((s) => s.isNotEmpty)
                .toList()
            : [],
      );
    } catch (e) {
      debugPrint('DbSeeder: failed to parse line $lineNumber: "$line" → $e');
      return null;
    }
  }

  static List<String> _splitCsvLine(String line) {
    final fields = <String>[];
    final buffer = StringBuffer();
    bool inQuotes = false;

    for (int i = 0; i < line.length; i++) {
      final ch = line[i];
      if (ch == '"') {
        inQuotes = !inQuotes;
      } else if (ch == ',' && !inQuotes) {
        fields.add(buffer.toString());
        buffer.clear();
      } else {
        buffer.write(ch);
      }
    }
    fields.add(buffer.toString());
    return fields;
  }
}
