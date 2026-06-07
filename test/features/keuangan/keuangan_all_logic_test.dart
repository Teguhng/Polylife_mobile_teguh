import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_ver/features/keuangan/models/keuangan_model.dart';
import 'package:mobile_ver/features/keuangan/services/keuangan_all_logic.dart';

void main() {
  group('KeuanganAllLogic', () {
    const logic = KeuanganAllLogic();

    KeuanganTransaction trx({
      required int id,
      required String jenis,
      required String kategori,
      required double nominal,
      required DateTime tanggal,
      String? deskripsi,
    }) {
      return KeuanganTransaction(
        id: id,
        jenis: jenis,
        kategori: kategori,
        deskripsi: deskripsi,
        nominal: nominal,
        tanggal: tanggal,
      );
    }

    final items = [
      trx(
        id: 1,
        jenis: 'pengeluaran',
        kategori: 'Makan',
        nominal: 25000,
        tanggal: DateTime(2026, 5, 1),
        deskripsi: 'Sarapan',
      ),
      trx(
        id: 2,
        jenis: 'pengeluaran',
        kategori: 'Transport',
        nominal: 10000,
        tanggal: DateTime(2026, 5, 2),
        deskripsi: 'Bus kampus',
      ),
      trx(
        id: 3,
        jenis: 'pemasukan',
        kategori: 'Gaji',
        nominal: 500000,
        tanggal: DateTime(2026, 4, 30),
        deskripsi: 'Part time',
      ),
    ];

    test('filters by type, month, query, category, date range, and amount', () {
      final filtered = logic.filterItems(
        items: items,
        searchQuery: 'bus',
        jenisFilter: 'pengeluaran',
        monthFilter: '2026-05',
        dateRangeFilter: DateTimeRange(
          start: DateTime(2026, 5, 2),
          end: DateTime(2026, 5, 2),
        ),
        minNominalFilter: 5000,
        maxNominalFilter: 15000,
        categoryFilters: {'Transport'},
      );

      expect(filtered.map((item) => item.id), [2]);
    });

    test('returns sorted categories and months', () {
      expect(logic.availableCategories(items), ['Gaji', 'Makan', 'Transport']);
      expect(logic.availableMonths(items), ['2026-05', '2026-04']);
    });

    test('aggregates monthly expenses by category', () {
      final totals = logic.expenseByCategory(items: items, monthKey: '2026-05');

      expect(totals, {'Makan': 25000, 'Transport': 10000});
    });

    test('builds month trend series with daily expense totals', () {
      final series = logic.buildTrendSeries(
        source: items,
        trendRange: 'month',
        monthFilter: '2026-05',
        currentMonthKey: '2026-05',
      );

      expect(series, hasLength(31));
      expect(series[0], 25000);
      expect(series[1], 10000);
      expect(series.skip(2).every((value) => value == 0), isTrue);
    });

    test(
      'resolves budget month with explicit, filtered, latest, and fallback values',
      () {
        expect(
          logic.resolvedBudgetMonth(
            budgetMonth: '2026-03',
            monthFilter: 'semua',
            items: items,
            currentMonthKey: '2026-05',
          ),
          '2026-03',
        );
        expect(
          logic.resolvedBudgetMonth(
            budgetMonth: '',
            monthFilter: '2026-04',
            items: items,
            currentMonthKey: '2026-05',
          ),
          '2026-04',
        );
        expect(
          logic.resolvedBudgetMonth(
            budgetMonth: '',
            monthFilter: 'semua',
            items: items,
            currentMonthKey: '2026-05',
          ),
          '2026-05',
        );
        expect(
          logic.resolvedBudgetMonth(
            budgetMonth: '',
            monthFilter: 'semua',
            items: const [],
            currentMonthKey: '2026-05',
          ),
          '2026-05',
        );
      },
    );

    test('counts advanced filters and normalizes budget keys', () {
      expect(
        logic.advancedFilterCount(
          dateRangeFilter: DateTimeRange(
            start: DateTime(2026, 5, 1),
            end: DateTime(2026, 5, 31),
          ),
          minNominalFilter: 10000,
          maxNominalFilter: null,
          categoryFilters: {'Makan', 'Transport'},
        ),
        3,
      );
      expect(logic.budgetKey('2026-05', '  Makan  '), '2026-05|makan');
    });

    test('advances recurring dates without monthly overflow drift', () {
      expect(
        logic.advanceRecurringDate(
          base: DateTime(2026, 5, 13, 8),
          frequency: 'daily',
        ),
        DateTime(2026, 5, 14, 8),
      );
      expect(
        logic.advanceRecurringDate(
          base: DateTime(2026, 5, 13, 8),
          frequency: 'weekly',
        ),
        DateTime(2026, 5, 20, 8),
      );
      expect(
        logic.advanceRecurringDate(
          base: DateTime(2026, 1, 31, 8),
          frequency: 'monthly',
        ),
        DateTime(2026, 2, 28, 8),
      );
      expect(
        logic.advanceRecurringDate(
          base: DateTime(2026, 1, 30, 8),
          frequency: 'monthly',
        ),
        DateTime(2026, 2, 28, 8),
      );
    });
  });
}
