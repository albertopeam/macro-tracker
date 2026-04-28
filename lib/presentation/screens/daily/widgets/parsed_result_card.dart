import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants.dart';
import '../../../../data/models/food.dart';
import '../../../../data/models/meal_entry.dart';
import '../../../../domain/parsing/fuzzy_matcher.dart';
import '../../../../domain/services/macro_calculator.dart';
import '../../food_search/food_search_screen.dart';

class ParsedResultCard extends StatefulWidget {
  final Food? matchedFood;
  final List<FuzzyResult> alternatives;
  final double initialGrams;
  final MealType mealType;
  final String date;
  final void Function(MealEntry entry) onConfirmed;
  final VoidCallback onRemove;

  const ParsedResultCard({
    super.key,
    required this.matchedFood,
    required this.alternatives,
    required this.initialGrams,
    required this.mealType,
    required this.date,
    required this.onConfirmed,
    required this.onRemove,
  });

  @override
  State<ParsedResultCard> createState() => _ParsedResultCardState();
}

class _ParsedResultCardState extends State<ParsedResultCard> {
  late TextEditingController _gramsCtrl;
  Food? _selectedFood;
  late double _grams;

  @override
  void initState() {
    super.initState();
    _selectedFood = widget.matchedFood;
    _grams = widget.initialGrams;
    _gramsCtrl =
        TextEditingController(text: _fmtGrams(widget.initialGrams));
  }

  @override
  void dispose() {
    _gramsCtrl.dispose();
    super.dispose();
  }

  MealEntry? get _entry {
    if (_selectedFood == null) return null;
    return MacroCalculator.calculate(
      food: _selectedFood!,
      grams: _grams,
      mealType: widget.mealType,
      date: widget.date,
    );
  }

  @override
  Widget build(BuildContext context) {
    final entry = _entry;
    final hasFood = _selectedFood != null;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: _FoodDropdown(
                    selected: _selectedFood,
                    alternatives: widget.alternatives,
                    onChanged: (f) => setState(() => _selectedFood = f),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: widget.onRemove,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                SizedBox(
                  width: 90,
                  child: TextField(
                    controller: _gramsCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                          RegExp(r'^\d*\.?\d*'))
                    ],
                    decoration: const InputDecoration(
                      isDense: true,
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      border: OutlineInputBorder(),
                      labelText: 'Grams',
                    ),
                    onChanged: (v) {
                      final g = double.tryParse(v);
                      if (g != null && g > 0) setState(() => _grams = g);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                if (hasFood && entry != null) ...[
                  _MacroMini('P', entry.protein, AppColors.protein),
                  const SizedBox(width: 8),
                  _MacroMini('C', entry.carbs, AppColors.carbs),
                  const SizedBox(width: 8),
                  _MacroMini('F', entry.fat, AppColors.fat),
                  const SizedBox(width: 8),
                  _MacroMini('kcal', entry.calories, AppColors.calories,
                      isCalories: true),
                ] else
                  Text(
                    'Select a food to see macros',
                    style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context)
                            .colorScheme
                            .error),
                  ),
              ],
            ),
            if (hasFood && entry != null) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.tonal(
                  onPressed: () => widget.onConfirmed(entry),
                  child: Text('Add to ${widget.mealType.displayName}'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static String _fmtGrams(double g) =>
      g == g.roundToDouble() ? g.round().toString() : g.toStringAsFixed(1);
}

class _FoodDropdown extends StatelessWidget {
  final Food? selected;
  final List<FuzzyResult> alternatives;
  final void Function(Food?) onChanged;

  const _FoodDropdown({
    required this.selected,
    required this.alternatives,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final items = <DropdownMenuItem<Food?>>[
      if (selected != null &&
          !alternatives.any((a) => a.food.id == selected!.id))
        DropdownMenuItem(
            value: selected,
            child: Text(selected!.name,
                overflow: TextOverflow.ellipsis)),
      ...alternatives.map((r) => DropdownMenuItem(
          value: r.food,
          child: Text(r.food.name, overflow: TextOverflow.ellipsis))),
      const DropdownMenuItem(
          value: null,
          child: Text('Search…',
              style: TextStyle(fontStyle: FontStyle.italic))),
    ];

    return DropdownButtonFormField<Food?>(
      initialValue: selected,
      isExpanded: true,
      decoration: const InputDecoration(
        isDense: true,
        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        border: OutlineInputBorder(),
        labelText: 'Food',
      ),
      items: items,
      onChanged: (food) async {
        if (food == null) {
          // "Search…" — open full search screen
          // ignore: use_build_context_synchronously
          final picked = await FoodSearchScreen.push(context);
          if (picked != null) onChanged(picked);
          return;
        }
        onChanged(food);
      },
    );
  }
}

class _MacroMini extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  final bool isCalories;

  const _MacroMini(this.label, this.value, this.color,
      {this.isCalories = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 9, color: color, fontWeight: FontWeight.bold)),
        Text(
            isCalories
                ? value.round().toString()
                : '${value.toStringAsFixed(1)}g',
            style: const TextStyle(fontSize: 10)),
      ],
    );
  }
}
