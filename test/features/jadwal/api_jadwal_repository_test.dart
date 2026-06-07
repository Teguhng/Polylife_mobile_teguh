import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_ver/features/jadwal/models/jadwal_item.dart';
import 'package:mobile_ver/features/jadwal/repositories/api_jadwal_repository.dart';

import '../../support/fake_http_api_client.dart';

void main() {
  group('ApiJadwalRepository', () {
    test(
      'fetchAll parses schedule payload, matkul previews, and sorts by start',
      () async {
        final client = FakeHttpApiClient()
          ..when(
            'GET',
            '/jadwal?per_page=200',
            statusCode: 200,
            body: '''
          {
            "data": [
              {
                "id": "2",
                "title": "Agenda siang",
                "type": "rapat",
                "start_at": "2026-05-13T13:00:00",
                "end_at": "2026-05-13T12:00:00",
                "completed": "1",
                "matkul_names": ["", "Manajemen Proyek"],
                "primary_matkul": {
                  "id": "7",
                  "nama": "Manajemen Proyek",
                  "kelas": "TI-1",
                  "schedule_days": ["Senin", "Rabu"],
                  "schedule_entries": [
                    {
                      "hari": "Rabu",
                      "jam_mulai": "13:00",
                      "jam_selesai": "14:40",
                      "ruangan": "A204",
                      "kelas": "TI-1"
                    }
                  ]
                }
              },
              {
                "id": "1",
                "title": "Agenda pagi",
                "type": "kuliah",
                "start_at": "2026-05-13T08:00:00",
                "end_at": "2026-05-13T09:40:00",
                "completed": 0
              }
            ]
          }
          ''',
          );
        final repository = ApiJadwalRepository(client: client);

        final rows = await repository.fetchAll();

        expect(client.requests.single.endpoint, '/jadwal?per_page=200');
        expect(rows.map((row) => row.title), ['Agenda pagi', 'Agenda siang']);
        expect(rows.last.completed, isTrue);
        expect(rows.last.endAt, DateTime(2026, 5, 13, 14));
        expect(rows.last.matkulNames, ['Manajemen Proyek']);
        expect(rows.last.primaryMatkul?.name, 'Manajemen Proyek');
        expect(rows.last.primaryMatkul?.scheduleDays, ['senin', 'rabu']);
        expect(rows.last.primaryMatkul?.scheduleEntries.single.ruangan, 'A204');
      },
    );

    test('create sends trimmed payload and reads created row', () async {
      final client = FakeHttpApiClient()
        ..when(
          'POST',
          '/jadwal',
          statusCode: 201,
          body: '''
          {
            "data": {
              "id": 5,
              "title": "Ujian",
              "type": "ujian",
              "start_at": "2026-05-13T10:00:00",
              "end_at": "2026-05-13T12:00:00",
              "location": "Ruang A",
              "notes": "Bawa kartu",
              "completed": false
            }
          }
          ''',
        );
      final repository = ApiJadwalRepository(client: client);

      final created = await repository.create(
        JadwalItem(
          id: 0,
          title: '  Ujian  ',
          type: JadwalType.ujian,
          startAt: DateTime(2026, 5, 13, 10),
          endAt: DateTime(2026, 5, 13, 12),
          location: '  Ruang A  ',
          notes: '  Bawa kartu  ',
          completed: false,
        ),
      );

      expect(client.requests.single.body, {
        'title': 'Ujian',
        'type': 'ujian',
        'start_at': DateTime(2026, 5, 13, 10).toIso8601String(),
        'end_at': DateTime(2026, 5, 13, 12).toIso8601String(),
        'location': 'Ruang A',
        'notes': 'Bawa kartu',
        'completed': false,
      });
      expect(created.id, 5);
      expect(created.type, JadwalType.ujian);
    });

    test('update and delete use agenda id in endpoint', () async {
      final client = FakeHttpApiClient()
        ..when(
          'PUT',
          '/jadwal/8',
          statusCode: 200,
          body: '''
          {
            "data": {
              "id": 8,
              "title": "Personal",
              "type": "personal",
              "start_at": "2026-05-13T18:00:00",
              "end_at": "2026-05-13T19:00:00",
              "completed": true
            }
          }
          ''',
        )
        ..when('DELETE', '/jadwal/8', statusCode: 200, body: '{}');
      final repository = ApiJadwalRepository(client: client);

      final updated = await repository.update(
        JadwalItem(
          id: 8,
          title: 'Personal',
          type: JadwalType.personal,
          startAt: DateTime(2026, 5, 13, 18),
          endAt: DateTime(2026, 5, 13, 19),
          location: '',
          notes: '',
          completed: true,
        ),
      );
      await repository.delete(8);

      expect(updated.completed, isTrue);
      expect(client.requests.map((request) => request.endpoint), [
        '/jadwal/8',
        '/jadwal/8',
      ]);
    });

    test('throws when API returns non-success status', () async {
      final client = FakeHttpApiClient()
        ..when('GET', '/jadwal?per_page=200', statusCode: 500, body: '{}')
        ..when('DELETE', '/jadwal/9', statusCode: 404, body: '{}');
      final repository = ApiJadwalRepository(client: client);

      expect(repository.fetchAll(), throwsException);
      expect(repository.delete(9), throwsException);
    });
  });
}
