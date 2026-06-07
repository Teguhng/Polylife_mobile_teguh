import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mobile_ver/core/config/app_mode.dart';
import 'package:mobile_ver/core/database/app_database.dart';
import 'package:mobile_ver/core/network/api_client.dart';
import 'package:mobile_ver/core/notifications/reminder_notification_service.dart';
import 'package:mobile_ver/core/sync/sync_models.dart';
import 'package:mobile_ver/core/sync/sync_service.dart';
import 'package:mobile_ver/core/sync/sync_uuid.dart';
import 'package:mobile_ver/features/auth/providers/auth_provider.dart';
import 'package:mobile_ver/features/reminder/models/reminder_list_item.dart';
import 'package:mobile_ver/features/reminder/models/reminder_target_option.dart';

class ReminderListState {
  final bool isLoading;
  final List<ReminderListItem> items;
  final String? errorMessage;

  const ReminderListState({
    required this.isLoading,
    required this.items,
    required this.errorMessage,
  });

  factory ReminderListState.initial() {
    return const ReminderListState(
      isLoading: true,
      items: <ReminderListItem>[],
      errorMessage: null,
    );
  }

  ReminderListState copyWith({
    bool? isLoading,
    List<ReminderListItem>? items,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ReminderListState(
      isLoading: isLoading ?? this.isLoading,
      items: items ?? this.items,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class ReminderListNotifier extends StateNotifier<ReminderListState> {
  ReminderListNotifier({required this.userId})
    : super(ReminderListState.initial()) {
    load();
  }

  final int userId;

  static final List<ReminderListItem> _mockItems = <ReminderListItem>[
    ReminderListItem(
      id: 1,
      title: 'Laporan Praktikum PBO',
      targetType: 'todolist',
      targetLabel: 'To-Do',
      targetContext: 'To-Do: Laporan Praktikum PBO',
      destination: 'todo',
      active: true,
      scheduledAt: DateTime(2026, 4, 22, 1, 2),
      scheduledLabel: 'Rabu, 22 April 2026 - 01:02',
    ),
  ];

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);

    if (AppMode.uiOnly) {
      state = state.copyWith(
        isLoading: false,
        items: List<ReminderListItem>.from(_mockItems),
      );
      unawaited(
        ReminderNotificationService.instance.scheduleAll(state.items),
      );
      return;
    }

    if (userId > 0) {
      try {
        await const SyncService().syncNow(userId);
        final items = await _readLocalReminders();
        state = state.copyWith(
          isLoading: false,
          items: items,
          clearError: true,
        );
        unawaited(ReminderNotificationService.instance.scheduleAll(items));
      } catch (_) {
        final items = await _readLocalReminders();
        state = state.copyWith(
          isLoading: false,
          items: items,
          errorMessage: 'Memakai cache lokal. Sync reminder belum berhasil.',
        );
        unawaited(ReminderNotificationService.instance.scheduleAll(items));
      }
      return;
    }

    await _loadFromApi();
  }

  Future<List<ReminderTargetOption>> loadOptions() async {
    if (AppMode.uiOnly) {
      return const <ReminderTargetOption>[
        ReminderTargetOption(
          key: 'todolist',
          label: 'To-Do',
          helper:
              'Kirim pengingat dari tugas dalam daftar kegiatan sehari-hari.',
          options: [ReminderOptionItem(id: 1, label: 'Laporan Praktikum PBO')],
        ),
      ];
    }

    if (userId > 0) {
      await const SyncService().syncNow(userId);
      return _readLocalOptions();
    }

    return _loadOptionsFromApi();
  }

  Future<bool> createReminder({
    required ReminderTargetOption target,
    required int targetId,
    required DateTime scheduledAt,
    required bool active,
  }) async {
    if (AppMode.uiOnly) {
      final option = target.options.firstWhere(
        (item) => item.id == targetId,
        orElse: () => ReminderOptionItem(id: targetId, label: target.label),
      );
      final localUuid = SyncUuid.v4();
      final item = _buildLocalItem(
        localUuid: localUuid,
        localIntId: _localId(localUuid),
        serverId: null,
        serverVersion: 0,
        syncStatus: SyncStatus.pendingCreate.wireName,
        targetType: target.key,
        targetServerId: targetId,
        title: option.label,
        targetLabel: target.label,
        scheduledAt: scheduledAt,
        active: active,
      );

      state = state.copyWith(items: [item, ...state.items], clearError: true);
      unawaited(ReminderNotificationService.instance.schedule(item));
      return true;
    }

    if (userId <= 0) {
      return _createViaApi(
        target: target,
        targetId: targetId,
        scheduledAt: scheduledAt,
        active: active,
      );
    }

    final option = target.options.firstWhere(
      (item) => item.id == targetId,
      orElse: () => ReminderOptionItem(id: targetId, label: target.label),
    );
    final localUuid = SyncUuid.v4();
    final localIntId = _localId(localUuid);
    final operationId = SyncUuid.v4();
    final now = DateTime.now().toIso8601String();
    final payload = _toPayload(
      targetType: target.key,
      targetServerId: targetId,
      scheduledAt: scheduledAt,
      active: active,
    );
    final item = _buildLocalItem(
      localUuid: localUuid,
      localIntId: localIntId,
      serverId: null,
      serverVersion: 0,
      syncStatus: SyncStatus.pendingCreate.wireName,
      targetType: target.key,
      targetServerId: targetId,
      title: option.label,
      targetLabel: target.label,
      scheduledAt: scheduledAt,
      active: active,
    );

    await AppDatabase.instance.transaction((txn) async {
      await txn.insert('reminder_local', {
        'local_uuid': localUuid,
        'local_int_id': localIntId,
        'user_id': userId,
        'server_id': null,
        'target_type': target.key,
        'target_server_id': targetId,
        'title': item.title,
        'target_label': item.targetLabel,
        'target_context': item.targetContext,
        'destination': item.destination,
        'active': active ? 1 : 0,
        'scheduled_at': scheduledAt.toIso8601String(),
        'scheduled_label': item.scheduledLabel,
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
        entityType: 'reminder',
        entityLocalUuid: localUuid,
        entityServerId: null,
        action: 'create',
        payload: payload,
        baseServerVersion: null,
      );
    });

    unawaited(const SyncService().pushPending(userId));
    unawaited(ReminderNotificationService.instance.schedule(item));
    state = state.copyWith(
      items: await _readLocalReminders(),
      clearError: true,
    );
    return true;
  }

  Future<bool> deleteReminder(int id) async {
    if (AppMode.uiOnly) {
      state = state.copyWith(
        items: state.items.where((item) => item.id != id).toList(),
      );
      unawaited(
        ReminderNotificationService.instance.cancelByIdentity(id: id),
      );
      return true;
    }

    if (userId <= 0) {
      return _deleteViaApi(id);
    }

    final row = await _findLocalRowById(id);
    if (row == null) {
      return false;
    }

    final reminderToCancel = _fromRow(row);
    final localUuid = row['local_uuid']?.toString() ?? '';
    final serverId = (row['server_id'] as num?)?.toInt();
    final serverVersion = (row['server_version'] as num?)?.toInt() ?? 0;
    final currentStatus =
        row['sync_status']?.toString() ?? SyncStatus.synced.wireName;
    final now = DateTime.now().toIso8601String();

    await AppDatabase.instance.transaction((txn) async {
      if (currentStatus == SyncStatus.pendingCreate.wireName) {
        await txn.delete(
          'reminder_local',
          where: 'local_uuid = ?',
          whereArgs: [localUuid],
        );
        await txn.delete(
          'sync_outbox',
          where: 'entity_local_uuid = ? AND entity_type = ?',
          whereArgs: [localUuid, 'reminder'],
        );
      } else {
        await txn.update(
          'reminder_local',
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
          entityType: 'reminder',
          entityLocalUuid: localUuid,
          entityServerId: serverId,
          action: 'delete',
          payload: const <String, dynamic>{},
          baseServerVersion: serverId == null ? null : serverVersion,
        );
      }
    });

    unawaited(const SyncService().pushPending(userId));
    unawaited(ReminderNotificationService.instance.cancel(reminderToCancel));
    state = state.copyWith(
      items: await _readLocalReminders(),
      clearError: true,
    );
    return true;
  }

  Future<String> testNotification() {
    return ReminderNotificationService.instance.showTestNotification();
  }

  Future<String> rescheduleNotifications() async {
    final items = userId > 0 ? await _readLocalReminders() : state.items;
    await ReminderNotificationService.instance.scheduleAll(items);
    final pendingCount =
        await ReminderNotificationService.instance.pendingCountOrZero();
    return 'Reminder dijadwalkan ulang. Pending notification: $pendingCount.';
  }

  Future<void> _loadFromApi() async {
    try {
      final response = await ApiClient.get('/reminder');
      if (response.statusCode != 200) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Gagal memuat daftar reminder.',
        );
        return;
      }

      final decoded = jsonDecode(response.body);
      final rawData = decoded is Map<String, dynamic> ? decoded['data'] : null;
      final items = rawData is List
          ? rawData
                .whereType<Map>()
                .map(
                  (row) =>
                      ReminderListItem.fromJson(Map<String, dynamic>.from(row)),
                )
                .toList()
          : const <ReminderListItem>[];

      state = state.copyWith(isLoading: false, items: items, clearError: true);
      unawaited(ReminderNotificationService.instance.scheduleAll(items));
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Gagal memuat daftar reminder.',
      );
    }
  }

  Future<List<ReminderListItem>> _readLocalReminders() async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query(
      'reminder_local',
      where: 'user_id = ? AND deleted_locally = 0',
      whereArgs: [userId],
      orderBy: 'scheduled_at DESC, local_int_id DESC',
    );

    return rows.map(_fromRow).toList();
  }

  Future<List<ReminderTargetOption>> _readLocalOptions() async {
    final db = await AppDatabase.instance.database;
    final todoRows = await db.query(
      'todo_local',
      columns: ['server_id', 'title'],
      where: 'user_id = ? AND deleted_locally = 0 AND server_id IS NOT NULL',
      whereArgs: [userId],
      orderBy: 'title ASC',
    );
    final jadwalRows = await db.query(
      'jadwal_local',
      columns: ['server_id', 'title', 'start_at'],
      where: 'user_id = ? AND deleted_locally = 0 AND server_id IS NOT NULL',
      whereArgs: [userId],
      orderBy: 'start_at ASC',
    );

    return [
      ReminderTargetOption(
        key: 'todolist',
        label: 'To-Do',
        helper: 'Kirim pengingat dari tugas dalam daftar kegiatan sehari-hari.',
        options: todoRows
            .map(
              (row) => ReminderOptionItem(
                id: (row['server_id'] as num?)?.toInt() ?? 0,
                label: row['title']?.toString() ?? 'To-Do',
              ),
            )
            .where((item) => item.id > 0)
            .toList(),
      ),
      ReminderTargetOption(
        key: 'jadwal',
        label: 'Agenda Kuliah',
        helper: 'Ingatkan agenda penting dari kalender jadwal.',
        options: jadwalRows
            .map(
              (row) => ReminderOptionItem(
                id: (row['server_id'] as num?)?.toInt() ?? 0,
                label: _jadwalOptionLabel(row),
              ),
            )
            .where((item) => item.id > 0)
            .toList(),
      ),
    ];
  }

  Future<List<ReminderTargetOption>> _loadOptionsFromApi() async {
    final response = await ApiClient.get('/reminder/options');
    if (response.statusCode != 200) {
      return const <ReminderTargetOption>[];
    }

    final decoded = jsonDecode(response.body);
    final rawData = decoded is Map<String, dynamic> ? decoded['data'] : null;
    final rawTargets = rawData is Map<String, dynamic>
        ? rawData['targets']
        : null;

    return rawTargets is List
        ? rawTargets
              .whereType<Map>()
              .map(
                (item) => ReminderTargetOption.fromJson(
                  Map<String, dynamic>.from(item),
                ),
              )
              .toList()
        : const <ReminderTargetOption>[];
  }

  Future<bool> _createViaApi({
    required ReminderTargetOption target,
    required int targetId,
    required DateTime scheduledAt,
    required bool active,
  }) async {
    try {
      final response = await ApiClient.post(
        '/reminder',
        _toPayload(
          targetType: target.key,
          targetServerId: targetId,
          scheduledAt: scheduledAt,
          active: active,
        ),
      );
      if (response.statusCode != 201) {
        state = state.copyWith(errorMessage: 'Gagal menyimpan reminder.');
        return false;
      }

      await load();
      return true;
    } catch (_) {
      state = state.copyWith(errorMessage: 'Gagal menyimpan reminder.');
      return false;
    }
  }

  Future<bool> _deleteViaApi(int id) async {
    try {
      final response = await ApiClient.delete('/reminder/$id');
      if (response.statusCode != 200) {
        state = state.copyWith(errorMessage: 'Gagal menghapus reminder.');
        return false;
      }

      state = state.copyWith(
        items: state.items.where((item) => item.id != id).toList(),
        clearError: true,
      );
      unawaited(
        ReminderNotificationService.instance.cancelByIdentity(id: id),
      );
      return true;
    } catch (_) {
      state = state.copyWith(errorMessage: 'Gagal menghapus reminder.');
      return false;
    }
  }

  Future<Map<String, Object?>?> _findLocalRowById(int id) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query(
      'reminder_local',
      where: 'user_id = ? AND (server_id = ? OR local_int_id = ?)',
      whereArgs: [userId, id, id],
      limit: 1,
    );

    return rows.isEmpty ? null : rows.first;
  }

  ReminderListItem _fromRow(Map<String, Object?> row) {
    final localUuid = row['local_uuid']?.toString() ?? '';
    final serverId = (row['server_id'] as num?)?.toInt();
    final scheduledAt = DateTime.tryParse(
      row['scheduled_at']?.toString() ?? '',
    );

    return ReminderListItem(
      id:
          serverId ??
          (row['local_int_id'] as num?)?.toInt() ??
          _localId(localUuid),
      localUuid: localUuid,
      serverId: serverId,
      serverVersion: (row['server_version'] as num?)?.toInt() ?? 0,
      syncStatus: row['sync_status']?.toString() ?? SyncStatus.synced.wireName,
      title: row['title']?.toString() ?? 'Reminder',
      targetType: row['target_type']?.toString() ?? 'todolist',
      targetLabel: row['target_label']?.toString() ?? 'Reminder',
      targetContext: row['target_context']?.toString() ?? '',
      destination: row['destination']?.toString() ?? 'todo',
      active: (row['active'] as num?)?.toInt() == 1,
      scheduledAt: scheduledAt,
      scheduledLabel:
          row['scheduled_label']?.toString() ??
          (scheduledAt == null ? '' : _scheduledLabel(scheduledAt)),
    );
  }

  ReminderListItem _buildLocalItem({
    required String localUuid,
    required int localIntId,
    required int? serverId,
    required int serverVersion,
    required String syncStatus,
    required String targetType,
    required int targetServerId,
    required String title,
    required String targetLabel,
    required DateTime scheduledAt,
    required bool active,
  }) {
    final destination = _destinationForTarget(targetType);
    return ReminderListItem(
      id: serverId ?? localIntId,
      localUuid: localUuid,
      serverId: serverId,
      serverVersion: serverVersion,
      syncStatus: syncStatus,
      title: title,
      targetType: targetType,
      targetLabel: targetLabel,
      targetContext: '$targetLabel: $title',
      destination: destination,
      active: active,
      scheduledAt: scheduledAt,
      scheduledLabel: _scheduledLabel(scheduledAt),
    );
  }

  Map<String, dynamic> _toPayload({
    required String targetType,
    required int targetServerId,
    required DateTime scheduledAt,
    required bool active,
  }) {
    final payload = <String, dynamic>{
      'reminder_target': targetType,
      '${targetType}_id': targetServerId,
      'waktu_reminder': scheduledAt.toIso8601String(),
    };
    if (active) {
      payload['aktif'] = true;
    }

    return payload;
  }

  String _destinationForTarget(String targetType) {
    return targetType == 'jadwal' || targetType == 'kegiatan'
        ? 'jadwal'
        : 'todo';
  }

  String _scheduledLabel(DateTime date) {
    return DateFormat("EEEE, dd MMMM yyyy - HH:mm", 'id_ID').format(date);
  }

  String _jadwalOptionLabel(Map<String, Object?> row) {
    final title = row['title']?.toString().trim() ?? '';
    final startAt = DateTime.tryParse(row['start_at']?.toString() ?? '');
    if (startAt == null) {
      return title.isEmpty ? 'Agenda' : title;
    }

    final suffix = DateFormat('dd MMM', 'id_ID').format(startAt);
    return title.isEmpty ? 'Agenda - $suffix' : '$title - $suffix';
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
}

final reminderListProvider =
    StateNotifierProvider<ReminderListNotifier, ReminderListState>((ref) {
      final user = ref.watch(userProvider);
      return ReminderListNotifier(userId: user?.id ?? 0);
    });
