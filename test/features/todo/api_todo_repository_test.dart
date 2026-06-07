import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_ver/features/todo/models/todo_item.dart';
import 'package:mobile_ver/features/todo/repositories/api_todo_repository.dart';

import '../../support/fake_http_api_client.dart';

void main() {
  group('ApiTodoRepository', () {
    test(
      'fetchAll parses Laravel payload and sorts active tasks first',
      () async {
        final client = FakeHttpApiClient()
          ..when(
            'GET',
            '/todolist',
            statusCode: 200,
            body: '''
          {
            "data": [
              {
                "id": 3,
                "nama_item": "Selesai",
                "status": 1,
                "reminder_enabled": 0,
                "created_at": "2026-05-10T08:00:00Z"
              },
              {
                "id": 1,
                "nama_item": "Besok",
                "status": 0,
                "reminder_enabled": "1",
                "reminder_at": "2026-05-14T09:00:00Z",
                "created_at": "2026-05-10T08:00:00Z"
              },
              {
                "id": 2,
                "nama_item": "Hari ini",
                "status": false,
                "reminder_enabled": true,
                "reminder_at": "2026-05-13T09:00:00Z",
                "created_at": "2026-05-11T08:00:00Z"
              }
            ]
          }
          ''',
          );
        final repository = ApiTodoRepository(client: client);

        final rows = await repository.fetchAll();

        expect(client.requests.single.endpoint, '/todolist');
        expect(rows.map((row) => row.title), ['Hari ini', 'Besok', 'Selesai']);
        expect(rows.first.priority, TodoPriority.high);
        expect(rows.first.completed, isFalse);
        expect(rows.last.completed, isTrue);
      },
    );

    test('create sends normalized payload and reads created task', () async {
      final client = FakeHttpApiClient()
        ..when(
          'POST',
          '/todolist',
          statusCode: 201,
          body: '''
          {
            "data": {
              "id": 10,
              "nama_item": "Belajar API",
              "status": 0,
              "reminder_enabled": 1,
              "reminder_at": "2026-05-13T07:30:00Z",
              "created_at": "2026-05-12T10:00:00Z"
            }
          }
          ''',
        );
      final repository = ApiTodoRepository(client: client);

      final created = await repository.create(
        TodoItem(
          id: 0,
          title: '  Belajar API  ',
          description: 'tidak dikirim API',
          createdAt: DateTime(2026, 5, 12),
          dueDate: DateTime(2026, 5, 13, 7, 30),
          priority: TodoPriority.high,
          completed: false,
        ),
      );

      expect(client.requests.single.method, 'POST');
      expect(client.requests.single.body, {
        'nama_item': 'Belajar API',
        'status': false,
        'reminder_enabled': true,
        'reminder_date': '2026-05-13',
        'reminder_time': '07:30',
      });
      expect(created.id, 10);
      expect(created.title, 'Belajar API');
      expect(created.dueDate, isNotNull);
    });

    test('update and delete use item id in endpoint', () async {
      final client = FakeHttpApiClient()
        ..when(
          'PUT',
          '/todolist/4',
          statusCode: 200,
          body: '''
          {
            "data": {
              "id": 4,
              "nama_item": "Selesai",
              "status": 1,
              "created_at": "2026-05-12T10:00:00Z"
            }
          }
          ''',
        )
        ..when('DELETE', '/todolist/4', statusCode: 200, body: '{}');
      final repository = ApiTodoRepository(client: client);

      final updated = await repository.update(
        TodoItem(
          id: 4,
          title: 'Selesai',
          description: '',
          createdAt: DateTime(2026, 5, 12),
          dueDate: null,
          priority: TodoPriority.normal,
          completed: true,
        ),
      );
      await repository.delete(4);

      expect(updated.completed, isTrue);
      expect(client.requests.map((request) => request.endpoint), [
        '/todolist/4',
        '/todolist/4',
      ]);
      expect(client.requests.first.body?['reminder_enabled'], isFalse);
    });

    test('throws when API returns non-success status', () async {
      final client = FakeHttpApiClient()
        ..when('GET', '/todolist', statusCode: 500, body: '{}')
        ..when('DELETE', '/todolist/9', statusCode: 404, body: '{}');
      final repository = ApiTodoRepository(client: client);

      expect(repository.fetchAll(), throwsException);
      expect(repository.delete(9), throwsException);
    });
  });
}
