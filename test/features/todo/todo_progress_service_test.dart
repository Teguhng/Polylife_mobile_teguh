import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_ver/features/todo/models/todo_item.dart';
import 'package:mobile_ver/features/todo/services/todo_progress_service.dart';

void main() {
  group('TodoProgressService', () {
    const service = TodoProgressService();

    TodoItem item({
      required int id,
      required String title,
      required DateTime createdAt,
      DateTime? dueDate,
      bool completed = false,
    }) {
      return TodoItem(
        id: id,
        title: title,
        description: '',
        createdAt: createdAt,
        dueDate: dueDate,
        priority: TodoPriority.normal,
        completed: completed,
      );
    }

    test('splits ongoing and completed tasks', () {
      final bucket = service.splitByCompletion([
        item(
          id: 1,
          title: 'Selesai',
          createdAt: DateTime(2026),
          completed: true,
        ),
        item(id: 2, title: 'Belum', createdAt: DateTime(2026, 1, 2)),
      ]);

      expect(bucket.ongoing.map((todo) => todo.title), ['Belum']);
      expect(bucket.completed.map((todo) => todo.title), ['Selesai']);
    });

    test('sorts ongoing tasks by due date then newest created date', () {
      final bucket = service.splitByCompletion([
        item(id: 1, title: 'Tanpa deadline', createdAt: DateTime(2026, 1, 1)),
        item(
          id: 2,
          title: 'Deadline besok',
          createdAt: DateTime(2026, 1, 1),
          dueDate: DateTime(2026, 5, 14),
        ),
        item(
          id: 3,
          title: 'Deadline hari ini lebih baru',
          createdAt: DateTime(2026, 1, 3),
          dueDate: DateTime(2026, 5, 13),
        ),
        item(
          id: 4,
          title: 'Deadline hari ini lebih lama',
          createdAt: DateTime(2026, 1, 2),
          dueDate: DateTime(2026, 5, 13),
        ),
      ]);

      expect(bucket.ongoing.map((todo) => todo.title), [
        'Deadline hari ini lebih baru',
        'Deadline hari ini lebih lama',
        'Deadline besok',
        'Tanpa deadline',
      ]);
    });
  });
}
