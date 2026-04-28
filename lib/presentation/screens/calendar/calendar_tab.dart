import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../core/constants.dart';
import '../../../presentation/providers/providers.dart';
import 'widgets/day_detail_sheet.dart';
import 'widgets/week_strip_view.dart';

enum _CalView { week, month }

class CalendarTab extends ConsumerStatefulWidget {
  const CalendarTab({super.key});

  @override
  ConsumerState<CalendarTab> createState() => _CalendarTabState();
}

class _CalendarTabState extends ConsumerState<CalendarTab> {
  _CalView _view = _CalView.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  Widget build(BuildContext context) {
    final month = DateFormat('yyyy-MM').format(_focusedDay);
    final caloriesAsync = ref.watch(monthlyCaloriesProvider(month));
    final goals = ref.watch(goalsProvider).valueOrNull;
    final calTarget = goals?.caloriesKcal ?? 2200;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendar'),
        actions: [
          SegmentedButton<_CalView>(
            segments: const [
              ButtonSegment(value: _CalView.week, label: Text('Week')),
              ButtonSegment(value: _CalView.month, label: Text('Month')),
            ],
            selected: {_view},
            onSelectionChanged: (s) =>
                setState(() => _view = s.first),
            style: const ButtonStyle(
                visualDensity: VisualDensity.compact),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          if (_view == _CalView.week) ...[
            _WeekNav(
              focusedDay: _focusedDay,
              onPrev: () => setState(() => _focusedDay =
                  _focusedDay.subtract(const Duration(days: 7))),
              onNext: () =>
                  setState(() => _focusedDay = _focusedDay.add(const Duration(days: 7))),
            ),
            WeekStripView(
              focusedDay: _focusedDay,
              onDayTap: _showDetail,
            ),
          ] else ...[
            caloriesAsync.when(
              loading: () => const LinearProgressIndicator(),
              error: (_, __) => const SizedBox.shrink(),
              data: (calMap) => TableCalendar(
                firstDay: DateTime.utc(2020, 1, 1),
                lastDay: DateTime.now().add(const Duration(days: 1)),
                focusedDay: _focusedDay,
                selectedDayPredicate: (d) =>
                    isSameDay(d, _selectedDay),
                onDaySelected: (selected, focused) {
                  setState(() {
                    _selectedDay = selected;
                    _focusedDay = focused;
                  });
                  _showDetail(selected);
                },
                onPageChanged: (focused) =>
                    setState(() => _focusedDay = focused),
                calendarStyle: const CalendarStyle(
                  todayDecoration: BoxDecoration(
                    color: Color(0x3343A047),
                    shape: BoxShape.circle,
                  ),
                  selectedDecoration: BoxDecoration(
                    color: Color(0xFF43A047),
                    shape: BoxShape.circle,
                  ),
                ),
                calendarBuilders: CalendarBuilders(
                  markerBuilder: (ctx, day, _) {
                    final key = DateFormat('yyyy-MM-dd').format(day);
                    final cal = calMap[key];
                    if (cal == null) return null;
                    final color = _dayColor(cal, calTarget);
                    return Positioned(
                      bottom: 4,
                      child: Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                            color: color, shape: BoxShape.circle),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
          const Divider(height: 1),
          Expanded(
            child: _selectedDay != null
                ? _DayPreview(day: _selectedDay!)
                : Center(
                    child: Text(
                      'Tap a day to see details',
                      style: TextStyle(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.5)),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  void _showDetail(DateTime day) {
    setState(() => _selectedDay = day);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => DayDetailSheet(day: day),
    );
  }

  static Color _dayColor(double cal, double target) {
    final pct = cal / target;
    if (pct >= 1.15) return AppColors.goalOver;
    if (pct >= 0.90) return AppColors.goalHit;
    if (pct >= 0.50) return AppColors.goalPartial;
    return AppColors.goalLow;
  }
}

class _DayPreview extends ConsumerWidget {
  final DateTime day;
  const _DayPreview({required this.day});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final key = DateFormat('yyyy-MM-dd').format(day);
    final logAsync = ref.watch(logProvider(key));
    final goals = ref.watch(goalsProvider).valueOrNull;

    return logAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (log) {
        if (!log.hasAnyEntry) {
          return Center(
            child: Text(
              'No entries for ${DateFormat('MMM d').format(day)}',
              style: TextStyle(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.5)),
            ),
          );
        }
        final t = log.totals;
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(DateFormat('EEEE, MMMM d').format(day),
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 15)),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _MacroStat('Protein', t.protein, goals?.proteinG,
                      AppColors.protein),
                  _MacroStat(
                      'Carbs', t.carbs, goals?.carbsG, AppColors.carbs),
                  _MacroStat('Fat', t.fat, goals?.fatG, AppColors.fat),
                  _MacroStat('kcal', t.calories, goals?.caloriesKcal,
                      AppColors.calories,
                      isCalories: true),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MacroStat extends StatelessWidget {
  final String label;
  final double value;
  final double? target;
  final Color color;
  final bool isCalories;

  const _MacroStat(this.label, this.value, this.target, this.color,
      {this.isCalories = false});

  @override
  Widget build(BuildContext context) {
    final valueStr = isCalories
        ? value.round().toString()
        : '${value.toStringAsFixed(1)}g';
    final targetStr = target != null
        ? isCalories
            ? '/${target!.round()}'
            : '/${target!.toStringAsFixed(0)}g'
        : '';

    return Column(
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 11, color: color, fontWeight: FontWeight.w600)),
        const SizedBox(height: 2),
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                  text: valueStr,
                  style: TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14,
                      color: Theme.of(context).colorScheme.onSurface)),
              TextSpan(
                  text: targetStr,
                  style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade600)),
            ],
          ),
        ),
      ],
    );
  }
}

class _WeekNav extends StatelessWidget {
  final DateTime focusedDay;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  const _WeekNav(
      {required this.focusedDay,
      required this.onPrev,
      required this.onNext});

  @override
  Widget build(BuildContext context) {
    final weekStart =
        focusedDay.subtract(Duration(days: focusedDay.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 6));
    final label =
        '${DateFormat('MMM d').format(weekStart)} – ${DateFormat('MMM d').format(weekEnd)}';

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(icon: const Icon(Icons.chevron_left), onPressed: onPrev),
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        IconButton(icon: const Icon(Icons.chevron_right), onPressed: onNext),
      ],
    );
  }
}
