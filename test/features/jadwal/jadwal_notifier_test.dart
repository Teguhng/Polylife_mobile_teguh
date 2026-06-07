import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_ver/features/jadwal/models/jadwal_item.dart';
import 'package:mobile_ver/features/jadwal/providers/jadwal_provider.dart';
import 'package:mobile_ver/features/jadwal/repositories/jadwal_repository.dart';

void main() {
  group('JadwalNotifier', () {
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

    test('loads rows and recomputes selected day items', () async {
      final repository = _FakeJadwalRepository([
        item(
          id: 1,
          title: 'Kuliah',
          type: JadwalType.kuliah,
          startAt: DateTime(2026, 5, 13, 8),
          endAt: DateTime(2026, 5, 13, 10),
        ),
        item(
          id: 2,
          title: 'Besok',
          type: JadwalType.personal,
          startAt: DateTime(2026, 5, 14, 8),
          endAt: DateTime(2026, 5, 14, 9),
        ),
      ]);
      final notifier = JadwalNotifier(repository: repository);

      await _flushAsync();
      notifier.selectDate(DateTime(2026, 5, 13, 20, 30));

      expect(notifier.state.isLoading, isFalse);
      expect(notifier.state.selectedDate, DateTime(2026, 5, 13));
      expect(notifier.state.dayItems.map((row) => row.title), ['Kuliah']);
      expect(notifier.state.dayStats.total, 1);
    });

    test('creates trimmed agenda and updates derived day state', () async {
      final repository = _FakeJadwalRepository();
      final notifier = JadwalNotifier(repository: repository);

      await _flushAsync();
      notifier.selectDate(DateTime(2026, 5, 13));

      final result = await notifier.createFromInput(
        JadwalInput(
          title: '  Rapat Proyek  ',
          type: JadwalType.rapat,
          startAt: DateTime(2026, 5, 13, 13),
          endAt: DateTime(2026, 5, 13, 14),
          location: '  Lab  ',
          notes: '  Bahas UI  ',
          completed: false,
        ),
      );

      expect(result.success, isTrue);
      expect(notifier.state.allItems.single.title, 'Rapat Proyek');
      expect(notifier.state.allItems.single.location, 'Lab');
      expect(notifier.state.dayItems.single.notes, 'Bahas UI');
    });

    test('rejects create and update when agenda conflicts', () async {
      final existing = item(
        id: 1,
        title: 'Agenda utama',
        type: JadwalType.rapat,
        startAt: DateTime(2026, 5, 13, 9),
        endAt: DateTime(2026, 5, 13, 10),
      );
      final repository = _FakeJadwalRepository([existing]);
      final notifier = JadwalNotifier(repository: repository);

      await _flushAsync();

      final createResult = await notifier.createFromInput(
        JadwalInput(
          title: 'Bentrok',
          type: JadwalType.ujian,
          startAt: DateTime(2026, 5, 13, 9, 30),
          endAt: DateTime(2026, 5, 13, 11),
          location: '',
          notes: '',
          completed: false,
        ),
      );

      expect(createResult.success, isFalse);
      expect(
        createResult.message,
        'Jadwal bentrok dengan agenda lain di jam yang sama.',
      );
      expect(repository.createCount, 0);

      final updateResult = await notifier.updateFromInput(
        id: 2,
        input: JadwalInput(
          title: 'Bentrok update',
          type: JadwalType.personal,
          startAt: DateTime(2026, 5, 13, 9, 30),
          endAt: DateTime(2026, 5, 13, 10, 30),
          location: '',
          notes: '',
          completed: false,
        ),
      );

      expect(updateResult.success, isFalse);
      expect(
        updateResult.message,
        'Perubahan jadwal bentrok dengan agenda lain.',
      );
      expect(repository.updateCount, 0);
    });

    test('updates, toggles completion, and deletes agenda', () async {
      final existing = item(
        id: 1,
        title: 'Agenda',
        type: JadwalType.personal,
        startAt: DateTime(2026, 5, 13, 8),
        endAt: DateTime(2026, 5, 13, 9),
      );
      final repository = _FakeJadwalRepository([existing]);
      final notifier = JadwalNotifier(repository: repository);

      await _flushAsync();
      notifier.selectDate(DateTime(2026, 5, 13));

      final updateResult = await notifier.updateFromInput(
        id: 1,
        input: JadwalInput(
          title: 'Agenda baru',
          type: JadwalType.personal,
          startAt: DateTime(2026, 5, 13, 10),
          endAt: DateTime(2026, 5, 13, 11),
          location: 'Rumah',
          notes: 'Catatan',
          completed: false,
        ),
      );

      expect(updateResult.success, isTrue);
      expect(notifier.state.allItems.single.title, 'Agenda baru');
      expect(notifier.state.dayItems.single.startAt.hour, 10);

      await notifier.toggleCompleted(notifier.state.allItems.single);
      expect(notifier.state.allItems.single.completed, isTrue);
      expect(notifier.state.dayStats.completed, 1);

      await notifier.delete(1);
      expect(notifier.state.allItems, isEmpty);
      expect(notifier.state.dayItems, isEmpty);
    });

    test('surfaces repository errors while keeping current state', () async {
      final existing = item(
        id: 1,
        title: 'Agenda',
        type: JadwalType.personal,
        startAt: DateTime(2026, 5, 13, 8),
        endAt: DateTime(2026, 5, 13, 9),
      );
      final repository = _FakeJadwalRepository([existing])..failDeletes = true;
      final notifier = JadwalNotifier(repository: repository);

      await _flushAsync();
      await notifier.delete(1);

      expect(notifier.state.allItems.single.id, 1);
      expect(notifier.state.errorMessage, 'Gagal menghapus jadwal.');
    });
  });
}

class _FakeJadwalRepository implements JadwalRepository {
  _FakeJadwalRepository([List<JadwalItem>? seed])
    : _items = List.of(seed ?? []);

  final List<JadwalItem> _items;
  int createCount = 0;
  int updateCount = 0;
  bool failDeletes = false;

  @override
  Future<List<JadwalItem>> fetchAll() async {
    return List<JadwalItem>.of(_items)..sort((a, b) {
      final byDate = a.startAt.compareTo(b.startAt);
      if (byDate != 0) return byDate;
      return a.id.compareTo(b.id);
    });
  }

  @override
  Future<JadwalItem> create(JadwalItem item) async {
    createCount++;
    final nextId = _items.isEmpty
        ? 1
        : _items.map((row) => row.id).reduce((a, b) => a > b ? a : b) + 1;
    final created = item.copyWith(id: nextId);
    _items.add(created);
    return created;
  }

  @override
  Future<JadwalItem> update(JadwalItem item) async {
    updateCount++;
    final index = _items.indexWhere((row) => row.id == item.id);
    if (index != -1) {
      _items[index] = item;
    }
    return item;
  }

  @override
  Future<void> delete(int id) async {
    if (failDeletes) {
      throw StateError('failed delete');
    }
    _items.removeWhere((row) => row.id == id);
  }
}

Future<void> _flushAsync() async {
  await Future<void>.delayed(Duration.zero);
}
