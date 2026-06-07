import 'package:mobile_ver/features/todo/models/todo_item.dart';

class TodoProgressBucket {
  final List<TodoItem> ongoing;
  final List<TodoItem> completed;

  const TodoProgressBucket({required this.ongoing, required this.completed});
}

class TodoProgressService {
  const TodoProgressService();

  TodoProgressBucket splitByCompletion(List<TodoItem> source) {
    final ongoing = source.where((item) => !item.completed).toList()
      ..sort((a, b) {
        final aDue = a.dueDate ?? DateTime(2100);
        final bDue = b.dueDate ?? DateTime(2100);
        final byDue = aDue.compareTo(bDue);
        if (byDue != 0) return byDue;
        return b.createdAt.compareTo(a.createdAt);
      });

    final completed = source.where((item) => item.completed).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return TodoProgressBucket(ongoing: ongoing, completed: completed);
  }
}
