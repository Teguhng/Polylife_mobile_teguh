import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_ver/features/pengumuman/models/pengumuman_model.dart';

void main() {
  group('Pengumuman model', () {
    test('parses announcement payload and keeps creator object', () {
      final pengumuman = Pengumuman.fromJson({
        'id': '8',
        'title': 'Info Kampus',
        'body': 'Isi lengkap',
        'excerpt': 'Ringkasan',
        'image_url': 'https://example.test/image.jpg',
        'target_mode': 'affiliation',
        'published_at': '2026-05-13 10:00',
        'creator': {'name': 'Admin'},
      });

      expect(pengumuman.id, 8);
      expect(pengumuman.title, 'Info Kampus');
      expect(pengumuman.body, 'Isi lengkap');
      expect(pengumuman.targetMode, 'affiliation');
      expect(pengumuman.creator?['name'], 'Admin');
    });

    test('uses display-safe defaults for empty announcement payload', () {
      final pengumuman = Pengumuman.fromJson({
        'title': '   ',
        'body': '',
        'target_mode': '',
        'creator': 'invalid',
      });

      expect(pengumuman.id, 0);
      expect(pengumuman.title, 'Tanpa Judul');
      expect(pengumuman.body, isNull);
      expect(pengumuman.excerpt, '');
      expect(pengumuman.targetMode, 'global');
      expect(pengumuman.creator, isNull);
    });
  });
}
