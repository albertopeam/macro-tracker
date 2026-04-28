import '../database/app_database.dart';
import '../database/meal_entry_dao.dart';
import '../models/daily_log.dart';
import '../models/meal_entry.dart';

class LogRepository {
  LogRepository._();
  static final LogRepository instance = LogRepository._();

  MealEntryDao? _dao;

  Future<MealEntryDao> _getDao() async {
    if (_dao != null) return _dao!;
    final db = await AppDatabase.instance.database;
    _dao = MealEntryDao(db);
    return _dao!;
  }

  Future<DailyLog> getDailyLog(String date) async {
    final dao = await _getDao();
    final entries = await dao.getByDate(date);
    final meals = <MealType, List<MealEntry>>{
      MealType.breakfast: [],
      MealType.lunch: [],
      MealType.dinner: [],
      MealType.snack: [],
    };
    for (final e in entries) {
      meals[e.mealType]!.add(e);
    }
    return DailyLog(date: date, meals: meals);
  }

  Future<void> addEntries(List<MealEntry> entries) async {
    final dao = await _getDao();
    await dao.insertBatch(entries);
  }

  Future<void> deleteEntry(String id) async {
    final dao = await _getDao();
    await dao.delete(id);
  }

  Future<void> deleteEntries(List<String> ids) async {
    final dao = await _getDao();
    await dao.deleteMany(ids);
  }

  Future<void> updateEntry(MealEntry entry) async {
    final dao = await _getDao();
    await dao.update(entry);
  }

  Future<Map<String, double>> getMonthlyCalories(String month) async {
    final dao = await _getDao();
    return dao.getMonthlyCalories(month);
  }
}
