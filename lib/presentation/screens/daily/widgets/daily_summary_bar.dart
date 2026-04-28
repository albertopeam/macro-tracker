import 'package:flutter/material.dart';
import '../../../../core/constants.dart';
import '../../../../data/models/macro_totals.dart';

class DailySummaryBar extends StatelessWidget {
  final MacroTotals totals;
  final MacroGoals goals;

  const DailySummaryBar({
    super.key,
    required this.totals,
    required this.goals,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _MacroColumn(
                  label: 'Protein',
                  value: totals.protein,
                  target: goals.proteinG,
                  color: AppColors.protein,
                ),
                _MacroColumn(
                  label: 'Carbs',
                  value: totals.carbs,
                  target: goals.carbsG,
                  color: AppColors.carbs,
                ),
                _MacroColumn(
                  label: 'Fat',
                  value: totals.fat,
                  target: goals.fatG,
                  color: AppColors.fat,
                ),
                _MacroColumn(
                  label: 'kcal',
                  value: totals.calories,
                  target: goals.caloriesKcal,
                  color: AppColors.calories,
                  isCalories: true,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MacroColumn extends StatelessWidget {
  final String label;
  final double value;
  final double target;
  final Color color;
  final bool isCalories;

  const _MacroColumn({
    required this.label,
    required this.value,
    required this.target,
    required this.color,
    this.isCalories = false,
  });

  @override
  Widget build(BuildContext context) {
    final pct = (target > 0 ? (value / target).clamp(0.0, 1.0) : 0.0);
    final display = isCalories
        ? '${value.round()}/${target.round()}'
        : '${_f(value)}/${_f(target)}g';

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          children: [
            Text(label,
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: color)),
            const SizedBox(height: 2),
            Text(display,
                style: const TextStyle(
                    fontSize: 11, fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: pct,
                minHeight: 5,
                backgroundColor: color.withValues(alpha: 0.15),
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _f(double v) =>
      v >= 100 ? v.round().toString() : v.toStringAsFixed(1);
}
