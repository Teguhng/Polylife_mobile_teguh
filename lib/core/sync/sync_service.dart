import 'dart:convert';

import 'package:mobile_ver/core/database/app_database.dart';
import 'package:mobile_ver/core/network/api_client.dart';
import 'package:mobile_ver/core/security/local_data_crypto.dart';
import 'package:mobile_ver/core/sync/sync_models.dart';
import 'package:sqflite/sqflite.dart';

class SyncService {
  const SyncService();

  static const String _cursorKey = 'sync_cursor';
  static const int _pushBatchSize = 25;

  Future<void> syncNow(int userId) async {
    await pushPending(userId);
    await pullChanges(userId);
  }

  Future<void> pushPending(int userId) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query(
      'sync_outbox',
      where: 'user_id = ? AND status IN (?, ?)',
      whereArgs: [userId, 'pending', 'failed'],
      orderBy: 'created_at ASC',
      limit: _pushBatchSize,
    );

    if (rows.isEmpty) {
      return;
    }

    final operations = <SyncOutboxOperation>[];
    for (final row in rows) {
      final operation = await _outboxFromRow(row);
      if (operation == null) {
        await _markBatch(
          [row],
          'failed',
          'Cache lokal terenkripsi tidak bisa dibuka.',
        );
        continue;
      }
      operations.add(operation);
    }

    if (operations.isEmpty) {
      return;
    }

    try {
      final response = await ApiClient.post('/sync/push', {
        'operations': operations.map((item) => item.toApiPayload()).toList(),
      });

      if (response.statusCode == 401 || response.statusCode == 403) {
        await _markBatch(rows, 'auth_required', 'Sesi perlu login ulang.');
        return;
      }

      if (response.statusCode != 200) {
        await _markBatch(rows, 'failed', 'Server menolak sinkronisasi.');
        return;
      }

      final decoded = _decodeMap(response.body);
      final rawOps = decoded['data'] is Map
          ? decoded['data']['operations']
          : null;
      final results = rawOps is List
          ? rawOps.whereType<Map>().toList()
          : const <Map>[];

      await AppDatabase.instance.transaction((txn) async {
        for (final rawResult in results) {
          final result = Map<String, dynamic>.from(rawResult);
          final operationId = result['operation_id']?.toString();
          if (operationId == null || operationId.isEmpty) {
            continue;
          }

          final status = result['status']?.toString() ?? 'failed';
          if (status == 'synced') {
            final rawRecord = result['record'];
            final entityType = result['entity_type']?.toString() ?? '';
            if (rawRecord is Map) {
              await _applyServerRecord(
                txn,
                userId,
                entityType,
                Map<String, dynamic>.from(rawRecord),
                force: true,
              );
            }
            await txn.delete(
              'sync_outbox',
              where: 'operation_id = ?',
              whereArgs: [operationId],
            );
          } else if (status == 'conflict') {
            await _markOperationInTransaction(
              txn,
              operationId,
              'conflict',
              result['error'] is Map
                  ? result['error']['message']?.toString()
                  : 'Konflik data.',
            );
            await _markEntityConflict(txn, result);
          } else {
            await _markOperationInTransaction(
              txn,
              operationId,
              'failed',
              result['error'] is Map
                  ? result['error']['message']?.toString()
                  : 'Sync gagal.',
            );
          }
        }
      });
    } catch (_) {
      await _markBatch(rows, 'failed', 'Koneksi belum tersedia.');
    }
  }

  Future<void> pullChanges(int userId) async {
    final db = await AppDatabase.instance.database;
    final cursor = await _readCursor(db);

    try {
      final response = await ApiClient.get(
        '/sync/pull?cursor=${Uri.encodeQueryComponent(cursor)}',
      );
      if (response.statusCode != 200) {
        return;
      }

      final decoded = _decodeMap(response.body);
      final rawData = decoded['data'];
      if (rawData is! Map) {
        return;
      }

      final data = Map<String, dynamic>.from(rawData);
      final rawEntities = data['entities'];
      if (rawEntities is! Map) {
        return;
      }

      await AppDatabase.instance.transaction((txn) async {
        for (final entry in rawEntities.entries) {
          final entityType = entry.key.toString();
          final rows = entry.value is List ? entry.value as List : const [];
          for (final rawRow in rows.whereType<Map>()) {
            await _applyServerRecord(
              txn,
              userId,
              entityType,
              Map<String, dynamic>.from(rawRow),
            );
          }
        }

        final nextCursor = data['cursor']?.toString();
        if (nextCursor != null && nextCursor.isNotEmpty) {
          await txn.insert('sync_metadata', {
            'key': _cursorKey,
            'value': nextCursor,
          }, conflictAlgorithm: ConflictAlgorithm.replace);
        }
      });
    } catch (_) {
      return;
    }
  }

  static Future<void> enqueue(
    Transaction txn, {
    required String operationId,
    required int userId,
    required String entityType,
    required String entityLocalUuid,
    required int? entityServerId,
    required String action,
    required Map<String, dynamic> payload,
    required int? baseServerVersion,
  }) async {
    final now = DateTime.now().toIso8601String();
    final payloadJson = entityType == 'catatan'
        ? await LocalDataCrypto.encryptString(userId, jsonEncode(payload))
        : jsonEncode(payload);

    await txn.insert('sync_outbox', {
      'operation_id': operationId,
      'user_id': userId,
      'entity_type': entityType,
      'entity_local_uuid': entityLocalUuid,
      'entity_server_id': entityServerId,
      'action': action,
      'payload_json': payloadJson,
      'base_server_version': baseServerVersion,
      'status': 'pending',
      'attempt_count': 0,
      'schema_version': 1,
      'created_at': now,
      'updated_at': now,
    });
  }

  Future<String> _readCursor(Database db) async {
    final rows = await db.query(
      'sync_metadata',
      columns: ['value'],
      where: 'key = ?',
      whereArgs: [_cursorKey],
      limit: 1,
    );

    if (rows.isEmpty) {
      return '1970-01-01T00:00:00Z';
    }

    return rows.first['value']?.toString() ?? '1970-01-01T00:00:00Z';
  }

  Future<void> _markBatch(
    List<Map<String, Object?>> rows,
    String status,
    String message,
  ) async {
    final db = await AppDatabase.instance.database;
    final now = DateTime.now().toIso8601String();
    final ids = rows
        .map((row) => row['operation_id']?.toString())
        .whereType<String>()
        .toList();
    if (ids.isEmpty) {
      return;
    }

    await db.update(
      'sync_outbox',
      {'status': status, 'updated_at': now, 'error_message': message},
      where: 'operation_id IN (${List.filled(ids.length, '?').join(',')})',
      whereArgs: ids,
    );

    for (final id in ids) {
      await db.rawUpdate(
        'UPDATE sync_outbox SET attempt_count = attempt_count + 1 WHERE operation_id = ?',
        [id],
      );
    }
  }

  Future<void> _markOperationInTransaction(
    Transaction txn,
    String operationId,
    String status,
    String? message,
  ) async {
    await txn.rawUpdate(
      '''
      UPDATE sync_outbox
      SET status = ?, attempt_count = attempt_count + 1, updated_at = ?, error_message = ?
      WHERE operation_id = ?
      ''',
      [status, DateTime.now().toIso8601String(), message, operationId],
    );
  }

  Future<void> _markEntityConflict(
    Transaction txn,
    Map<String, dynamic> result,
  ) async {
    final entityType = result['entity_type']?.toString() ?? '';
    final localUuid = result['client_uuid']?.toString() ?? '';
    final table = _tableForEntity(entityType);
    if (table == null || localUuid.isEmpty) {
      return;
    }

    await txn.update(
      table,
      {'sync_status': SyncStatus.conflict.wireName},
      where: 'local_uuid = ?',
      whereArgs: [localUuid],
    );
  }

  Future<void> _applyServerRecord(
    Transaction txn,
    int userId,
    String entityType,
    Map<String, dynamic> record, {
    bool force = false,
  }) async {
    final table = _tableForEntity(entityType);
    if (table == null) {
      return;
    }

    final localUuid = record['sync_uuid']?.toString();
    if (localUuid == null || localUuid.isEmpty) {
      return;
    }

    final existing = await txn.query(
      table,
      where: 'local_uuid = ?',
      whereArgs: [localUuid],
      limit: 1,
    );

    if (!force && existing.isNotEmpty) {
      final status = existing.first['sync_status']?.toString();
      if (status != null && status != SyncStatus.synced.wireName) {
        return;
      }
    }

    final row = await _localRowFromServer(entityType, userId, record);
    if (row == null) {
      return;
    }

    await txn.insert(table, row, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<SyncOutboxOperation?> _outboxFromRow(Map<String, Object?> row) async {
    final entityType = row['entity_type']?.toString() ?? '';
    final userId = (row['user_id'] as num?)?.toInt() ?? 0;
    final payloadJson = row['payload_json']?.toString() ?? '{}';
    final decodedPayload = await _decodePayload(
      userId: userId,
      entityType: entityType,
      payloadJson: payloadJson,
    );
    if (decodedPayload == null) {
      return null;
    }

    return SyncOutboxOperation(
      operationId: row['operation_id']?.toString() ?? '',
      userId: userId,
      entityType: entityType,
      entityLocalUuid: row['entity_local_uuid']?.toString() ?? '',
      entityServerId: (row['entity_server_id'] as num?)?.toInt(),
      action: row['action']?.toString() ?? '',
      payload: decodedPayload,
      baseServerVersion: (row['base_server_version'] as num?)?.toInt(),
      status: row['status']?.toString() ?? 'pending',
      attemptCount: (row['attempt_count'] as num?)?.toInt() ?? 0,
    );
  }

  Future<Map<String, dynamic>?> _localRowFromServer(
    String entityType,
    int userId,
    Map<String, dynamic> json,
  ) async {
    final deleted = (json['deleted_at']?.toString() ?? '').isNotEmpty;
    final base = <String, dynamic>{
      'local_uuid': json['sync_uuid']?.toString() ?? '',
      'local_int_id': _toInt(json['id']) > 0
          ? _toInt(json['id'])
          : _localIntId(json['sync_uuid']?.toString() ?? ''),
      'user_id': userId,
      'server_id': _toInt(json['id']),
      'server_version': _toInt(json['server_version'], fallback: 1),
      'sync_status': SyncStatus.synced.wireName,
      'deleted_locally': deleted ? 1 : 0,
      'created_at': json['created_at']?.toString(),
      'updated_at': json['updated_at']?.toString(),
      'dirty_at': null,
    };

    switch (entityType) {
      case 'catatan':
        final showPreview = _toBool(json['show_preview']);
        final preview = json['preview_isi']?.toString() ?? '';
        return {
          ...base,
          'judul': json['judul']?.toString() ?? '',
          'isi': await LocalDataCrypto.encryptString(
            userId,
            json['isi']?.toString() ?? '',
          ),
          'preview_isi': await LocalDataCrypto.encryptString(
            userId,
            showPreview ? preview : '',
          ),
          'show_preview': showPreview ? 1 : 0,
          'has_full_isi': _toBool(json['has_full_isi']) ? 1 : 0,
          'tanggal': json['tanggal']?.toString() ?? '',
          'status_sampah': _toBool(json['status_sampah']) ? 1 : 0,
        };
      case 'keuangan':
        return {
          ...base,
          'jenis': json['jenis']?.toString() ?? 'pengeluaran',
          'kategori': json['kategori']?.toString() ?? '',
          'deskripsi': json['deskripsi']?.toString(),
          'nominal': _toDouble(json['nominal']),
          'tanggal': json['tanggal']?.toString() ?? '',
        };
      case 'todolist':
        final reminderAt = json['reminder_at']?.toString();
        return {
          ...base,
          'title': json['nama_item']?.toString() ?? '',
          'description': '',
          'completed': _toBool(json['status']) ? 1 : 0,
          'due_at': reminderAt == null || reminderAt.isEmpty
              ? null
              : reminderAt,
          'priority':
              _toBool(json['reminder_enabled']) || (reminderAt ?? '').isNotEmpty
              ? 'high'
              : 'normal',
        };
      case 'jadwal':
        return {
          ...base,
          'title': json['title']?.toString() ?? '',
          'type': json['type']?.toString() ?? 'personal',
          'start_at':
              json['start_at']?.toString() ?? DateTime.now().toIso8601String(),
          'end_at':
              json['end_at']?.toString() ??
              DateTime.now().add(const Duration(hours: 1)).toIso8601String(),
          'location': json['location']?.toString() ?? '',
          'notes': json['notes']?.toString() ?? '',
          'completed': _toBool(json['completed']) ? 1 : 0,
          'matkul_names_json': _encodeList(json['matkul_names']),
          'primary_matkul_json': _encodeNullableMap(json['primary_matkul']),
          'matkul_previews_json': _encodeList(json['matkul_previews']),
        };
      case 'reminder':
        final targetType = json['target_type']?.toString() ?? 'todolist';
        final serverId = _toInt(json['id']);
        return {
          ...base,
          'local_int_id': serverId > 0
              ? serverId
              : _localIntId(json['sync_uuid']?.toString() ?? ''),
          'target_type': targetType,
          'target_server_id': null,
          'title': json['title']?.toString() ?? 'Reminder',
          'target_label': json['target_label']?.toString() ?? 'Reminder',
          'target_context': json['target_context']?.toString() ?? '',
          'destination':
              json['destination']?.toString() ??
              (targetType == 'jadwal' || targetType == 'kegiatan'
                  ? 'jadwal'
                  : 'todo'),
          'active': _toBool(json['active']) ? 1 : 0,
          'scheduled_at': json['scheduled_at']?.toString(),
          'scheduled_label': json['scheduled_label']?.toString() ?? '',
        };
      default:
        return null;
    }
  }

  static String? _tableForEntity(String entityType) {
    switch (entityType) {
      case 'catatan':
        return 'catatan_local';
      case 'keuangan':
        return 'keuangan_local';
      case 'todolist':
        return 'todo_local';
      case 'jadwal':
        return 'jadwal_local';
      case 'reminder':
        return 'reminder_local';
      default:
        return null;
    }
  }

  static Map<String, dynamic> _decodeMap(String source) {
    try {
      final decoded = jsonDecode(source);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    } catch (_) {
      // fall through
    }
    return <String, dynamic>{};
  }

  static String _encodeList(Object? value) {
    if (value is List) {
      return jsonEncode(value);
    }

    return '[]';
  }

  static String? _encodeNullableMap(Object? value) {
    if (value is Map) {
      return jsonEncode(value);
    }

    return null;
  }

  Future<Map<String, dynamic>?> _decodePayload({
    required int userId,
    required String entityType,
    required String payloadJson,
  }) async {
    if (entityType != 'catatan') {
      return _decodeMap(payloadJson);
    }

    final decrypted = await LocalDataCrypto.tryDecryptString(
      userId,
      payloadJson,
    );
    if (decrypted == null) {
      return null;
    }

    return _decodeMap(decrypted);
  }

  static int _toInt(Object? value, {int fallback = 0}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse((value ?? '').toString()) ?? fallback;
  }

  static double _toDouble(Object? value) {
    if (value is num) return value.toDouble();
    return double.tryParse((value ?? '').toString()) ?? 0;
  }

  static bool _toBool(Object? value) {
    return value == true || value == 1 || value == '1' || value == 'true';
  }

  static int _localIntId(String value) {
    var hash = 0;
    for (final code in value.codeUnits) {
      hash = 0x1fffffff & (hash + code);
      hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
      hash ^= hash >> 6;
    }
    return -hash.abs();
  }
}
