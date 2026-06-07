import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_ver/features/catatan/models/catatan_model.dart';

void main() {
  group('Catatan model', () {
    test('uses preview as isi when full content is not included', () {
      final catatan = Catatan.fromJson({
        'id': '12',
        'sync_uuid': 'note-uuid',
        'server_version': '3',
        'judul': 'Judul',
        'preview_isi': 'Preview aman',
        'show_preview': true,
        'tanggal': '2026-05-13',
        'status_sampah': '0',
      });

      expect(catatan.id, 12);
      expect(catatan.serverId, 12);
      expect(catatan.serverVersion, 3);
      expect(catatan.isi, '');
      expect(catatan.showPreview, isTrue);
      expect(catatan.hasFullIsi, isFalse);
      expect(catatan.listPreview, 'Preview aman');
      expect(catatan.statusSampah, isFalse);
    });

    test('detects trash status and keeps full content when present', () {
      final catatan = Catatan.fromJson({
        'id': 15,
        'judul': 'Rahasia',
        'isi': 'Isi lengkap',
        'preview_isi': 'Preview pendek',
        'show_preview': true,
        'tanggal': '2026-05-10',
        'status_sampah': 1,
        'created_at': '2026-05-10T10:00:00Z',
      });

      expect(catatan.isi, 'Isi lengkap');
      expect(catatan.previewIsi, 'Preview pendek');
      expect(catatan.showPreview, isTrue);
      expect(catatan.hasFullIsi, isTrue);
      expect(catatan.statusSampah, isTrue);
      expect(catatan.tanggalAsDate, DateTime(2026, 5, 10));
      expect(catatan.createdAt, isNotNull);
    });

    test(
      'hides preview and never falls back to full content when disabled',
      () {
        final catatan = Catatan.fromJson({
          'id': 20,
          'judul': 'Rahasia',
          'isi': 'Isi lengkap tidak boleh muncul di list',
          'preview_isi': 'Preview dari server',
          'show_preview': false,
          'tanggal': '2026-05-10',
          'status_sampah': false,
        });

        expect(catatan.isi, 'Isi lengkap tidak boleh muncul di list');
        expect(catatan.previewIsi, '');
        expect(catatan.showPreview, isFalse);
        expect(catatan.listPreview, '');
      },
    );
  });
}
