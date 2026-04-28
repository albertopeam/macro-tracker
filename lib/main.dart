import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'data/database/app_database.dart';
import 'data/database/db_seeder.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final db = await AppDatabase.instance.database;
  await DbSeeder.seedIfNeeded(db);
  runApp(const ProviderScope(child: MacroTrackerApp()));
}
