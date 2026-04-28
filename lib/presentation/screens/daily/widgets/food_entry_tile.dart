import 'package:flutter/material.dart';
import '../../../../core/constants.dart';
import '../../../../data/models/meal_entry.dart';

class FoodEntryTile extends StatelessWidget {
  final MealEntry entry;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const FoodEntryTile({
    super.key,
    required this.entry,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(entry.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        color: Colors.red.shade400,
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Delete entry?'),
            content: Text('Remove ${entry.foodName}?'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancel')),
              TextButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Delete',
                      style: TextStyle(color: Colors.red))),
            ],
          ),
        );
      },
      onDismissed: (_) => onDelete(),
      child: InkWell(
        onTap: onEdit,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(entry.foodName,
                        style: const TextStyle(fontWeight: FontWeight.w500)),
                    Text('${_fmtGrams(entry.grams)}g',
                        style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.6))),
                  ],
                ),
              ),
              _miniChip('P', entry.protein, AppColors.protein),
              const SizedBox(width: 6),
              _miniChip('C', entry.carbs, AppColors.carbs),
              const SizedBox(width: 6),
              _miniChip('F', entry.fat, AppColors.fat),
              const SizedBox(width: 6),
              _miniChip('kcal', entry.calories, AppColors.calories,
                  isCalories: true),
            ],
          ),
        ),
      ),
    );
  }

  Widget _miniChip(String label, double value, Color color,
      {bool isCalories = false}) {
    return Column(
      children: [
        Text(label,
            style: TextStyle(fontSize: 9, color: color, fontWeight: FontWeight.w600)),
        Text(
            isCalories
                ? value.round().toString()
                : '${value.toStringAsFixed(1)}g',
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
      ],
    );
  }

  static String _fmtGrams(double g) =>
      g == g.roundToDouble() ? g.round().toString() : g.toStringAsFixed(1);
}
