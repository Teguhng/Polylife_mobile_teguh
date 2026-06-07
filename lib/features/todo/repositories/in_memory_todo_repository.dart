import 'package:mobile_ver/features/todo/models/todo_item.dart';
import 'package:mobile_ver/features/todo/repositories/todo_repository.dart';

class InMemoryTodoRepository implements TodoRepository {
  static final List<TodoItem> _store = <TodoItem>[];

  @override
  Future<List<TodoItem>> fetchAll() async {
    final rows = List<TodoItem>.from(_store)
      ..sort((a, b) {
        if (a.completed != b.completed) {
          return a.completed ? 1 : -1;
        }
        return b.createdAt.compareTo(a.createdAt);
      });
    return rows;
  }

  @override
  Future<TodoItem> create(TodoItem item) async {
    final nextId = _store.isEmpty
        ? 1
        : _store.map((row) => row.id).reduce((a, b) => a > b ? a : b) + 1;

    final created = item.copyWith(id: nextId);
    _store.add(created);
    return created;
  }

  @override
  Future<TodoItem> update(TodoItem item) async {
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
