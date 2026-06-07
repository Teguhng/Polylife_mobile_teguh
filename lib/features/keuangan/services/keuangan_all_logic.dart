import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:mobile_ver/features/keuangan/models/keuangan_model.dart';

class KeuanganAllLogic {
  const KeuanganAllLogic();

  List<KeuanganTransaction> filterItems({
    required List<KeuanganTransaction> items,
    required String searchQuery,
    required String jenisFilter,
    required String monthFilter,
    required DateTimeRange? dateRangeFilter,
    required double? minNominalFilter,
    required double? maxNominalFilter,
    required Set<String> categoryFilters,
  }) {
    final normalizedQuery = searchQuery.trim().toLowerCase();

    return items.where((item) {
      if (jenisFilter != 'semua' && item.jenis != jenisFilter) {
        return false;
      }

      if (monthFilter != 'semua') {
        final monthKey = DateFormat('yyyy-MM').format(item.tanggal);
        if (monthKey != monthFilter) {
          return false;
        }
      }

      if (dateRangeFilter != null) {
        if (item.tanggal.isBefore(dateRangeFilter.start) ||
            item.tanggal.isAfter(
              dateRangeFilter.end.add(const Duration(days: 1)),
            )) {
          return false;
        }
      }

      if (minNominalFilter != null && item.nominal < minNominalFilter) {
        return false;
      }

      if (maxNominalFilter != null && item.nominal > maxNominalFilter) {
        return false;
      }

      if (categoryFilters.isNotEmpty &&
          !categoryFilters.contains(item.kategori)) {
        return false;
      }

      if (normalizedQuery.isNotEmpty) {
        final haystack =
            '${item.kategori} ${item.deskripsi ?? ''} ${item.jenis}'
                .toLowerCase();
        if (!haystack.contains(normalizedQuery)) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  List<double> buildTrendSeries({
    required List<KeuanganTransaction> source,
    required String trendRange,
    required String monthFilter,
    required String currentMonthKey,
  }) {
    final now = DateTime.now();

    if (trendRange == 'month') {
      final month = monthFilter != 'semua' ? monthFilter : currentMonthKey;
      final parts = month.split('-');
      if (parts.length != 2) {
        return const <double>[];
      }

      final year = int.tryParse(parts[0]);
      final monthInt = int.tryParse(parts[1]);
      if (year == null || monthInt == null) {
        return const <double>[];
      }

      final start = DateTime(year, monthInt, 1);
      final end = DateTime(year, monthInt + 1, 0);
      return _dailyExpenseSeries(source: source, start: start, end: end);
    }

    final days = trendRange == '7d' ? 7 : 30;
    final start = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: days - 1));
    final end = DateTime(now.year, now.month, now.day);
    return _dailyExpenseSeries(source: source, start: start, end: end);
  }

  List<String> availableCategories(List<KeuanganTransaction> items) {
    final categories = items.map((item) => item.kategori).toSet().toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return categories;
  }

  List<String> availableMonths(List<KeuanganTransaction> items) {
    final months =
        items
            .map((item) => DateFormat('yyyy-MM').format(item.tanggal))
            .toSet()
            .toList()
          ..sort((a, b) => b.compareTo(a));
    return months;
  }

  String monthFilterLabel(String monthKey) {
    if (monthKey == 'semua') {
      return 'Semua Bulan';
    }

    try {
      final dt = DateTime.parse('$monthKey-01');
      final label = DateFormat('MMM yyyy', 'id_ID').format(dt);
      return label[0].toUpperCase() + label.substring(1);
    } catch (_) {
      return monthKey;
    }
  }

  String resolvedBudgetMonth({
    required String budgetMonth,
    required String monthFilter,
    required List<KeuanganTransaction> items,
    required String currentMonthKey,
  }) {
    if (budgetMonth.trim().isNotEmpty) {
      return budgetMonth;
    }

    if (monthFilter != 'semua') {
      return monthFilter;
    }

    final months = availableMonths(items);
    return months.isNotEmpty ? months.first : currentMonthKey;
  }

  Map<String, double> expenseByCategory({
    required List<KeuanganTransaction> items,
    required String monthKey,
  }) {
    final output = <String, double>{};

    for (final row in items) {
      if (row.jenis != 'pengeluaran') {
        continue;
      }

      if (DateFormat('yyyy-MM').format(row.tanggal) != monthKey) {
        continue;
      }

      output[row.kategori] = (output[row.kategori] ?? 0) + row.nominal;
    }

    return output;
  }

  String budgetKey(String month, String category) {
    return '$month|${category.toLowerCase().trim()}';
  }

  int advancedFilterCount({
    required DateTimeRange? dateRangeFilter,
    required double? minNominalFilter,
    required double? maxNominalFilter,
    required Set<String> categoryFilters,
  }) {
    var count = 0;
    if (dateRangeFilter != null) {
      count++;
    }
    if (minNominalFilter != null) {
      count++;
    }
    if (maxNominalFilter != null) {
      count++;
    }
    if (categoryFilters.isNotEmpty) {
      count++;
    }
    return count;
  }

  DateTime advanceRecurringDate({
    required DateTime base,
    required String frequency,
  }) {
    if (frequency == 'daily') {
      return base.add(const Duration(days: 1));
    }
    if (frequency == 'weekly') {
      return base.add(const Duration(days: 7));
    }

    // Prevent month overflow drift (e.g. Jan 31 -> Mar 3).
    final nextMonthDate = DateTime(base.year, base.month + 1, 1);
    final lastDayOfCurrentMonth = DateUtils.getDaysInMonth(
      base.year,
      base.month,
    );
    final lastDayOfNextMonth = DateUtils.getDaysInMonth(
      nextMonthDate.year,
      nextMonthDate.month,
    );
    final isEndOfMonth = base.day == lastDayOfCurrentMonth;

    final targetDay = isEndOfMonth
        ? lastDayOfNextMonth
        : base.day.clamp(1, lastDayOfNextMonth).toInt();
    return DateTime(
      nextMonthDate.year,
      nextMonthDate.month,
      targetDay,
      base.hour,
      base.minute,
      base.second,
      base.millisecond,
      base.microsecond,
    );
  }

  List<double> _dailyExpenseSeries({
    required List<KeuanganTransaction> source,
    required DateTime start,
    required DateTime end,
  }) {
    final values = <double>[];

    var cursor = DateTime(start.year, start.month, start.day);
    final endDay = DateTime(end.year, end.month, end.day);

    while (!cursor.isAfter(endDay)) {
      final dayTotal = source
          .where(
            (item) =>
                item.jenis == 'pengeluaran' &&
                item.tanggal.year == cursor.year &&
                item.tanggal.month == cursor.month &&
                item.tanggal.day == cursor.day,
          )
          .fold<double>(0, (sum, item) => sum + item.nominal);
      values.add(dayTotal);
      cursor = cursor.add(const Duration(days: 1));
    }

    return values;
  }
}
