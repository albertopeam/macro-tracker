import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants.dart';
import '../../../../data/models/meal_entry.dart';
import '../../../../presentation/providers/providers.dart';
import 'food_entry_tile.dart';
import 'voice_session_sheet.dart';

class MealSection extends ConsumerWidget {
  final MealType mealType;
  final String date;
  final List<MealEntry> entries;
  final VoidCallback? onRemove;
  final VoidCallback? onCopy;

  const MealSection({
    super.key,
    required this.mealType,
    required this.date,
    required this.entries,
    this.onRemove,
    this.onCopy,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totals = _sumEntries(entries);
    final scheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.fromLTRB(12, 4, 12, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
            child: Row(
              children: [
                Text(
                  mealType.displayName,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 15),
                ),
                const SizedBox(width: 8),
                if (entries.isNotEmpty) ...[
                  _mealMacroChip(
                      '${totals[0].toStringAsFixed(0)}P', AppColors.protein),
                  const SizedBox(width: 4),
                  _mealMacroChip(
                      '${totals[1].toStringAsFixed(0)}C', AppColors.carbs),
                  const SizedBox(width: 4),
                  _mealMacroChip(
                      '${totals[2].toStringAsFixed(0)}F', AppColors.fat),
                  const SizedBox(width: 4),
                  _mealMacroChip(
                      '${totals[3].round()}kcal', AppColors.calories),
                ],
                const Spacer(),
                if (entries.isNotEmpty && onCopy != null)
                  IconButton(
                    icon: Icon(Icons.content_copy, color: scheme.primary, size: 20),
                    tooltip: 'Copy meal to another day',
                    onPressed: onCopy,
                  ),
                IconButton(
                  icon: Icon(Icons.mic, color: scheme.primary),
                  tooltip: 'Add by voice',
                  onPressed: () => _openVoiceInput(context),
                ),
                if (onRemove != null)
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    tooltip: 'Remove section',
                    onPressed: onRemove,
                  ),
              ],
            ),
          ),
          // Entries
          if (entries.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Text(
                'No entries yet. Tap the mic to add.',
                style: TextStyle(
                    fontSize: 12,
                    color: scheme.onSurface.withValues(alpha: 0.45)),
              ),
            )
          else ...[
            ...entries.map((e) => FoodEntryTile(
                  entry: e,
                  onDelete: () =>
                      ref.read(logProvider(date).notifier).deleteEntry(e.id),
                  onEdit: () => _openEditSheet(context, ref, e),
                )),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }

  void _openEditSheet(BuildContext context, WidgetRef ref, MealEntry entry) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _EditEntrySheet(
        entry: entry,
        onSave: (newGrams) {
          if (newGrams > 0 && newGrams != entry.grams) {
            final ratio = newGrams / entry.grams;
            ref.read(logProvider(entry.date).notifier).updateEntry(
                  entry.copyWith(
                    grams: newGrams,
                    protein: entry.protein * ratio,
                    carbs: entry.carbs * ratio,
                    fat: entry.fat * ratio,
                    calories: entry.calories * ratio,
                  ),
                );
          }
        },
        onDelete: () =>
            ref.read(logProvider(entry.date).notifier).deleteEntry(entry.id),
      ),
    );
  }

  List<double> _sumEntries(List<MealEntry> entries) {
    double p = 0, c = 0, f = 0, kcal = 0;
    for (final e in entries) {
      p += e.protein;
      c += e.carbs;
      f += e.fat;
      kcal += e.calories;
    }
    return [p, c, f, kcal];
  }

  Widget _mealMacroChip(String text, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(text,
            style: TextStyle(
                fontSize: 10, color: color, fontWeight: FontWeight.w600)),
      );

  void _openVoiceInput(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => VoiceSessionSheet(mealType: mealType, date: date),
      fullscreenDialog: true,
    ));
  }

  static String _fmtGrams(double g) =>
      g == g.roundToDouble() ? g.round().toString() : g.toStringAsFixed(1);
}

class _EditEntrySheet extends StatefulWidget {
  final MealEntry entry;
  final void Function(double newGrams) onSave;
  final VoidCallback onDelete;

  const _EditEntrySheet({
    required this.entry,
    required this.onSave,
    required this.onDelete,
  });

  @override
  State<_EditEntrySheet> createState() => _EditEntrySheetState();
}

class _EditEntrySheetState extends State<_EditEntrySheet> {
  late final TextEditingController _ctrl;
  late double _newGrams;

  @override
  void initState() {
    super.initState();
    _newGrams = widget.entry.grams;
    _ctrl = TextEditingController(
        text: MealSection._fmtGrams(widget.entry.grams));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final entry = widget.entry;
    final ratio = _newGrams > 0 ? _newGrams / entry.grams : 1.0;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(entry.foodName,
              style:
                  const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 14),
          Row(
            children: [
              SizedBox(
                width: 100,
                child: TextField(
                  controller: _ctrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Grams',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  autofocus: true,
                  onChanged: (v) {
                    final g = double.tryParse(v);
                    if (g != null && g > 0) setState(() => _newGrams = g);
                  },
                ),
              ),
              const SizedBox(width: 16),
              _miniMacros(entry, ratio),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              TextButton.icon(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                label: const Text('Delete',
                    style: TextStyle(color: Colors.red)),
                onPressed: () {
                  Navigator.pop(context);
                  widget.onDelete();
                },
              ),
              const Spacer(),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: () {
                  Navigator.pop(context);
                  widget.onSave(_newGrams);
                },
                child: const Text('Save'),
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _miniMacros(MealEntry entry, double ratio) {
    return Row(
      children: [
        _macroCol('P', entry.protein * ratio, AppColors.protein),
        const SizedBox(width: 10),
        _macroCol('C', entry.carbs * ratio, AppColors.carbs),
        const SizedBox(width: 10),
        _macroCol('F', entry.fat * ratio, AppColors.fat),
        const SizedBox(width: 10),
        _macroCol('kcal', entry.calories * ratio, AppColors.calories,
            isCalories: true),
      ],
    );
  }

  Widget _macroCol(String label, double value, Color color,
      {bool isCalories = false}) {
    return Column(
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 9, color: color, fontWeight: FontWeight.w600)),
        Text(
            isCalories
                ? value.round().toString()
                : '${value.toStringAsFixed(1)}g',
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
