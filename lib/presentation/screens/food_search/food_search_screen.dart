import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/food.dart';
import '../../../domain/parsing/fuzzy_matcher.dart';
import '../../../presentation/providers/providers.dart';

/// Pushed when the user taps "Search…" in the food dropdown.
/// Returns the selected [Food] via Navigator.pop.
class FoodSearchScreen extends ConsumerStatefulWidget {
  const FoodSearchScreen({super.key});

  static Future<Food?> push(BuildContext context) =>
      Navigator.of(context).push<Food?>(
          MaterialPageRoute(builder: (_) => const FoodSearchScreen()));

  @override
  ConsumerState<FoodSearchScreen> createState() => _FoodSearchScreenState();
}

class _FoodSearchScreenState extends ConsumerState<FoodSearchScreen> {
  final _ctrl = TextEditingController();
  List<FuzzyResult> _results = [];

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _search(String query) {
    final matcher = ref.read(fuzzyMatcherProvider);
    setState(() {
      _results = query.trim().isEmpty
          ? []
          : matcher.search(query.trim(), limit: 20);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _ctrl,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Search foods…',
            border: InputBorder.none,
          ),
          onChanged: _search,
        ),
        actions: [
          if (_ctrl.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                _ctrl.clear();
                _search('');
              },
            ),
        ],
      ),
      body: _results.isEmpty
          ? Center(
              child: Text(
                _ctrl.text.isEmpty
                    ? 'Start typing to search'
                    : 'No matches for "${_ctrl.text}"',
                style: TextStyle(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.5)),
              ),
            )
          : ListView.separated(
              itemCount: _results.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (ctx, i) {
                final food = _results[i].food;
                return ListTile(
                  title: Text(food.name),
                  subtitle: Text(food.category),
                  trailing: Text(
                    'P${food.proteinPer100g.toStringAsFixed(1)} '
                    'C${food.carbsPer100g.toStringAsFixed(1)} '
                    'F${food.fatPer100g.toStringAsFixed(1)}',
                    style: const TextStyle(fontSize: 11),
                  ),
                  onTap: () => Navigator.of(context).pop(food),
                );
              },
            ),
    );
  }
}
