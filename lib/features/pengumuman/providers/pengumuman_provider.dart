import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_ver/core/config/app_mode.dart';
import 'package:mobile_ver/core/config/api_config.dart';
import 'package:mobile_ver/core/media/local_image_cache.dart';
import 'package:mobile_ver/core/network/api_client.dart';
import '../models/pengumuman_model.dart';

class PengumumanNotifier extends StateNotifier<AsyncValue<List<Pengumuman>>> {
  static const Duration _freshWindow = Duration(seconds: 20);
  static final List<Pengumuman> _mockFeed = [
    Pengumuman(
      id: 1,
      title: 'Briefing Organisasi Mingguan',
      body: 'Rapat koordinasi terbuka untuk seluruh anggota.',
      excerpt:
          'Rapat koordinasi terbuka untuk seluruh anggota pada Jumat 19.00.',
      imageUrl: null,
      targetMode: 'afiliasi',
      publishedAt: '2026-02-28 08:00:00',
      creator: {'name': 'Admin Kampus'},
    ),
    Pengumuman(
      id: 2,
      title: 'Pengumuman Jadwal Ujian',
      body: 'Silakan cek perubahan jadwal ujian terbaru.',
      excerpt: 'Ada pembaruan jadwal ujian, pastikan cek sebelum hari H.',
      imageUrl: null,
      targetMode: 'global',
      publishedAt: '2026-02-27 16:30:00',
      creator: {'name': 'Biro Akademik'},
    ),
  ];

  Future<void>? _activeRequest;
  DateTime? _lastFetchedAt;

  PengumumanNotifier() : super(const AsyncValue.loading()) {
    fetchPengumuman();
  }

  Future<void> fetchPengumuman({bool showLoader = true, bool force = false}) {
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
      state = AsyncValue.data(List<Pengumuman>.from(_mockFeed));
      _lastFetchedAt = DateTime.now();
      return;
    }

    final previousState = state;
    if (showLoader || !previousState.hasValue) {
      state = const AsyncValue.loading();
    }

    try {
      final response = await ApiClient.get('/pengumuman?per_page=20');
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body)['data'];
        final list = data.map((e) => Pengumuman.fromJson(e)).toList();
        state = AsyncValue.data(list);
        _lastFetchedAt = DateTime.now();
        unawaited(_prefetchAnnouncementImages(list));
      } else {
        state = AsyncValue.error(
          'Kegiatan belum bisa dimuat. Periksa koneksi internet lalu coba lagi.',
          StackTrace.current,
        );
      }
    } catch (e, st) {
      state = AsyncValue.error(_friendlyFetchError(e), st);
    }
  }

  Future<void> _prefetchAnnouncementImages(List<Pengumuman> items) async {
    final urls = items
        .map((item) => _resolveImageUrl(item.imageUrl))
        .whereType<String>()
        .take(4)
        .toList();

    if (urls.isEmpty) {
      return;
    }

    await Future.wait(
      urls.map((url) => LocalImageCache.getOrFetchBytes(url)),
      eagerError: false,
    );
  }

  String? _resolveImageUrl(String? rawPath) {
    return ApiConfig.resolveMediaUrl(rawPath);
  }

  String _friendlyFetchError(Object error) {
    final raw = error.toString().toLowerCase();
    if (raw.contains('socketexception') ||
        raw.contains('failed host lookup') ||
        raw.contains('no address associated') ||
        raw.contains('connection refused') ||
        raw.contains('network is unreachable')) {
      return 'Kamu sedang offline atau koneksi sedang bermasalah. Kegiatan kampus akan dimuat lagi saat jaringan tersedia.';
    }

    if (raw.contains('timeout')) {
      return 'Koneksi terlalu lama merespons. Coba lagi beberapa saat.';
    }

    return 'Kegiatan belum bisa dimuat. Coba lagi beberapa saat.';
  }
}

final pengumumanProvider =
    StateNotifierProvider<PengumumanNotifier, AsyncValue<List<Pengumuman>>>((
      ref,
    ) {
      return PengumumanNotifier();
    });
