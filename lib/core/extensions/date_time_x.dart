import 'package:intl/intl.dart';

extension DateTimeX on DateTime {
  bool get isToday {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }

  bool isSameDay(DateTime? other) {
    if (other == null) return false;
    return year == other.year && month == other.month && day == other.day;
  }

  String get dateKey => DateFormat('yyyy-MM-dd').format(this);

  String get monthKey => DateFormat('yyyy-MM').format(this);
}
