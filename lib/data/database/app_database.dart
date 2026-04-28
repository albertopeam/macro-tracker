import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  AppDatabase._();
  static final AppDatabase instance = AppDatabase._();

  Database? _db;

  Future<Database> get database async {
    _db ??= await _init();
    return _db!;
  }

  Future<Database> _init() async {
    final dir = await getApplicationDocumentsDirectory();
    final path = join(dir.path, 'macro_tracker.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE foods (
        id               INTEGER PRIMARY KEY AUTOINCREMENT,
        name             TEXT    NOT NULL UNIQUE,
        category         TEXT    NOT NULL,
        protein_per_100g REAL    NOT NULL DEFAULT 0.0,
        carbs_per_100g   REAL    NOT NULL DEFAULT 0.0,
        fat_per_100g     REAL    NOT NULL DEFAULT 0.0,
        calories_per_100g REAL   NOT NULL DEFAULT 0.0,
        aliases          TEXT    NOT NULL DEFAULT '[]'
      )
    ''');

    await db.execute('''
      CREATE TABLE meal_entries (
        id         TEXT PRIMARY KEY,
        date       TEXT NOT NULL,
        meal_type  TEXT NOT NULL,
        food_id    INTEGER NOT NULL,
        food_name  TEXT NOT NULL,
        grams      REAL NOT NULL,
        protein    REAL NOT NULL,
        carbs      REAL NOT NULL,
        fat        REAL NOT NULL,
        calories   REAL NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute(
        'CREATE INDEX idx_meal_date ON meal_entries(date)');
    await db.execute(
        'CREATE INDEX idx_meal_date_type ON meal_entries(date, meal_type)');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Add migration blocks here as the schema evolves:
    // if (oldVersion < 2) { await db.execute('ALTER TABLE ...'); }
  }
}
