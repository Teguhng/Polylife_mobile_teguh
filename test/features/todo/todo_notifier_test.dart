import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_ver/features/todo/models/todo_item.dart';
import 'package:mobile_ver/features/todo/providers/todo_provider.dart';
import 'package:mobile_ver/features/todo/repositories/todo_repository.dart';

void main() {
  group('TodoNotifier', () {
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

    test('loads tasks and derives ongoing and completed buckets', () async {
      final repository = _FakeTodoRepository([
        item(
          id: 1,
          title: 'Selesai',
          createdAt: DateTime(2026),
          completed: true,
        ),
        item(id: 2, title: 'Belum', createdAt: DateTime(2026, 1, 2)),
      ]);
      final notifier = TodoNotifier(repository: repository);

      await _flushAsync();

      expect(notifier.state.isLoading, isFalse);
      expect(notifier.state.items.map((row) => row.title), [
        'Belum',
        'Selesai',
      ]);
      expect(notifier.state.ongoingItems.map((row) => row.title), ['Belum']);
      expect(notifier.state.completedItems.map((row) => row.title), [
        'Selesai',
      ]);
      expect(notifier.state.errorMessage, isNull);
    });

    test('rejects empty create input before touching repository', () async {
      final repository = _FakeTodoRepository();
      final notifier = TodoNotifier(repository: repository);

      await _flushAsync();

      final result = await notifier.createTask(
        const TodoInput(
          title: '   ',
          description: 'Abaikan',
          dueDate: null,
          priority: TodoPriority.normal,
        ),
      );

      expect(result.success, isFalse);
      expect(result.message, 'Judul tugas wajib diisi.');
      expect(repository.createCount, 0);
    });

    test(
      'creates, toggles, deletes, and keeps derived state updated',
      () async {
        final repository = _FakeTodoRepository();
        final notifier = TodoNotifier(repository: repository);

        await _flushAsync();

        final created = await notifier.createTask(
          TodoInput(
            title: '  Belajar Flutter  ',
            description: '  Riverpod  ',
            dueDate: DateTime(2026, 5, 13, 10),
            priority: TodoPriority.high,
          ),
        );

        expect(created.success, isTrue);
        expect(notifier.state.items.single.title, 'Belajar Flutter');
        expect(notifier.state.items.single.description, 'Riverpod');
        expect(notifier.state.ongoingItems, hasLength(1));

        await notifier.toggleCompleted(notifier.state.items.single);

        expect(notifier.state.ongoingItems, isEmpty);
        expect(notifier.state.completedItems.single.completed, isTrue);

        await notifier.deleteTask(notifier.state.items.single.id);

        expect(notifier.state.items, isEmpty);
        expect(notifier.state.completedItems, isEmpty);
      },
    );

    test('surfaces repository errors without clearing current items', () async {
      final existing = item(
        id: 1,
        title: 'Tetap ada',
        createdAt: DateTime(2026, 5, 13),
      );
      final repository = _FakeTodoRepository([existing]);
      final notifier = TodoNotifier(repository: repository);

      await _flushAsync();

      repository.failUpdates = true;
      await notifier.toggleCompleted(existing);

      expect(notifier.state.items.single.completed, isFalse);
      expect(notifier.state.errorMessage, 'Gagal memperbarui status tugas.');
    });

    test('toggles section expansion state independently', () async {
      final notifier = TodoNotifier(repository: _FakeTodoRepository());

      await _flushAsync();

      notifier.toggleOngoingExpanded();
      expect(notifier.state.ongoingExpanded, isFalse);
      expect(notifier.state.completedExpanded, isTrue);

      notifier.toggleCompletedExpanded();
      expect(notifier.state.ongoingExpanded, isFalse);
      expect(notifier.state.completedExpanded, isFalse);
    });
  });
}

class _FakeTodoRepository implements TodoRepository {
  _FakeTodoRepository([List<TodoItem>? seed]) : _items = List.of(seed ?? []);

  final List<TodoItem> _items;
  int createCount = 0;
  bool failUpdates = false;

  @override
  Future<List<TodoItem>> fetchAll() async {
    return List<TodoItem>.of(_items)..sort((a, b) {
      if (a.completed != b.completed) {
        return a.completed ? 1 : -1;
      }
      return b.createdAt.compareTo(a.createdAt);
    });
  }

  @override
  Future<TodoItem> create(TodoItem item) async {
    createCount++;
    final nextId = _items.isEmpty
        ? 1
        : _items.map((row) => row.id).reduce((a, b) => a > b ? a : b) + 1;
    final created = item.copyWith(id: nextId);
    _items.add(created);
    return created;
  }

  @override
  Future<TodoItem> update(TodoItem item) async {
    if (failUpdates) {
      throw StateError('failed update');
    }

    final index = _items.indexWhere((row) => row.id == item.id);
    if (index != -1) {
      _items[index] = item;
    }
    return item;
  }

  @override
  Future<void> delete(int id) async {
    _items.removeWhere((row) => row.id == id);
  }
}

Future<void> _flushAsync() async {
  await Future<void>.delayed(Duration.zero);
}
