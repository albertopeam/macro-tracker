import '../database/app_database.dart';
import '../database/food_dao.dart';
import '../models/food.dart';

class FoodRepository {
  FoodRepository._();
  static final FoodRepository instance = FoodRepository._();

  FoodDao? _dao;

  Future<FoodDao> _getDao() async {
    if (_dao != null) return _dao!;
    final db = await AppDatabase.instance.database;
    _dao = FoodDao(db);
    return _dao!;
  }

  Future<List<Food>> getAllFoods() async {
    final dao = await _getDao();
    return dao.getAll();
  }
}
