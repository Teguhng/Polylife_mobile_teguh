import 'dart:async';
import 'dart:convert';

import 'package:mobile_ver/core/database/app_database.dart';
import 'package:mobile_ver/core/sync/sync_models.dart';
import 'package:mobile_ver/core/sync/sync_service.dart';
import 'package:mobile_ver/core/sync/sync_uuid.dart';
import 'package:mobile_ver/features/todo/models/todo_item.dart';
import 'package:mobile_ver/features/todo/repositories/todo_repository.dart';

class OfflineFirstTodoRepository implements TodoRepository {
  OfflineFirstTodoRepository({required this.userId});

  final int userId;

  @override
  Future<List<TodoItem>> fetchAll() async {
    if (userId <= 0) {
      return const <TodoItem>[];
    }

    unawaited(const SyncService().syncNow(userId));
    final db = await AppDatabase.instance.database;
    final rows = await db.query(
      'todo_local',
      where: 'user_id = ? AND deleted_locally = 0',
      whereArgs: [userId],
      orderBy: 'completed ASC, due_at IS NULL ASC, due_at ASC, created_at DESC',
    );

    return rows.map(_fromRow).toList();
  }

  @override
  Future<TodoItem> create(TodoItem item) async {
    final localUuid = SyncUuid.v4();
    final operationId = SyncUuid.v4();
    final now = DateTime.now().toIso8601String();
    final payload = _toPayload(item);
    final localId = _localId(localUuid);

    await AppDatabase.instance.transaction((txn) async {
      await txn.insert('todo_local', {
        'local_uuid': localUuid,
        'local_int_id': localId,
        'user_id': userId,
        'server_id': null,
        'title': item.title.trim(),
        'description': item.description.trim(),
        'completed': item.completed ? 1 : 0,
        'due_at': item.dueDate?.toIso8601String(),
        'priority': item.priority == TodoPriority.high ? 'high' : 'normal',
        'server_version': 0,
        'sync_status': SyncStatus.pendingCreate.wireName,
        'deleted_locally': 0,
        'created_at': now,
        'updated_at': now,
        'dirty_at': now,
      });
      await SyncService.enqueue(
        txn,
        operationId: operationId,
        userId: userId,
        entityType: 'todolist',
        entityLocalUuid: localUuid,
        entityServerId: null,
        action: 'create',
        payload: payload,
        baseServerVersion: null,
      );
    });

    unawaited(const SyncService().pushPending(userId));
    return item.copyWith(
      id: localId,
      localUuid: localUuid,
      syncStatus: SyncStatus.pendingCreate.wireName,
    );
  }

  @override
  Future<TodoItem> update(TodoItem item) async {
    final row = await _findRow(item);
    if (row == null) {
      throw Exception('Todo lokal tidak ditemukan');
    }

    final localUuid = row['local_uuid']?.toString() ?? item.localUuid;
    final serverId = (row['server_id'] as num?)?.toInt();
    final serverVersion = (row['server_version'] as num?)?.toInt() ?? 0;
    final operationId = SyncUuid.v4();
    final now = DateTime.now().toIso8601String();
    final payload = _toPayload(item);
    final currentStatus =
        row['sync_status']?.toString() ?? SyncStatus.synced.wireName;
    final nextStatus = currentStatus == SyncStatus.pendingCreate.wireName
        ? SyncStatus.pendingCreate.wireName
        : SyncStatus.pendingUpdate.wireName;

    await AppDatabase.instance.transaction((txn) async {
      await txn.update(
        'todo_local',
        {
          'title': item.title.trim(),
          'description': item.description.trim(),
          'completed': item.completed ? 1 : 0,
          'due_at': item.dueDate?.toIso8601String(),
          'priority': item.priority == TodoPriority.high ? 'high' : 'normal',
          'sync_status': nextStatus,
          'updated_at': now,
          'dirty_at': now,
        },
        where: 'local_uuid = ?',
        whereArgs: [localUuid],
      );

      if (currentStatus == SyncStatus.pendingCreate.wireName) {
        await txn.update(
          'sync_outbox',
          {
            'payload_json': jsonEncode(payload),
            'updated_at': now,
            'status': 'pending',
          },
          where: 'entity_local_uuid = ? AND entity_type = ? AND action = ?',
          whereArgs: [localUuid, 'todolist', 'create'],
        );
      } else {
        await SyncService.enqueue(
          txn,
          operationId: operationId,
          userId: userId,
          entityType: 'todolist',
          entityLocalUuid: localUuid,
          entityServerId: serverId,
          action: 'update',
          payload: payload,
          baseServerVersion: serverId == null ? null : serverVersion,
        );
      }
    });

    unawaited(const SyncService().pushPending(userId));
    return item.copyWith(
      localUuid: localUuid,
      serverId: serverId,
      serverVersion: serverVersion,
      syncStatus: nextStatus,
    );
  }

  @override
  Future<void> delete(int id) async {
    final row = await _findRowById(id);
    if (row == null) {
      return;
    }

    final localUuid = row['local_uuid']?.toString() ?? '';
    final serverId = (row['server_id'] as num?)?.toInt();
    final serverVersion = (row['server_version'] as num?)?.toInt() ?? 0;
    final currentStatus =
        row['sync_status']?.toString() ?? SyncStatus.synced.wireName;
    final now = DateTime.now().toIso8601String();

    await AppDatabase.instance.transaction((txn) async {
      if (currentStatus == SyncStatus.pendingCreate.wireName) {
        await txn.delete(
          'todo_local',
          where: 'local_uuid = ?',
          whereArgs: [localUuid],
        );
        await txn.delete(
          'sync_outbox',
          where: 'entity_local_uuid = ? AND entity_type = ?',
          whereArgs: [localUuid, 'todolist'],
        );
      } else {
        await txn.update(
          'todo_local',
          {
            'deleted_locally': 1,
            'sync_status': SyncStatus.pendingDelete.wireName,
            'updated_at': now,
            'dirty_at': now,
          },
          where: 'local_uuid = ?',
          whereArgs: [localUuid],
        );

        await SyncService.enqueue(
          txn,
          operationId: SyncUuid.v4(),
          userId: userId,
          entityType: 'todolist',
          entityLocalUuid: localUuid,
          entityServerId: serverId,
          action: 'delete',
          payload: const <String, dynamic>{},
          baseServerVersion: serverId == null ? null : serverVersion,
        );
      }
    });

    unawaited(const SyncService().pushPending(userId));
  }

  Future<Map<String, Object?>?> _findRow(TodoItem item) async {
    if (item.localUuid.isNotEmpty) {
      final db = await AppDatabase.instance.database;
      final rows = await db.query(
        'todo_local',
        where: 'local_uuid = ?',
        whereArgs: [item.localUuid],
        limit: 1,
      );
      if (rows.isNotEmpty) return rows.first;
    }

    return _findRowById(item.id);
  }

  Future<Map<String, Object?>?> _findRowById(int id) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query(
      'todo_local',
      where: 'user_id = ? AND (server_id = ? OR local_int_id = ?)',
      whereArgs: [userId, id, id],
      limit: 1,
    );

    return rows.isEmpty ? null : rows.first;
  }

  TodoItem _fromRow(Map<String, Object?> row) {
    final serverId = (row['server_id'] as num?)?.toInt();
    final localUuid = row['local_uuid']?.toString() ?? '';
    final dueAt = DateTime.tryParse(row['due_at']?.toString() ?? '');
    final priority = row['priority']?.toString() == 'high'
        ? TodoPriority.high
        : TodoPriority.normal;

    return TodoItem(
      id: serverId ?? _localId(localUuid),
      localUuid: localUuid,
      serverId: serverId,
      serverVersion: (row['server_version'] as num?)?.toInt() ?? 0,
      syncStatus: row['sync_status']?.toString() ?? SyncStatus.synced.wireName,
      title: row['title']?.toString() ?? '',
      description: row['description']?.toString() ?? '',
      createdAt:
          DateTime.tryParse(row['created_at']?.toString() ?? '') ??
          DateTime.now(),
      dueDate: dueAt,
      priority: priority,
      completed: row['completed'] == 1,
    );
  }

  Map<String, dynamic> _toPayload(TodoItem item) {
    final dueDate = item.dueDate;
    return {
      'nama_item': item.title.trim(),
      'status': item.completed,
      'reminder_enabled': dueDate != null,
      'reminder_date': dueDate == null ? null : _dateKey(dueDate),
      'reminder_time': dueDate == null ? null : _timeKey(dueDate),
    };
  }

  int _localId(String value) {
    var hash = 0;
    for (final code in value.codeUnits) {
      hash = 0x1fffffff & (hash + code);
      hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
      hash ^= hash >> 6;
    }
    return -hash.abs();
  }

  String _dateKey(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String _timeKey(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
