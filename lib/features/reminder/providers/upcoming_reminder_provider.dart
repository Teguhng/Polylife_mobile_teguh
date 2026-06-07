import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_ver/core/config/app_mode.dart';
import 'package:mobile_ver/core/database/app_database.dart';
import 'package:mobile_ver/core/network/api_client.dart';
import 'package:mobile_ver/features/auth/providers/auth_provider.dart';
import 'package:mobile_ver/features/reminder/models/upcoming_reminder.dart';

class UpcomingReminderNotifier
    extends StateNotifier<AsyncValue<UpcomingReminder?>> {
  static const Duration _freshWindow = Duration(seconds: 20);
  static final UpcomingReminder _mockReminder = UpcomingReminder(
    id: 1,
    title: 'Laporan Praktikum PBO',
    targetType: 'tugas',
    scheduledAt: DateTime(2026, 4, 22, 1, 2),
    scheduledLabel: 'Rabu, 22 April 2026 01:02',
    relativeLabel: '1 minggu lagi',
    timeLeftText: 'Sisa 1 minggu 2 hari',
    secondsLeft: 9 * 24 * 3600,
  );

  Future<void>? _activeRequest;
  DateTime? _lastFetchedAt;
  final int userId;

  UpcomingReminderNotifier({required this.userId})
    : super(const AsyncValue.loading()) {
    fetchReminder();
  }

  Future<void> fetchReminder({bool showLoader = true, bool force = false}) {
    if (!force &&
        _lastFetchedAt != null &&
        DateTime.now().difference(_lastFetchedAt!) < _freshWindow &&
        state.hasValue) {
      return Future.value();
    }

    if (_activeRequest != null) {
      return _activeRequest!;
    }

    final request = _performFetch(showLoader: showLoader);
    _activeRequest = request;

    return request.whenComplete(() {
      if (identical(_activeRequest, request)) {
        _activeRequest = null;
      }
    });
  }

  Future<void> _performFetch({required bool showLoader}) async {
    if (AppMode.uiOnly) {
      state = AsyncValue.data(_mockReminder);
      _lastFetchedAt = DateTime.now();
      return;
    }

    final previous = state.valueOrNull;
    if (showLoader || previous == null) {
      state = const AsyncValue.loading();
    }

    try {
      final response = await ApiClient.get('/reminder/next');
      if (response.statusCode != 200) {
        state = AsyncValue.error('Failed to load reminder', StackTrace.current);
        return;
      }

      final payload = _decodeToMap(response.body);
      final rawData = payload['data'];
      if (rawData == null) {
        state = const AsyncValue.data(null);
        _lastFetchedAt = DateTime.now();
        return;
      }

      if (rawData is Map<String, dynamic>) {
        state = AsyncValue.data(UpcomingReminder.fromJson(rawData));
        _lastFetchedAt = DateTime.now();
        return;
      }

      if (rawData is Map) {
        state = AsyncValue.data(
          UpcomingReminder.fromJson(Map<String, dynamic>.from(rawData)),
        );
        _lastFetchedAt = DateTime.now();
        return;
      }

      state = AsyncValue.error('Invalid reminder response', StackTrace.current);
    } catch (e, st) {
      final localReminder = await _readNextLocalReminder();
      if (localReminder != null || previous == null) {
        state = AsyncValue.data(localReminder);
        _lastFetchedAt = DateTime.now();
      } else {
        state = AsyncValue.error(e, st);
      }
    }
  }

  Future<UpcomingReminder?> _readNextLocalReminder() async {
    if (userId <= 0) return null;

    final db = await AppDatabase.instance.database;
    final now = DateTime.now();
    final rows = await db.query(
      'reminder_local',
      where:
          'user_id = ? AND deleted_locally = 0 AND active = 1 AND scheduled_at >= ?',
      whereArgs: [userId, now.toIso8601String()],
      orderBy: 'scheduled_at ASC, local_int_id ASC',
      limit: 1,
    );

    if (rows.isEmpty) return null;

    final row = rows.first;
    final scheduledAt = DateTime.tryParse(
      row['scheduled_at']?.toString() ?? '',
    );
    final secondsLeft = scheduledAt == null
        ? 0
        : scheduledAt.difference(now).inSeconds.clamp(0, 1 << 31);

    return UpcomingReminder(
      id:
          (row['server_id'] as num?)?.toInt() ??
          (row['local_int_id'] as num?)?.toInt() ??
          0,
      title: row['title']?.toString() ?? 'Reminder',
      targetType: row['target_type']?.toString() ?? 'reminder',
      scheduledAt: scheduledAt,
      scheduledLabel: row['scheduled_label']?.toString() ?? '',
      relativeLabel: _relativeLabel(secondsLeft),
      timeLeftText: _timeLeftText(secondsLeft),
      secondsLeft: secondsLeft,
    );
  }

  Map<String, dynamic> _decodeToMap(String raw) {
    final decoded = jsonDecode(raw);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }

    if (decoded is Map) {
      return Map<String, dynamic>.from(decoded);
    }

    return <String, dynamic>{};
  }
}

String _relativeLabel(int secondsLeft) {
  if (secondsLeft <= 0) return 'Sekarang';
  final duration = Duration(seconds: secondsLeft);
  if (duration.inDays >= 1) return '${duration.inDays} hari lagi';
  if (duration.inHours >= 1) return '${duration.inHours} jam lagi';
  if (duration.inMinutes >= 1) return '${duration.inMinutes} menit lagi';
  return 'Sebentar lagi';
}

String _timeLeftText(int secondsLeft) {
  if (secondsLeft <= 0) return 'Sekarang';
  final duration = Duration(seconds: secondsLeft);
  if (duration.inDays >= 1) {
    final hours = duration.inHours.remainder(24);
    return hours > 0
        ? 'Sisa ${duration.inDays} hari $hours jam'
        : 'Sisa ${duration.inDays} hari';
  }
  if (duration.inHours >= 1) {
    final minutes = duration.inMinutes.remainder(60);
    return minutes > 0
        ? 'Sisa ${duration.inHours} jam $minutes menit'
        : 'Sisa ${duration.inHours} jam';
  }
  if (duration.inMinutes >= 1) return 'Sisa ${duration.inMinutes} menit';
  return 'Sisa kurang dari 1 menit';
}

final upcomingReminderProvider =
    StateNotifierProvider<
      UpcomingReminderNotifier,
      AsyncValue<UpcomingReminder?>
    >((ref) {
      final user = ref.watch(userProvider);
      return UpcomingReminderNotifier(userId: user?.id ?? 0);
    });
