import 'package:mobile_ver/features/jadwal/models/jadwal_item.dart';

class JadwalDayStats {
  final int total;
  final int completed;
  final int upcoming;

  const JadwalDayStats({
    required this.total,
    required this.completed,
    required this.upcoming,
  });
}

class JadwalSchedulerService {
  const JadwalSchedulerService();

  DateTime normalizeDate(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }

  bool isWeekendDate(DateTime value) {
    final normalized = normalizeDate(value);
    return normalized.weekday == DateTime.saturday ||
        normalized.weekday == DateTime.sunday;
  }

  List<DateTime> buildMonthGrid(DateTime monthAnchor) {
    final firstDay = DateTime(monthAnchor.year, monthAnchor.month, 1);
    // Monday-based grid: Monday=1 ... Sunday=7
    final leadingDays = firstDay.weekday - DateTime.monday;
    final gridStart = firstDay.subtract(Duration(days: leadingDays));

    final output = <DateTime>[];
    for (var i = 0; i < 42; i++) {
      output.add(gridStart.add(Duration(days: i)));
    }
    return output;
  }

  List<JadwalItem> itemsForDate({
    required List<JadwalItem> allItems,
    required DateTime date,
  }) {
    final dayStart = normalizeDate(date);
    final dayEnd = dayStart.add(const Duration(days: 1));
    final isWeekend = isWeekendDate(dayStart);

    final rows =
        allItems
            .where(
              (item) =>
                  item.startAt.isBefore(dayEnd) && item.endAt.isAfter(dayStart),
            )
            .where((item) => !isWeekend || item.type != JadwalType.kuliah)
            .toList()
          ..sort((a, b) {
            final byStart = a.startAt.compareTo(b.startAt);
            if (byStart != 0) return byStart;
            return a.id.compareTo(b.id);
          });
    return rows;
  }

  JadwalType? dominantTypeForDate({
    required List<JadwalItem> allItems,
    required DateTime date,
  }) {
    final rows = itemsForDate(allItems: allItems, date: date);
    if (rows.isEmpty) {
      return null;
    }

    // Priority for visual marker.
    if (rows.any((item) => item.type == JadwalType.personal)) {
      return JadwalType.personal;
    }
    if (rows.any((item) => item.type == JadwalType.ujian)) {
      return JadwalType.ujian;
    }
    if (rows.any((item) => item.type == JadwalType.kuliah)) {
      return JadwalType.kuliah;
    }
    return rows.first.type;
  }

  bool hasConflict({
    required List<JadwalItem> allItems,
    required JadwalItem candidate,
    int? ignoreId,
  }) {
    for (final item in allItems) {
      if (ignoreId != null && item.id == ignoreId) {
        continue;
      }

      final overlaps =
          candidate.startAt.isBefore(item.endAt) &&
          candidate.endAt.isAfter(item.startAt);
      if (overlaps) {
        return true;
      }
    }
    return false;
  }

  JadwalDayStats buildDayStats(List<JadwalItem> dayItems) {
    final now = DateTime.now();
    final completed = dayItems.where((item) => item.completed).length;
    final upcoming = dayItems
        .where((item) => !item.completed && item.endAt.isAfter(now))
        .length;

    return JadwalDayStats(
      total: dayItems.length,
      completed: completed,
      upcoming: upcoming,
    );
  }

  int countForDate({
    required List<JadwalItem> allItems,
    required DateTime date,
  }) {
    return itemsForDate(allItems: allItems, date: date).length;
  }
}
