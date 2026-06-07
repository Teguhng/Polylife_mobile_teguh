import 'package:mobile_ver/features/jadwal/models/jadwal_item.dart';
import 'package:mobile_ver/features/jadwal/repositories/jadwal_repository.dart';

class InMemoryJadwalRepository implements JadwalRepository {
  static final List<JadwalItem> _store = <JadwalItem>[
    JadwalItem(
      id: 1,
      title: 'Kuliah Pemrograman Web',
      type: JadwalType.kuliah,
      startAt: DateTime(2026, 3, 2, 8, 0),
      endAt: DateTime(2026, 3, 2, 9, 40),
      location: 'Gedung A - Ruang 204',
      notes: 'Bawa laptop dan review materi middleware.',
      completed: false,
    ),
    JadwalItem(
      id: 2,
      title: 'Rapat Himpunan',
      type: JadwalType.rapat,
      startAt: DateTime(2026, 3, 2, 13, 0),
      endAt: DateTime(2026, 3, 2, 14, 30),
      location: 'Sekretariat HM',
      notes: 'Bahas agenda ospek jurusan.',
      completed: false,
    ),
    JadwalItem(
      id: 3,
      title: 'Deadline Laporan PBO',
      type: JadwalType.tugas,
      startAt: DateTime(2026, 3, 3, 20, 0),
      endAt: DateTime(2026, 3, 3, 21, 0),
      location: 'Online LMS',
      notes: 'Upload PDF final dan source code.',
      completed: false,
    ),
  ];

  @override
  Future<List<JadwalItem>> fetchAll() async {
    final rows = List<JadwalItem>.from(_store)
      ..sort((a, b) {
        final byDate = a.startAt.compareTo(b.startAt);
        if (byDate != 0) return byDate;
        return a.id.compareTo(b.id);
      });
    return rows;
  }

  @override
  Future<JadwalItem> create(JadwalItem item) async {
    final nextId = _store.isEmpty
        ? 1
        : _store.map((row) => row.id).reduce((a, b) => a > b ? a : b) + 1;

    final created = item.copyWith(id: nextId);
    _store.add(created);
    return created;
  }

  @override
  Future<JadwalItem> update(JadwalItem item) async {
    final index = _store.indexWhere((row) => row.id == item.id);
    if (index >= 0) {
      _store[index] = item;
    }
    return item;
  }

  @override
  Future<void> delete(int id) async {
    _store.removeWhere((row) => row.id == id);
  }
}
