import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_ver/core/config/app_mode.dart';
import 'package:mobile_ver/core/database/app_database.dart';
import 'package:mobile_ver/core/network/api_client.dart';
import 'package:mobile_ver/core/security/local_data_crypto.dart';
import 'package:mobile_ver/core/sync/sync_models.dart';
import 'package:mobile_ver/core/sync/sync_service.dart';
import 'package:mobile_ver/core/sync/sync_uuid.dart';
import 'package:mobile_ver/features/auth/providers/auth_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../models/catatan_model.dart';

class CatatanNotifier extends StateNotifier<AsyncValue<List<Catatan>>> {
  CatatanNotifier({required this.userId}) : super(const AsyncValue.loading()) {
    fetchCatatan();
  }

  final int userId;

  static final List<Catatan> _mockSeed = [
    Catatan(
      id: 1,
      judul: 'Materi Web',
      isi: 'Ringkasan HTML, CSS, JavaScript untuk latihan minggu ini.',
      previewIsi: 'Ringkasan HTML, CSS, JavaScript untuk latihan minggu ini.',
      showPreview: true,
      hasFullIsi: true,
      tanggal: '2026-02-28',
      statusSampah: false,
    ),
    Catatan(
      id: 2,
      judul: 'To-Do UTS',
      isi: 'Revisi catatan kuliah, latihan soal, dan cek jadwal ujian.',
      previewIsi: 'Revisi catatan kuliah, latihan soal, dan cek jadwal ujian.',
      showPreview: true,
      hasFullIsi: true,
      tanggal: '2026-02-27',
      statusSampah: false,
    ),
  ];

  Future<bool> fetchCatatan({bool showLoader = true}) async {
    if (AppMode.uiOnly) {
      state = AsyncValue.data(List<Catatan>.from(_mockSeed));
      return true;
    }

    if (userId > 0) {
      final previous = state.valueOrNull;
      if (showLoader || previous == null) {
        state = const AsyncValue.loading();
      }

      try {
        unawaited(const SyncService().syncNow(userId));
        state = AsyncValue.data(await _readLocalCatatan());
        return true;
      } catch (e, st) {
        if (previous != null && !showLoader) {
          return false;
        }
        state = AsyncValue.error(e, st);
        return false;
      }
    }

    final previous = state.valueOrNull;
    if (showLoader || previous == null) {
      state = const AsyncValue.loading();
    }

    try {
      final activeResponse = await ApiClient.get('/catatan?per_page=100');
      final trashResponse = await ApiClient.get('/catatan/trash?per_page=100');

      if (activeResponse.statusCode != 200 || trashResponse.statusCode != 200) {
        if (previous != null && !showLoader) {
          return false;
        }
        state = AsyncValue.error('Failed to load catatan', StackTrace.current);
        return false;
      }

      final activeList = _parseCatatanList(activeResponse.body);
      final trashList = _parseCatatanList(trashResponse.body);

      final mergedById = <int, Catatan>{
        for (final row in activeList) row.id: row.copyWith(statusSampah: false),
        for (final row in trashList) row.id: row.copyWith(statusSampah: true),
      };

      final merged = mergedById.values.toList()
        ..sort((a, b) {
          final byDate = b.tanggalAsDate.compareTo(a.tanggalAsDate);
          if (byDate != 0) return byDate;
          return b.id.compareTo(a.id);
        });

      state = AsyncValue.data(merged);
      return true;
    } catch (e, st) {
      if (previous != null && !showLoader) {
        return false;
      }
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> createCatatan(
    String judul,
    String isi,
    String tanggal,
    bool showPreview,
  ) async {
    if (AppMode.uiOnly) {
      final current = state.value ?? <Catatan>[];
      final nextId = current.isEmpty
          ? 1
          : current.map((e) => e.id).reduce((a, b) => a > b ? a : b) + 1;
      final newItem = Catatan(
        id: nextId,
        judul: judul,
        isi: isi,
        previewIsi: showPreview ? _preview(isi) : '',
        showPreview: showPreview,
        hasFullIsi: true,
        tanggal: tanggal,
        statusSampah: false,
      );
      state = AsyncValue.data([newItem, ...current]);
      return true;
    }

    try {
      if (userId > 0) {
        await _upsertLocalCatatan(
          id: null,
          judul: judul,
          isi: isi,
          tanggal: tanggal,
          showPreview: showPreview,
          statusSampah: false,
          action: 'create',
        );
        await fetchCatatan(showLoader: false);
        return true;
      }

      final response = await ApiClient.post('/catatan', {
        'judul': judul,
        'isi': isi,
        'show_preview': showPreview,
        'tanggal': tanggal,
      });
      if (response.statusCode == 201) {
        return fetchCatatan(showLoader: false);
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> updateCatatan(
    int id,
    String judul,
    String isi,
    String tanggal,
    bool showPreview,
  ) async {
    if (AppMode.uiOnly) {
      final current = state.value ?? <Catatan>[];
      final updated = current
          .map(
            (item) => item.id == id
                ? Catatan(
                    id: item.id,
                    judul: judul,
                    isi: isi,
                    previewIsi: showPreview ? _preview(isi) : '',
                    showPreview: showPreview,
                    hasFullIsi: true,
                    tanggal: tanggal,
                    statusSampah: item.statusSampah,
                  )
                : item,
          )
          .toList();
      state = AsyncValue.data(updated);
      return true;
    }

    try {
      if (userId > 0) {
        await _upsertLocalCatatan(
          id: id,
          judul: judul,
          isi: isi,
          tanggal: tanggal,
          showPreview: showPreview,
          statusSampah: null,
          action: 'update',
        );
        await fetchCatatan(showLoader: false);
        return true;
      }

      final response = await ApiClient.put('/catatan/$id', {
        'judul': judul,
        'isi': isi,
        'show_preview': showPreview,
        'tanggal': tanggal,
      });
      if (response.statusCode == 200) {
        return fetchCatatan(showLoader: false);
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deleteCatatan(int id) async {
    if (AppMode.uiOnly) {
      final current = state.value ?? <Catatan>[];
      final next = current
          .map(
            (item) => item.id == id ? item.copyWith(statusSampah: true) : item,
          )
          .toList();
      state = AsyncValue.data(next);
      return true;
    }

    try {
      if (userId > 0) {
        final row = await _findLocalRow(id);
        if (row == null) return false;
        await _markTrashState(row, true);
        await fetchCatatan(showLoader: false);
        return true;
      }

      final response = await ApiClient.delete('/catatan/$id');
      if (response.statusCode == 200) {
        return fetchCatatan(showLoader: false);
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> restoreCatatan(int id) async {
    if (AppMode.uiOnly) {
      final current = state.value ?? <Catatan>[];
      final next = current
          .map(
            (item) => item.id == id ? item.copyWith(statusSampah: false) : item,
          )
          .toList();
      state = AsyncValue.data(next);
      return true;
    }

    try {
      if (userId > 0) {
        final row = await _findLocalRow(id);
        if (row == null) return false;
        await _markTrashState(row, false);
        await fetchCatatan(showLoader: false);
        return true;
      }

      final response = await ApiClient.patch('/catatan/$id/restore', {});
      if (response.statusCode == 200) {
        return fetchCatatan(showLoader: false);
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> forceDeleteCatatan(int id) async {
    if (AppMode.uiOnly) {
      final current = state.value ?? <Catatan>[];
      state = AsyncValue.data(current.where((item) => item.id != id).toList());
      return true;
    }

    try {
      if (userId > 0) {
        final row = await _findLocalRow(id);
        if (row == null) return false;
        await _deleteLocal(row);
        await fetchCatatan(showLoader: false);
        return true;
      }

      final response = await ApiClient.delete('/catatan/$id/force-delete');
      if (response.statusCode == 200) {
        return fetchCatatan(showLoader: false);
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<Catatan?> fetchCatatanDetail(int id) async {
    final current = state.valueOrNull;

    if (AppMode.uiOnly) {
      try {
        return current?.firstWhere((item) => item.id == id);
      } catch (_) {
        return null;
      }
    }

    if (userId > 0) {
      try {
        return current?.firstWhere((item) => item.id == id);
      } catch (_) {
        final row = await _findLocalRow(id);
        return row == null ? null : await _fromLocalRow(row);
      }
    }

    try {
      final response = await ApiClient.get('/catatan/$id');
      if (response.statusCode != 200) {
        return null;
      }

      final item = _parseCatatanItem(response.body);
      if (item == null) {
        return null;
      }

      if (current != null) {
        final updated = current
            .map((row) => row.id == item.id ? item : row)
            .toList();
        state = AsyncValue.data(updated);
      }

      return item;
    } catch (_) {
      return null;
    }
  }

  List<Catatan> _parseCatatanList(String rawBody) {
    final decoded = jsonDecode(rawBody);
    if (decoded is! Map<String, dynamic>) return const <Catatan>[];

    final rawData = decoded['data'];
    if (rawData is! List) return const <Catatan>[];

    return rawData
        .whereType<Map>()
        .map((row) => Catatan.fromJson(Map<String, dynamic>.from(row)))
        .toList();
  }

  Catatan? _parseCatatanItem(String rawBody) {
    final decoded = jsonDecode(rawBody);
    if (decoded is! Map<String, dynamic>) return null;

    final rawData = decoded['data'];
    if (rawData is! Map) return null;

    return Catatan.fromJson(Map<String, dynamic>.from(rawData));
  }

  Future<List<Catatan>> _readLocalCatatan() async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query(
      'catatan_local',
      where: 'user_id = ? AND deleted_locally = 0',
      whereArgs: [userId],
      orderBy: 'tanggal DESC, local_int_id DESC',
    );

    final items = <Catatan>[];
    for (final row in rows) {
      items.add(await _fromLocalRow(row));
    }

    return items;
  }

  Future<void> _upsertLocalCatatan({
    required int? id,
    required String judul,
    required String isi,
    required String tanggal,
    required bool? showPreview,
    required bool? statusSampah,
    required String action,
  }) async {
    final existing = id == null ? null : await _findLocalRow(id);
    final localUuid = existing?['local_uuid']?.toString() ?? SyncUuid.v4();
    final localIntId = existing == null
        ? _localId(localUuid)
        : (existing['local_int_id'] as num?)?.toInt() ?? _localId(localUuid);
    final serverId = (existing?['server_id'] as num?)?.toInt();
    final serverVersion = (existing?['server_version'] as num?)?.toInt() ?? 0;
    final currentStatus =
        existing?['sync_status']?.toString() ?? SyncStatus.synced.wireName;
    final nextStatus =
        currentStatus == SyncStatus.pendingCreate.wireName || action == 'create'
        ? SyncStatus.pendingCreate.wireName
        : SyncStatus.pendingUpdate.wireName;
    final now = DateTime.now().toIso8601String();
    final nextTrash =
        statusSampah ?? ((existing?['status_sampah'] as num?)?.toInt() == 1);
    final nextShowPreview =
        showPreview ?? ((existing?['show_preview'] as num?)?.toInt() == 1);
    final payload = {
      'judul': judul.trim(),
      'isi': isi,
      'show_preview': nextShowPreview,
      'tanggal': tanggal,
      'status_sampah': nextTrash,
    };
    final encryptedIsi = await LocalDataCrypto.encryptString(userId, isi);
    final encryptedPreview = await LocalDataCrypto.encryptString(
      userId,
      nextShowPreview ? _preview(isi) : '',
    );
    final encryptedPayload = await LocalDataCrypto.encryptString(
      userId,
      jsonEncode(payload),
    );

    await AppDatabase.instance.transaction((txn) async {
      await txn.insert('catatan_local', {
        'local_uuid': localUuid,
        'local_int_id': localIntId,
        'user_id': userId,
        'server_id': serverId,
        'judul': judul.trim(),
        'isi': encryptedIsi,
        'preview_isi': encryptedPreview,
        'show_preview': nextShowPreview ? 1 : 0,
        'has_full_isi': 1,
        'tanggal': tanggal,
        'status_sampah': nextTrash ? 1 : 0,
        'server_version': serverVersion,
        'sync_status': nextStatus,
        'deleted_locally': 0,
        'created_at': existing?['created_at']?.toString() ?? now,
        'updated_at': now,
        'dirty_at': now,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
      if (currentStatus == SyncStatus.pendingCreate.wireName &&
          action != 'create') {
        await txn.update(
          'sync_outbox',
          {
            'payload_json': encryptedPayload,
            'updated_at': now,
            'status': 'pending',
          },
          where: 'entity_local_uuid = ? AND entity_type = ? AND action = ?',
          whereArgs: [localUuid, 'catatan', 'create'],
        );
      } else {
        await SyncService.enqueue(
          txn,
          operationId: SyncUuid.v4(),
          userId: userId,
          entityType: 'catatan',
          entityLocalUuid: localUuid,
          entityServerId: serverId,
          action:
              currentStatus == SyncStatus.pendingCreate.wireName ||
                  action == 'create'
              ? 'create'
              : 'update',
          payload: payload,
          baseServerVersion: serverId == null ? null : serverVersion,
        );
      }
    });

    unawaited(const SyncService().pushPending(userId));
  }

  Future<void> _markTrashState(
    Map<String, Object?> row,
    bool statusSampah,
  ) async {
    await _upsertLocalCatatan(
      id:
          (row['server_id'] as num?)?.toInt() ??
          (row['local_int_id'] as num?)?.toInt(),
      judul: row['judul']?.toString() ?? '',
      isi: await _decryptLocalField(row, 'isi'),
      tanggal: row['tanggal']?.toString() ?? '',
      showPreview: (row['show_preview'] as num?)?.toInt() == 1,
      statusSampah: statusSampah,
      action: 'update',
    );
  }

  Future<void> _deleteLocal(Map<String, Object?> row) async {
    final localUuid = row['local_uuid']?.toString() ?? '';
    final serverId = (row['server_id'] as num?)?.toInt();
    final serverVersion = (row['server_version'] as num?)?.toInt() ?? 0;
    final currentStatus =
        row['sync_status']?.toString() ?? SyncStatus.synced.wireName;
    final now = DateTime.now().toIso8601String();

    await AppDatabase.instance.transaction((txn) async {
      if (currentStatus == SyncStatus.pendingCreate.wireName) {
        await txn.delete(
          'catatan_local',
          where: 'local_uuid = ?',
          whereArgs: [localUuid],
        );
        await txn.delete(
          'sync_outbox',
          where: 'entity_local_uuid = ? AND entity_type = ?',
          whereArgs: [localUuid, 'catatan'],
        );
      } else {
        await txn.update(
          'catatan_local',
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
          entityType: 'catatan',
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

  Future<Map<String, Object?>?> _findLocalRow(int id) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query(
      'catatan_local',
      where: 'user_id = ? AND (server_id = ? OR local_int_id = ?)',
      whereArgs: [userId, id, id],
      limit: 1,
    );
    return rows.isEmpty ? null : rows.first;
  }

  Future<Catatan> _fromLocalRow(Map<String, Object?> row) async {
    final localUuid = row['local_uuid']?.toString() ?? '';
    final serverId = (row['server_id'] as num?)?.toInt();
    final isi = await _decryptLocalField(row, 'isi');
    final previewIsi = await _decryptLocalField(row, 'preview_isi');

    return Catatan(
      id:
          serverId ??
          (row['local_int_id'] as num?)?.toInt() ??
          _localId(localUuid),
      localUuid: localUuid,
      serverId: serverId,
      serverVersion: (row['server_version'] as num?)?.toInt() ?? 0,
      syncStatus: row['sync_status']?.toString() ?? SyncStatus.synced.wireName,
      judul: row['judul']?.toString() ?? '',
      isi: isi,
      previewIsi: previewIsi,
      showPreview: (row['show_preview'] as num?)?.toInt() == 1,
      hasFullIsi: row['has_full_isi'] == 1,
      tanggal: row['tanggal']?.toString() ?? '',
      statusSampah: row['status_sampah'] == 1,
      createdAt: DateTime.tryParse(row['created_at']?.toString() ?? ''),
      updatedAt: DateTime.tryParse(row['updated_at']?.toString() ?? ''),
    );
  }

  Future<String> _decryptLocalField(
    Map<String, Object?> row,
    String field,
  ) async {
    final rawValue = row[field]?.toString() ?? '';
    final decrypted = await LocalDataCrypto.tryDecryptString(userId, rawValue);

    return decrypted ?? '';
  }

  String _preview(String value) {
    final normalized = value.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (normalized.length <= 97) return normalized;
    return normalized.substring(0, 97);
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

final catatanProvider =
    StateNotifierProvider<CatatanNotifier, AsyncValue<List<Catatan>>>((ref) {
      final user = ref.watch(userProvider);
      return CatatanNotifier(userId: user?.id ?? 0);
    });
