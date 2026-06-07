import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_ver/features/jadwal/models/jadwal_item.dart';
import 'package:mobile_ver/features/jadwal/services/jadwal_scheduler_service.dart';

void main() {
  group('JadwalSchedulerService', () {
    const service = JadwalSchedulerService();

    JadwalItem item({
      required int id,
      required String title,
      required JadwalType type,
      required DateTime startAt,
      required DateTime endAt,
      bool completed = false,
    }) {
      return JadwalItem(
        id: id,
        title: title,
        type: type,
        startAt: startAt,
        endAt: endAt,
        location: '',
        notes: '',
        completed: completed,
      );
    }

    test('builds a 42-day Monday based month grid', () {
      final grid = service.buildMonthGrid(DateTime(2026, 5, 13));

      expect(grid, hasLength(42));
      expect(grid.first.weekday, DateTime.monday);
      expect(grid.first, DateTime(2026, 4, 27));
      expect(grid.last, DateTime(2026, 6, 7));
    });

    test('filters weekend lecture items but keeps personal items', () {
      final saturday = DateTime(2026, 5, 16);
      final rows = service.itemsForDate(
        date: saturday,
        allItems: [
          item(
            id: 1,
            title: 'Kuliah Sabtu',
            type: JadwalType.kuliah,
            startAt: DateTime(2026, 5, 16, 9),
            endAt: DateTime(2026, 5, 16, 10),
          ),
          item(
            id: 2,
            title: 'Kegiatan personal',
            type: JadwalType.personal,
            startAt: DateTime(2026, 5, 16, 8),
            endAt: DateTime(2026, 5, 16, 9),
          ),
        ],
      );

      expect(rows.map((row) => row.title), ['Kegiatan personal']);
    });

    test('detects schedule conflicts and supports ignoring an item id', () {
      final existing = item(
        id: 1,
        title: 'Rapat',
        type: JadwalType.rapat,
        startAt: DateTime(2026, 5, 13, 10),
        endAt: DateTime(2026, 5, 13, 11),
      );
      final candidate = item(
        id: 2,
        title: 'Ujian',
        type: JadwalType.ujian,
        startAt: DateTime(2026, 5, 13, 10, 30),
        endAt: DateTime(2026, 5, 13, 12),
      );

      expect(
        service.hasConflict(allItems: [existing], candidate: candidate),
        isTrue,
      );
      expect(
        service.hasConflict(
          allItems: [existing],
          candidate: existing,
          ignoreId: existing.id,
        ),
        isFalse,
      );
    });
  });
}
