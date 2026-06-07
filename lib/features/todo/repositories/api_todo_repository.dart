import 'dart:convert';

import 'package:intl/intl.dart';
import 'package:mobile_ver/core/network/api_client.dart';
import 'package:mobile_ver/features/todo/models/todo_item.dart';
import 'package:mobile_ver/features/todo/repositories/todo_repository.dart';

class ApiTodoRepository implements TodoRepository {
  ApiTodoRepository({HttpApiClient? client})
    : _client = client ?? const StaticApiClientAdapter();

  static final DateFormat _dateFormatter = DateFormat('yyyy-MM-dd');
  static final DateFormat _timeFormatter = DateFormat('HH:mm');
  final HttpApiClient _client;

  @override
  Future<List<TodoItem>> fetchAll() async {
    final response = await _client.get('/todolist');
    if (response.statusCode != 200) {
      throw Exception('Failed to load todo');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      return const <TodoItem>[];
    }

    final rawData = decoded['data'];
    if (rawData is! List) {
      return const <TodoItem>[];
    }

    final rows =
        rawData
            .whereType<Map>()
            .map((row) => _fromApiJson(Map<String, dynamic>.from(row)))
            .toList()
          ..sort((a, b) {
            if (a.completed != b.completed) {
              return a.completed ? 1 : -1;
            }

            final dueA = a.dueDate;
            final dueB = b.dueDate;
            if (dueA == null && dueB != null) return 1;
            if (dueA != null && dueB == null) return -1;
            if (dueA != null && dueB != null) {
              final byDue = dueA.compareTo(dueB);
              if (byDue != 0) return byDue;
            }

            return b.createdAt.compareTo(a.createdAt);
          });

    return rows;
  }

  @override
  Future<TodoItem> create(TodoItem item) async {
    final response = await _client.post('/todolist', _toApiPayload(item));
    if (response.statusCode != 201) {
      throw Exception('Failed to create todo');
    }

    return _readTodoFromResponse(response.body);
  }

  @override
  Future<TodoItem> update(TodoItem item) async {
    final response = await _client.put(
      '/todolist/${item.id}',
      _toApiPayload(item),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to update todo');
    }

    return _readTodoFromResponse(response.body);
  }

  @override
  Future<void> delete(int id) async {
    final response = await _client.delete('/todolist/$id');
    if (response.statusCode != 200) {
      throw Exception('Failed to delete todo');
    }
  }

  Map<String, dynamic> _toApiPayload(TodoItem item) {
    final dueDate = item.dueDate;

    return <String, dynamic>{
      'nama_item': item.title.trim(),
      'status': item.completed,
      'reminder_enabled': dueDate != null,
      'reminder_date': dueDate == null ? null : _dateFormatter.format(dueDate),
      'reminder_time': dueDate == null ? null : _timeFormatter.format(dueDate),
    };
  }

  TodoItem _readTodoFromResponse(String body) {
    final decoded = jsonDecode(body);
    if (decoded is! Map<String, dynamic>) {
      throw Exception('Invalid response');
    }

    final rawData = decoded['data'];
    if (rawData is! Map) {
      throw Exception('Invalid response');
    }

    return _fromApiJson(Map<String, dynamic>.from(rawData));
  }

  TodoItem _fromApiJson(Map<String, dynamic> json) {
    final dueDate = DateTime.tryParse((json['reminder_at'] ?? '').toString());
    final reminderEnabled =
        json['reminder_enabled'] == true ||
        json['reminder_enabled'] == 1 ||
        json['reminder_enabled'] == '1';
    final completed =
        json['status'] == true || json['status'] == 1 || json['status'] == '1';

    return TodoItem(
      id: int.tryParse((json['id'] ?? '').toString()) ?? 0,
      title: (json['nama_item'] ?? '').toString(),
      description: '',
      createdAt:
          DateTime.tryParse((json['created_at'] ?? '').toString()) ??
          DateTime.now(),
      dueDate: dueDate,
      priority: reminderEnabled || dueDate != null
          ? TodoPriority.high
          : TodoPriority.normal,
      completed: completed,
    );
  }
}
