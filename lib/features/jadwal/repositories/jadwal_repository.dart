import 'package:mobile_ver/features/jadwal/models/jadwal_item.dart';

abstract class JadwalRepository {
  Future<List<JadwalItem>> fetchAll();

  Future<JadwalItem> create(JadwalItem item);

  Future<JadwalItem> update(JadwalItem item);

  Future<void> delete(int id);
}
