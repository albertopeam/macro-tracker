import 'package:flutter/material.dart';
import '../../core/constants.dart';

class MacroChip extends StatelessWidget {
  final String label;
  final double value;
  final double? target;
  final Color color;
  final bool compact;

  const MacroChip({
    super.key,
    required this.label,
    required this.value,
    this.target,
    required this.color,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final text = compact
        ? '${_fmt(value)}g'
        : target != null
            ? '${_fmt(value)}/${_fmt(target!)}g'
            : '${_fmt(value)}g';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 10, color: color, fontWeight: FontWeight.w600)),
        const SizedBox(height: 1),
        Text(text,
            style: TextStyle(
                fontSize: compact ? 11 : 12, fontWeight: FontWeight.bold)),
      ],
    );
  }

  static String _fmt(double v) =>
      v >= 100 ? v.round().toString() : v.toStringAsFixed(1);
}

class MacroProgressRow extends StatelessWidget {
  final double protein;
  final double carbs;
  final double fat;
  final double calories;
  final double? proteinTarget;
  final double? carbsTarget;
  final double? fatTarget;
  final double? caloriesTarget;

  const MacroProgressRow({
    super.key,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.calories,
    this.proteinTarget,
    this.carbsTarget,
    this.fatTarget,
    this.caloriesTarget,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        MacroChip(label: 'Protein', value: protein, target: proteinTarget, color: AppColors.protein),
        MacroChip(label: 'Carbs', value: carbs, target: carbsTarget, color: AppColors.carbs),
        MacroChip(label: 'Fat', value: fat, target: fatTarget, color: AppColors.fat),
        MacroChip(label: 'Kcal', value: calories, target: caloriesTarget, color: AppColors.calories),
      ],
    );
  }
}
