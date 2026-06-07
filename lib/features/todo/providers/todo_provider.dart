import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mobile_ver/core/config/app_mode.dart';
import 'package:mobile_ver/features/auth/providers/auth_provider.dart';
import 'package:mobile_ver/features/todo/models/todo_item.dart';
import 'package:mobile_ver/features/todo/repositories/api_todo_repository.dart';
import 'package:mobile_ver/features/todo/repositories/in_memory_todo_repository.dart';
import 'package:mobile_ver/features/todo/repositories/offline_first_todo_repository.dart';
import 'package:mobile_ver/features/todo/repositories/todo_repository.dart';
import 'package:mobile_ver/features/todo/services/todo_progress_service.dart';

class TodoActionResult {
  final bool success;
  final String? message;

  const TodoActionResult({required this.success, this.message});
}

class TodoState {
  final bool isLoading;
  final List<TodoItem> items;
  final List<TodoItem> ongoingItems;
  final List<TodoItem> completedItems;
  final bool ongoingExpanded;
  final bool completedExpanded;
  final String? errorMessage;

  const TodoState({
    required this.isLoading,
    required this.items,
    required this.ongoingItems,
    required this.completedItems,
    required this.ongoingExpanded,
    required this.completedExpanded,
    required this.errorMessage,
  });

  factory TodoState.initial() {
    return const TodoState(
      isLoading: true,
      items: <TodoItem>[],
      ongoingItems: <TodoItem>[],
      completedItems: <TodoItem>[],
      ongoingExpanded: true,
      completedExpanded: true,
      errorMessage: null,
    );
  }

  TodoState copyWith({
    bool? isLoading,
    List<TodoItem>? items,
    List<TodoItem>? ongoingItems,
    List<TodoItem>? completedItems,
    bool? ongoingExpanded,
    bool? completedExpanded,
    String? errorMessage,
    bool clearError = false,
  }) {
    return TodoState(
      isLoading: isLoading ?? this.isLoading,
      items: items ?? this.items,
      ongoingItems: ongoingItems ?? this.ongoingItems,
      completedItems: completedItems ?? this.completedItems,
      ongoingExpanded: ongoingExpanded ?? this.ongoingExpanded,
      completedExpanded: completedExpanded ?? this.completedExpanded,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class TodoNotifier extends StateNotifier<TodoState> {
  final TodoRepository _repository;
  final TodoProgressService _progressService;

  TodoNotifier({
    TodoRepository? repository,
    TodoProgressService? progressService,
  }) : _repository = repository ?? InMemoryTodoRepository(),
       _progressService = progressService ?? const TodoProgressService(),
       super(TodoState.initial()) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final rows = await _repository.fetchAll();
      _setItems(rows);
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Gagal memuat daftar tugas.',
      );
    }
  }

  Future<TodoActionResult> createTask(TodoInput input) async {
    final title = input.title.trim();
    if (title.isEmpty) {
      return const TodoActionResult(
        success: false,
        message: 'Judul tugas wajib diisi.',
      );
    }

    final item = TodoItem(
      id: 0,
      title: title,
      description: input.description.trim(),
      createdAt: DateTime.now(),
      dueDate: input.dueDate,
      priority: input.priority,
      completed: false,
    );

    try {
      await _repository.create(item);
      final rows = await _repository.fetchAll();
      _setItems(rows);
      return const TodoActionResult(success: true);
    } catch (_) {
      state = state.copyWith(errorMessage: 'Gagal menambah tugas.');
      return const TodoActionResult(
        success: false,
        message: 'Gagal menambah tugas.',
      );
    }
  }

  Future<void> toggleCompleted(TodoItem item) async {
    try {
      final updated = item.copyWith(completed: !item.completed);
      await _repository.update(updated);
      final rows = await _repository.fetchAll();
      _setItems(rows);
    } catch (_) {
      state = state.copyWith(errorMessage: 'Gagal memperbarui status tugas.');
    }
  }

  Future<void> deleteTask(int id) async {
    try {
      await _repository.delete(id);
      final rows = await _repository.fetchAll();
      _setItems(rows);
    } catch (_) {
      state = state.copyWith(errorMessage: 'Gagal menghapus tugas.');
    }
  }

  void toggleOngoingExpanded() {
    state = state.copyWith(ongoingExpanded: !state.ongoingExpanded);
  }

  void toggleCompletedExpanded() {
    state = state.copyWith(completedExpanded: !state.completedExpanded);
  }

  void _setItems(List<TodoItem> rows) {
    final bucket = _progressService.splitByCompletion(rows);

    state = state.copyWith(
      isLoading: false,
      items: rows,
      ongoingItems: bucket.ongoing,
      completedItems: bucket.completed,
      clearError: true,
    );
  }
}

final todoProvider = StateNotifierProvider<TodoNotifier, TodoState>((ref) {
  final user = ref.watch(userProvider);
  return TodoNotifier(
    repository: AppMode.uiOnly
        ? InMemoryTodoRepository()
        : user == null
        ? ApiTodoRepository()
        : OfflineFirstTodoRepository(userId: user.id),
  );
});
