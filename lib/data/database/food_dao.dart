import 'package:sqflite/sqflite.dart';
import '../models/food.dart';

class FoodDao {
  final Database db;
  FoodDao(this.db);

  Future<void> insertBatch(List<Food> foods) async {
    final batch = db.batch();
    for (final f in foods) {
      batch.insert('foods', f.toMap(),
          conflictAlgorithm: ConflictAlgorithm.ignore);
    }
    await batch.commit(noResult: true);
  }

  Future<List<Food>> getAll() async {
    final rows = await db.query('foods', orderBy: 'name ASC');
    return rows.map(Food.fromMap).toList();
  }

  Future<Food?> getById(int id) async {
    final rows = await db.query('foods', where: 'id = ?', whereArgs: [id]);
    return rows.isEmpty ? null : Food.fromMap(rows.first);
  }

  Future<int> count() async {
    final result =
        await db.rawQuery('SELECT COUNT(*) as c FROM foods');
    return (result.first['c'] as int?) ?? 0;
  }
}
