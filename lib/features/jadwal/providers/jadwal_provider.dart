import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_ver/core/config/app_mode.dart';
import 'package:mobile_ver/features/auth/providers/auth_provider.dart';

import 'package:mobile_ver/features/jadwal/models/jadwal_item.dart';
import 'package:mobile_ver/features/jadwal/repositories/api_jadwal_repository.dart';
import 'package:mobile_ver/features/jadwal/repositories/in_memory_jadwal_repository.dart';
import 'package:mobile_ver/features/jadwal/repositories/jadwal_repository.dart';
import 'package:mobile_ver/features/jadwal/repositories/offline_first_jadwal_repository.dart';
import 'package:mobile_ver/features/jadwal/services/jadwal_scheduler_service.dart';

class JadwalActionResult {
  final bool success;
  final String? message;

  const JadwalActionResult({required this.success, this.message});
}

class JadwalState {
  final bool isLoading;
  final List<JadwalItem> allItems;
  final DateTime selectedDate;
  final List<JadwalItem> dayItems;
  final JadwalDayStats dayStats;
  final String? errorMessage;

  const JadwalState({
    required this.isLoading,
    required this.allItems,
    required this.selectedDate,
    required this.dayItems,
    required this.dayStats,
    required this.errorMessage,
  });

  factory JadwalState.initial() {
    final selected = DateTime.now();
    return JadwalState(
      isLoading: true,
      allItems: const <JadwalItem>[],
      selectedDate: DateTime(selected.year, selected.month, selected.day),
      dayItems: const <JadwalItem>[],
      dayStats: const JadwalDayStats(total: 0, completed: 0, upcoming: 0),
      errorMessage: null,
    );
  }

  JadwalState copyWith({
    bool? isLoading,
    List<JadwalItem>? allItems,
    DateTime? selectedDate,
    List<JadwalItem>? dayItems,
    JadwalDayStats? dayStats,
    String? errorMessage,
    bool clearError = false,
  }) {
    return JadwalState(
      isLoading: isLoading ?? this.isLoading,
      allItems: allItems ?? this.allItems,
      selectedDate: selectedDate ?? this.selectedDate,
      dayItems: dayItems ?? this.dayItems,
      dayStats: dayStats ?? this.dayStats,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class JadwalNotifier extends StateNotifier<JadwalState> {
  final JadwalRepository _repository;
  final JadwalSchedulerService _scheduler;

  JadwalNotifier({
    JadwalRepository? repository,
    JadwalSchedulerService? scheduler,
  }) : _repository =
           repository ??
           (AppMode.uiOnly
               ? InMemoryJadwalRepository()
               : ApiJadwalRepository()),
       _scheduler = scheduler ?? const JadwalSchedulerService(),
       super(JadwalState.initial()) {
    _recomputeDerived();
    load();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final rows = await _repository.fetchAll();
      _setAllItems(rows, keepLoading: false);
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Gagal memuat jadwal.',
      );
    }
  }

  void selectDate(DateTime value) {
    final normalized = _scheduler.normalizeDate(value);
    state = state.copyWith(selectedDate: normalized);
    _recomputeDerived();
  }

  Future<JadwalActionResult> createFromInput(JadwalInput input) async {
    final draft = JadwalItem(
      id: 0,
      title: input.title.trim(),
      type: input.type,
      startAt: input.startAt,
      endAt: input.endAt,
      location: input.location.trim(),
      notes: input.notes.trim(),
      completed: input.completed,
    );

    if (_scheduler.hasConflict(allItems: state.allItems, candidate: draft)) {
      return const JadwalActionResult(
        success: false,
        message: 'Jadwal bentrok dengan agenda lain di jam yang sama.',
      );
    }

    try {
      final created = await _repository.create(draft);
      _setAllItems(<JadwalItem>[...state.allItems, created]);
      return const JadwalActionResult(success: true);
    } catch (_) {
      return const JadwalActionResult(
        success: false,
        message: 'Gagal menambahkan jadwal.',
      );
    }
  }

  Future<JadwalActionResult> updateFromInput({
    required int id,
    required JadwalInput input,
  }) async {
    final updated = JadwalItem(
      id: id,
      title: input.title.trim(),
      type: input.type,
      startAt: input.startAt,
      endAt: input.endAt,
      location: input.location.trim(),
      notes: input.notes.trim(),
      completed: input.completed,
    );

    if (_scheduler.hasConflict(
      allItems: state.allItems,
      candidate: updated,
      ignoreId: id,
    )) {
      return const JadwalActionResult(
        success: false,
        message: 'Perubahan jadwal bentrok dengan agenda lain.',
      );
    }

    try {
      final saved = await _repository.update(updated);
      final merged = state.allItems
          .map((item) => item.id == id ? saved : item)
          .toList();
      _setAllItems(merged);
      return const JadwalActionResult(success: true);
    } catch (_) {
      return const JadwalActionResult(
        success: false,
        message: 'Gagal memperbarui jadwal.',
      );
    }
  }

  Future<void> toggleCompleted(JadwalItem item) async {
    try {
      final updated = item.copyWith(completed: !item.completed);
      final saved = await _repository.update(updated);
      final merged = state.allItems
          .map((row) => row.id == item.id ? saved : row)
          .toList();
      _setAllItems(merged);
    } catch (_) {
      state = state.copyWith(errorMessage: 'Gagal mengubah status jadwal.');
    }
  }

  Future<void> delete(int id) async {
    try {
      await _repository.delete(id);
      final rows = state.allItems.where((item) => item.id != id).toList();
      _setAllItems(rows);
    } catch (_) {
      state = state.copyWith(errorMessage: 'Gagal menghapus jadwal.');
    }
  }

  int countForDate(DateTime date) {
    return _scheduler.countForDate(allItems: state.allItems, date: date);
  }

  List<DateTime> buildMonthGrid(DateTime monthAnchor) {
    return _scheduler.buildMonthGrid(monthAnchor);
  }

  List<JadwalItem> itemsForDate(DateTime date) {
    return _scheduler.itemsForDate(allItems: state.allItems, date: date);
  }

  JadwalType? dominantTypeForDate(DateTime date) {
    return _scheduler.dominantTypeForDate(allItems: state.allItems, date: date);
  }

  void _setAllItems(List<JadwalItem> rows, {bool keepLoading = false}) {
    state = state.copyWith(
      allItems: rows,
      isLoading: keepLoading ? state.isLoading : false,
      clearError: true,
    );
    _recomputeDerived();
  }

  void _recomputeDerived() {
    final dayItems = _scheduler.itemsForDate(
      allItems: state.allItems,
      date: state.selectedDate,
    );
    final dayStats = _scheduler.buildDayStats(dayItems);

    state = state.copyWith(dayItems: dayItems, dayStats: dayStats);
  }
}

final jadwalProvider = StateNotifierProvider<JadwalNotifier, JadwalState>((
  ref,
) {
  final user = ref.watch(userProvider);
  return JadwalNotifier(
    repository: AppMode.uiOnly
        ? InMemoryJadwalRepository()
        : user == null
        ? ApiJadwalRepository()
        : OfflineFirstJadwalRepository(userId: user.id),
  );
});
