import 'package:sqflite/sqflite.dart';
import '../models/meal_entry.dart';

class MealEntryDao {
  final Database db;
  MealEntryDao(this.db);

  Future<void> insertBatch(List<MealEntry> entries) async {
    final batch = db.batch();
    for (final e in entries) {
      batch.insert('meal_entries', e.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<void> delete(String id) async {
    await db.delete('meal_entries', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteMany(List<String> ids) async {
    if (ids.isEmpty) return;
    final placeholders = List.filled(ids.length, '?').join(',');
    await db.delete('meal_entries', where: 'id IN ($placeholders)', whereArgs: ids);
  }

  Future<void> update(MealEntry entry) async {
    await db.update(
      'meal_entries',
      {
        'grams': entry.grams,
        'protein': entry.protein,
        'carbs': entry.carbs,
        'fat': entry.fat,
        'calories': entry.calories,
      },
      where: 'id = ?',
      whereArgs: [entry.id],
    );
  }

  Future<List<MealEntry>> getByDate(String date) async {
    final rows = await db.query(
      'meal_entries',
      where: 'date = ?',
      whereArgs: [date],
      orderBy: 'created_at ASC',
    );
    return rows.map(MealEntry.fromMap).toList();
  }

  /// Returns a map of date → total calories for all dates in [month] (YYYY-MM).
  Future<Map<String, double>> getMonthlyCalories(String month) async {
    final rows = await db.rawQuery(
      "SELECT date, SUM(calories) as total FROM meal_entries "
      "WHERE date LIKE ? GROUP BY date",
      ['$month%'],
    );
    return {for (final r in rows) r['date'] as String: (r['total'] as num).toDouble()};
  }
}
