import 'dart:async';
import 'dart:convert';

import 'package:mobile_ver/core/database/app_database.dart';
import 'package:mobile_ver/core/sync/sync_models.dart';
import 'package:mobile_ver/core/sync/sync_service.dart';
import 'package:mobile_ver/core/sync/sync_uuid.dart';
import 'package:mobile_ver/features/jadwal/models/jadwal_item.dart';
import 'package:mobile_ver/features/jadwal/repositories/jadwal_repository.dart';

class OfflineFirstJadwalRepository implements JadwalRepository {
  OfflineFirstJadwalRepository({required this.userId});

  final int userId;

  @override
  Future<List<JadwalItem>> fetchAll() async {
    if (userId <= 0) return const <JadwalItem>[];

    await const SyncService().syncNow(userId);
    final db = await AppDatabase.instance.database;
    final rows = await db.query(
      'jadwal_local',
      where: 'user_id = ? AND deleted_locally = 0',
      whereArgs: [userId],
      orderBy: 'start_at ASC, local_int_id ASC',
    );

    return rows.map(_fromRow).toList();
  }

  @override
  Future<JadwalItem> create(JadwalItem item) async {
    final localUuid = SyncUuid.v4();
    final localId = _localId(localUuid);
    final operationId = SyncUuid.v4();
    final now = DateTime.now().toIso8601String();

    await AppDatabase.instance.transaction((txn) async {
      await txn.insert('jadwal_local', {
        'local_uuid': localUuid,
        'local_int_id': localId,
        'user_id': userId,
        'server_id': null,
        'title': item.title.trim(),
        'type': _typeToApi(item.type),
        'start_at': item.startAt.toIso8601String(),
        'end_at': item.endAt.toIso8601String(),
        'location': item.location.trim(),
        'notes': item.notes.trim(),
        'completed': item.completed ? 1 : 0,
        'matkul_names_json': '[]',
        'primary_matkul_json': null,
        'matkul_previews_json': '[]',
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
        entityType: 'jadwal',
        entityLocalUuid: localUuid,
        entityServerId: null,
        action: 'create',
        payload: _toPayload(item),
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
  Future<JadwalItem> update(JadwalItem item) async {
    final row = await _findRow(item);
    if (row == null) throw Exception('Jadwal lokal tidak ditemukan');

    final localUuid = row['local_uuid']?.toString() ?? item.localUuid;
    final serverId = (row['server_id'] as num?)?.toInt();
    final serverVersion = (row['server_version'] as num?)?.toInt() ?? 0;
    final currentStatus =
        row['sync_status']?.toString() ?? SyncStatus.synced.wireName;
    final nextStatus = currentStatus == SyncStatus.pendingCreate.wireName
        ? SyncStatus.pendingCreate.wireName
        : SyncStatus.pendingUpdate.wireName;
    final now = DateTime.now().toIso8601String();

    await AppDatabase.instance.transaction((txn) async {
      await txn.update(
        'jadwal_local',
        {
          'title': item.title.trim(),
          'type': _typeToApi(item.type),
          'start_at': item.startAt.toIso8601String(),
          'end_at': item.endAt.toIso8601String(),
          'location': item.location.trim(),
          'notes': item.notes.trim(),
          'completed': item.completed ? 1 : 0,
          'sync_status': nextStatus,
          'updated_at': now,
          'dirty_at': now,
        },
        where: 'local_uuid = ?',
        whereArgs: [localUuid],
      );

      final payload = _toPayload(item);
      if (currentStatus == SyncStatus.pendingCreate.wireName) {
        await txn.update(
          'sync_outbox',
          {
            'payload_json': jsonEncode(payload),
            'updated_at': now,
            'status': 'pending',
          },
          where: 'entity_local_uuid = ? AND entity_type = ? AND action = ?',
          whereArgs: [localUuid, 'jadwal', 'create'],
        );
      } else {
        await SyncService.enqueue(
          txn,
          operationId: SyncUuid.v4(),
          userId: userId,
          entityType: 'jadwal',
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
    if (row == null) return;

    final localUuid = row['local_uuid']?.toString() ?? '';
    final serverId = (row['server_id'] as num?)?.toInt();
    final serverVersion = (row['server_version'] as num?)?.toInt() ?? 0;
    final currentStatus =
        row['sync_status']?.toString() ?? SyncStatus.synced.wireName;
    final now = DateTime.now().toIso8601String();

    await AppDatabase.instance.transaction((txn) async {
      if (currentStatus == SyncStatus.pendingCreate.wireName) {
        await txn.delete(
          'jadwal_local',
          where: 'local_uuid = ?',
          whereArgs: [localUuid],
        );
        await txn.delete(
          'sync_outbox',
          where: 'entity_local_uuid = ? AND entity_type = ?',
          whereArgs: [localUuid, 'jadwal'],
        );
      } else {
        await txn.update(
          'jadwal_local',
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
          entityType: 'jadwal',
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

  Future<Map<String, Object?>?> _findRow(JadwalItem item) async {
    if (item.localUuid.isNotEmpty) {
      final db = await AppDatabase.instance.database;
      final rows = await db.query(
        'jadwal_local',
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
      'jadwal_local',
      where: 'user_id = ? AND (server_id = ? OR local_int_id = ?)',
      whereArgs: [userId, id, id],
      limit: 1,
    );
    return rows.isEmpty ? null : rows.first;
  }

  JadwalItem _fromRow(Map<String, Object?> row) {
    final localUuid = row['local_uuid']?.toString() ?? '';
    final serverId = (row['server_id'] as num?)?.toInt();
    final startAt =
        DateTime.tryParse(row['start_at']?.toString() ?? '') ?? DateTime.now();
    var endAt =
        DateTime.tryParse(row['end_at']?.toString() ?? '') ??
        startAt.add(const Duration(hours: 1));
    if (!endAt.isAfter(startAt)) {
      endAt = startAt.add(const Duration(hours: 1));
    }
    final matkulPreviews = _parseMatkulPreviews(row['matkul_previews_json']);
    final primaryMatkul =
        _parsePrimaryMatkul(row['primary_matkul_json']) ??
        (matkulPreviews.isNotEmpty ? matkulPreviews.first : null);

    return JadwalItem(
      id: serverId ?? _localId(localUuid),
      localUuid: localUuid,
      serverId: serverId,
      serverVersion: (row['server_version'] as num?)?.toInt() ?? 0,
      syncStatus: row['sync_status']?.toString() ?? SyncStatus.synced.wireName,
      title: row['title']?.toString() ?? '',
      type: _typeFromApi(row['type']?.toString() ?? ''),
      startAt: startAt,
      endAt: endAt,
      location: row['location']?.toString() ?? '',
      notes: row['notes']?.toString() ?? '',
      completed: row['completed'] == 1,
      matkulNames: _parseMatkulNames(row['matkul_names_json']),
      primaryMatkul: primaryMatkul,
      matkulPreviews: matkulPreviews,
    );
  }

  Map<String, dynamic> _toPayload(JadwalItem item) {
    return {
      'title': item.title.trim(),
      'type': _typeToApi(item.type),
      'start_at': item.startAt.toIso8601String(),
      'end_at': item.endAt.toIso8601String(),
      'location': item.location.trim(),
      'notes': item.notes.trim(),
      'completed': item.completed,
    };
  }

  String _typeToApi(JadwalType type) {
    switch (type) {
      case JadwalType.kuliah:
        return 'kuliah';
      case JadwalType.tugas:
        return 'tugas';
      case JadwalType.ujian:
        return 'ujian';
      case JadwalType.rapat:
        return 'rapat';
      case JadwalType.personal:
        return 'personal';
    }
  }

  JadwalType _typeFromApi(String raw) {
    switch (raw.toLowerCase().trim()) {
      case 'kuliah':
        return JadwalType.kuliah;
      case 'tugas':
        return JadwalType.tugas;
      case 'ujian':
        return JadwalType.ujian;
      case 'rapat':
        return JadwalType.rapat;
      default:
        return JadwalType.personal;
    }
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

  List<String> _parseMatkulNames(Object? value) {
    final decoded = _decodeJson(value);
    if (decoded is! List) return const <String>[];

    return decoded
        .map((item) => item.toString().trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }

  JadwalMatkulPreview? _parsePrimaryMatkul(Object? value) {
    final decoded = _decodeJson(value);
    if (decoded is! Map) return null;

    return _parseMatkulPreview(Map<String, dynamic>.from(decoded));
  }

  List<JadwalMatkulPreview> _parseMatkulPreviews(Object? value) {
    final decoded = _decodeJson(value);
    if (decoded is! List) return const <JadwalMatkulPreview>[];

    return decoded
        .whereType<Map>()
        .map((row) => _parseMatkulPreview(Map<String, dynamic>.from(row)))
        .whereType<JadwalMatkulPreview>()
        .toList();
  }

  Object? _decodeJson(Object? value) {
    final raw = value?.toString() ?? '';
    if (raw.trim().isEmpty) return null;

    try {
      return jsonDecode(raw);
    } catch (_) {
      return null;
    }
  }

  JadwalMatkulPreview? _parseMatkulPreview(Map<String, dynamic> mapped) {
    final name = (mapped['nama'] ?? '').toString().trim();
    if (name.isEmpty) return null;

    final rawScheduleDays = mapped['schedule_days'];
    final scheduleDays = rawScheduleDays is List
        ? rawScheduleDays
              .map((value) => value.toString().trim().toLowerCase())
              .where((value) => value.isNotEmpty)
              .toList()
        : const <String>[];

    final rawScheduleEntries = mapped['schedule_entries'];
    final scheduleEntries = rawScheduleEntries is List
        ? rawScheduleEntries.whereType<Map>().map((row) {
            final entry = Map<String, dynamic>.from(row);
            return JadwalMatkulScheduleEntry(
              hari: _nullableText(entry['hari']),
              jamMulai: _nullableText(entry['jam_mulai']),
              jamSelesai: _nullableText(entry['jam_selesai']),
              ruangan: _nullableText(entry['ruangan']),
              kelas: _nullableText(entry['kelas']),
            );
          }).toList()
        : const <JadwalMatkulScheduleEntry>[];

    return JadwalMatkulPreview(
      id: int.tryParse((mapped['id'] ?? '').toString()),
      name: name,
      kelas: _nullableText(mapped['kelas']),
      ruangan: _nullableText(mapped['ruangan']),
      timeLabel: _nullableText(mapped['time_label']),
      warnaLabel: _nullableText(mapped['warna_label']),
      scheduleDays: scheduleDays,
      scheduleEntries: scheduleEntries,
    );
  }

  String? _nullableText(Object? value) {
    final text = (value ?? '').toString().trim();
    return text.isEmpty ? null : text;
  }
}
