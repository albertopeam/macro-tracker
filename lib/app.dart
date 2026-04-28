import 'package:flutter/material.dart';
import 'core/theme.dart';
import 'presentation/screens/main_scaffold.dart';

class MacroTrackerApp extends StatelessWidget {
  const MacroTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Macro Tracker',
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      home: const MainScaffold(),
      debugShowCheckedModeBanner: false,
    );
  }
}
