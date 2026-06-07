import 'package:mobile_ver/features/todo/models/todo_item.dart';

abstract class TodoRepository {
  Future<List<TodoItem>> fetchAll();

  Future<TodoItem> create(TodoItem item);

  Future<TodoItem> update(TodoItem item);

  Future<void> delete(int id);
}
