import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants.dart';
import '../../../../presentation/providers/providers.dart';

class WeekStripView extends ConsumerWidget {
  final DateTime focusedDay;
  final void Function(DateTime) onDayTap;

  const WeekStripView({
    super.key,
    required this.focusedDay,
    required this.onDayTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final month = DateFormat('yyyy-MM').format(focusedDay);
    final caloriesAsync = ref.watch(monthlyCaloriesProvider(month));
    final goals = ref.watch(goalsProvider).valueOrNull;
    final calTarget = goals?.caloriesKcal ?? 2200;

    // Build 7 days centered on focusedDay's week (Mon–Sun)
    final weekStart = focusedDay.subtract(
        Duration(days: focusedDay.weekday - 1));
    final days = List.generate(7, (i) => weekStart.add(Duration(days: i)));
    final today = DateTime.now();

    return caloriesAsync.when(
      loading: () => const SizedBox(height: 80),
      error: (_, __) => const SizedBox(height: 80),
      data: (calMap) => SizedBox(
        height: 80,
        child: Row(
          children: days.map((day) {
            final key = DateFormat('yyyy-MM-dd').format(day);
            final cal = calMap[key];
            final isToday = DateFormat('yyyy-MM-dd').format(today) == key;
            final color = _dayColor(cal, calTarget);

            return Expanded(
              child: GestureDetector(
                onTap: () => onDayTap(day),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color: isToday
                        ? Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: 0.08)
                        : null,
                    borderRadius: BorderRadius.circular(8),
                    border: isToday
                        ? Border.all(
                            color: Theme.of(context).colorScheme.primary,
                            width: 1.5)
                        : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        DateFormat('E').format(day).substring(0, 1),
                        style: const TextStyle(
                            fontSize: 10, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        day.day.toString(),
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: isToday
                                ? FontWeight.bold
                                : FontWeight.normal),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      if (cal != null)
                        Text(
                          '${cal.round()}',
                          style: const TextStyle(fontSize: 8),
                        ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  static Color _dayColor(double? cal, double target) {
    if (cal == null) return AppColors.goalNone;
    final pct = cal / target;
    if (pct >= 1.15) return AppColors.goalOver;
    if (pct >= 0.90) return AppColors.goalHit;
    if (pct >= 0.50) return AppColors.goalPartial;
    return AppColors.goalLow;
  }
}
