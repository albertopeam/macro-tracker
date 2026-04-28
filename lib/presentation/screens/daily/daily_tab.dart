import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../../data/models/daily_log.dart';
import '../../../data/models/meal_entry.dart';
import '../../../presentation/providers/providers.dart';
import 'widgets/daily_summary_bar.dart';
import 'widgets/meal_section.dart';

class DailyTab extends ConsumerStatefulWidget {
  const DailyTab({super.key});

  @override
  ConsumerState<DailyTab> createState() => _DailyTabState();
}

class _DailyTabState extends ConsumerState<DailyTab> {
  DateTime _date = DateTime.now();

  String get _dateKey => DateFormat('yyyy-MM-dd').format(_date);
  bool get _isToday =>
      DateFormat('yyyy-MM-dd').format(DateTime.now()) == _dateKey;

  void _prevDay() => setState(() => _date = _date.subtract(const Duration(days: 1)));
  void _nextDay() {
    final tomorrow = _date.add(const Duration(days: 1));
    if (!tomorrow.isAfter(DateTime.now())) {
      setState(() => _date = tomorrow);
    }
  }

  void _goToday() => setState(() => _date = DateTime.now());

  @override
  Widget build(BuildContext context) {
    final logAsync = ref.watch(logProvider(_dateKey));
    final goalsAsync = ref.watch(goalsProvider);

    return Scaffold(
      appBar: AppBar(
        title: _DateNav(
          date: _date,
          isToday: _isToday,
          onPrev: _prevDay,
          onNext: _isToday ? null : _nextDay,
          onTodayTap: _isToday ? null : _goToday,
        ),
        automaticallyImplyLeading: false,
      ),
      body: goalsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (goals) => logAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (log) => _buildBody(log, goals),
        ),
      ),
    );
  }

  Widget _buildBody(DailyLog log, goals) {
    final fixedMeals = [MealType.breakfast, MealType.lunch, MealType.dinner];
    final hasSnack = log.entriesForMeal(MealType.snack).isNotEmpty ||
        _showSnack;

    return Column(
      children: [
        DailySummaryBar(totals: log.totals, goals: goals),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.only(bottom: 100),
            children: [
              ...fixedMeals.map((type) {
                final entries = log.entriesForMeal(type);
                return MealSection(
                  mealType: type,
                  date: _dateKey,
                  entries: entries,
                  onCopy: entries.isNotEmpty
                      ? () => _showCopySheet(context, type, entries)
                      : null,
                );
              }),
              if (hasSnack)
                MealSection(
                  mealType: MealType.snack,
                  date: _dateKey,
                  entries: log.entriesForMeal(MealType.snack),
                  onRemove: () => _removeExtraSection(
                      log.entriesForMeal(MealType.snack)),
                  onCopy: log.entriesForMeal(MealType.snack).isNotEmpty
                      ? () => _showCopySheet(context, MealType.snack,
                          log.entriesForMeal(MealType.snack))
                      : null,
                ),
              if (!hasSnack)
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add extra meal'),
                    onPressed: () => setState(() => _showSnack = true),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  bool _showSnack = false;

  Future<void> _removeExtraSection(List<MealEntry> snackEntries) async {
    if (snackEntries.isEmpty) {
      setState(() => _showSnack = false);
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Extra?'),
        content: Text(
            'This will delete ${snackEntries.length} '
            'entr${snackEntries.length == 1 ? 'y' : 'ies'}.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Remove',
                  style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await ref.read(logProvider(_dateKey).notifier).deleteEntries(
          snackEntries.map((e) => e.id).toList(),
        );
    setState(() => _showSnack = false);
  }

  Future<void> _showCopySheet(
    BuildContext context,
    MealType mealType,
    List<MealEntry> sourceEntries,
  ) async {
    final targetDate = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _CopyMealSheet(mealType: mealType, isToday: _isToday),
    );
    if (targetDate == null || !mounted) return;

    final now = DateTime.now();
    final newEntries = sourceEntries
        .map((e) => MealEntry(
              id: const Uuid().v4(),
              date: targetDate,
              mealType: e.mealType,
              foodId: e.foodId,
              foodName: e.foodName,
              grams: e.grams,
              protein: e.protein,
              carbs: e.carbs,
              fat: e.fat,
              calories: e.calories,
              createdAt: now,
            ))
        .toList();

    await ref.read(logProvider(targetDate).notifier).addEntries(newEntries);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
            '${mealType.displayName} copied to ${_fmtDateLabel(targetDate)}'),
        duration: const Duration(seconds: 3),
      ));
    }
  }

  String _fmtDateLabel(String dateKey) {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final tomorrow = DateFormat('yyyy-MM-dd').format(
      DateTime.now().add(const Duration(days: 1)),
    );
    if (dateKey == today) return 'Today';
    if (dateKey == tomorrow) return 'Tomorrow';
    return DateFormat('EEE, MMM d').format(DateTime.parse(dateKey));
  }
}

class _DateNav extends StatelessWidget {
  final DateTime date;
  final bool isToday;
  final VoidCallback onPrev;
  final VoidCallback? onNext;
  final VoidCallback? onTodayTap;

  const _DateNav({
    required this.date,
    required this.isToday,
    required this.onPrev,
    this.onNext,
    this.onTodayTap,
  });

  @override
  Widget build(BuildContext context) {
    final label = isToday
        ? 'Today'
        : DateFormat('EEE, MMM d').format(date);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: onPrev,
          tooltip: 'Previous day',
        ),
        GestureDetector(
          onTap: onTodayTap,
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed: onNext,
          tooltip: 'Next day',
        ),
      ],
    );
  }
}

class _CopyMealSheet extends StatelessWidget {
  final MealType mealType;
  final bool isToday;

  const _CopyMealSheet({required this.mealType, required this.isToday});

  String _fmt(DateTime d) => DateFormat('yyyy-MM-dd').format(d);

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final tomorrow = today.add(const Duration(days: 1));

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Text(
              'Copy ${mealType.displayName} to…',
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
          ),
          const Divider(height: 1),
          if (!isToday)
            ListTile(
              leading: const Icon(Icons.today),
              title: Text('Today · ${DateFormat('EEE, MMM d').format(today)}'),
              onTap: () => Navigator.pop(context, _fmt(today)),
            ),
          ListTile(
            leading: const Icon(Icons.arrow_forward),
            title: Text('Tomorrow · ${DateFormat('EEE, MMM d').format(tomorrow)}'),
            onTap: () => Navigator.pop(context, _fmt(tomorrow)),
          ),
          ListTile(
            leading: const Icon(Icons.calendar_today_outlined),
            title: const Text('Choose another day…'),
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: today,
                firstDate: DateTime(2020),
                lastDate: today.add(const Duration(days: 365)),
              );
              if (picked != null && context.mounted) {
                Navigator.pop(context, _fmt(picked));
              }
            },
          ),
        ],
      ),
    );
  }
}
