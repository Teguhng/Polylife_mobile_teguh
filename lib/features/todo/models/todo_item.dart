enum TodoPriority { normal, high }

class TodoItem {
  final int id;
  final String localUuid;
  final int? serverId;
  final int serverVersion;
  final String syncStatus;
  final String title;
  final String description;
  final DateTime createdAt;
  final DateTime? dueDate;
  final TodoPriority priority;
  final bool completed;

  const TodoItem({
    required this.id,
    this.localUuid = '',
    this.serverId,
    this.serverVersion = 0,
    this.syncStatus = 'synced',
    required this.title,
    required this.description,
    required this.createdAt,
    required this.dueDate,
    required this.priority,
    required this.completed,
  });

  TodoItem copyWith({
    int? id,
    String? localUuid,
    int? serverId,
    int? serverVersion,
    String? syncStatus,
    String? title,
    String? description,
    DateTime? createdAt,
    DateTime? dueDate,
    TodoPriority? priority,
    bool? completed,
  }) {
    return TodoItem(
      id: id ?? this.id,
      localUuid: localUuid ?? this.localUuid,
      serverId: serverId ?? this.serverId,
      serverVersion: serverVersion ?? this.serverVersion,
      syncStatus: syncStatus ?? this.syncStatus,
      title: title ?? this.title,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      dueDate: dueDate ?? this.dueDate,
      priority: priority ?? this.priority,
      completed: completed ?? this.completed,
    );
  }
}

class TodoInput {
  final String title;
  final String description;
  final DateTime? dueDate;
  final TodoPriority priority;

  const TodoInput({
    required this.title,
    required this.description,
    required this.dueDate,
    required this.priority,
  });
}
