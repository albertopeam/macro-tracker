import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../data/models/meal_entry.dart';
import '../../../../presentation/providers/providers.dart';
import '../../../shared/macro_chip.dart';

class DayDetailSheet extends ConsumerWidget {
  final DateTime day;

  const DayDetailSheet({super.key, required this.day});

  String get _dateKey => DateFormat('yyyy-MM-dd').format(day);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logAsync = ref.watch(logProvider(_dateKey));
    final goalsAsync = ref.watch(goalsProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.3,
      maxChildSize: 0.95,
      expand: false,
      builder: (ctx, scroll) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Text(
            DateFormat('EEEE, MMMM d').format(day),
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: logAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (log) {
                if (!log.hasAnyEntry) {
                  return const Center(child: Text('No entries for this day.'));
                }
                final goals = goalsAsync.valueOrNull;
                return ListView(
                  controller: scroll,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    if (goals != null)
                      MacroProgressRow(
                        protein: log.totals.protein,
                        carbs: log.totals.carbs,
                        fat: log.totals.fat,
                        calories: log.totals.calories,
                        proteinTarget: goals.proteinG,
                        carbsTarget: goals.carbsG,
                        fatTarget: goals.fatG,
                        caloriesTarget: goals.caloriesKcal,
                      ),
                    const SizedBox(height: 12),
                    ...MealType.values.map((type) {
                      final entries = log.entriesForMeal(type);
                      if (entries.isEmpty) return const SizedBox.shrink();
                      final totals = log.totalsForMeal(type);
                      return _MealBlock(
                          type: type, entries: entries, totals: totals);
                    }),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _MealBlock extends StatelessWidget {
  final MealType type;
  final List<MealEntry> entries;
  final totals;

  const _MealBlock(
      {required this.type, required this.entries, required this.totals});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(type.displayName,
            style: const TextStyle(
                fontWeight: FontWeight.w700, fontSize: 14)),
        const Divider(height: 8),
        ...entries.map((e) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  Expanded(
                    child: Text('${e.foodName} ${_fmtG(e.grams)}g',
                        style: const TextStyle(fontSize: 13)),
                  ),
                  Text(
                    'P${_f(e.protein)} C${_f(e.carbs)} F${_f(e.fat)} ${e.calories.round()}kcal',
                    style: const TextStyle(fontSize: 11),
                  ),
                ],
              ),
            )),
        const SizedBox(height: 8),
      ],
    );
  }

  static String _f(double v) => v.toStringAsFixed(1);
  static String _fmtG(double g) =>
      g == g.roundToDouble() ? g.round().toString() : g.toStringAsFixed(1);
}
