class Catatan {
  final int id;
  final String localUuid;
  final int? serverId;
  final int serverVersion;
  final String syncStatus;
  final String judul;
  final String isi;
  final String previewIsi;
  final bool showPreview;
  final bool hasFullIsi;
  final String tanggal;
  final bool statusSampah;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Catatan({
    required this.id,
    this.localUuid = '',
    this.serverId,
    this.serverVersion = 0,
    this.syncStatus = 'synced',
    required this.judul,
    required this.isi,
    required this.previewIsi,
    this.showPreview = false,
    required this.hasFullIsi,
    required this.tanggal,
    required this.statusSampah,
    this.createdAt,
    this.updatedAt,
  });

  factory Catatan.fromJson(Map<String, dynamic> json) {
    final rawStatus = json['status_sampah'];
    final isTrash = rawStatus == true || rawStatus == 1 || rawStatus == '1';
    final rawShowPreview = json['show_preview'];
    final showPreview =
        rawShowPreview == true ||
        rawShowPreview == 1 ||
        rawShowPreview == '1' ||
        rawShowPreview == 'true';
    final hasFullIsi = json['has_full_isi'] == true || json.containsKey('isi');
    final previewIsi = showPreview
        ? (json['preview_isi'] ?? '').toString()
        : '';
    final fullIsi = hasFullIsi ? (json['isi'] ?? '').toString() : '';

    return Catatan(
      id: int.tryParse((json['id'] ?? '').toString()) ?? 0,
      localUuid: (json['sync_uuid'] ?? '').toString(),
      serverId: int.tryParse((json['id'] ?? '').toString()),
      serverVersion:
          int.tryParse((json['server_version'] ?? '').toString()) ?? 1,
      judul: (json['judul'] ?? '').toString(),
      isi: fullIsi,
      previewIsi: previewIsi,
      showPreview: showPreview,
      hasFullIsi: hasFullIsi,
      tanggal: (json['tanggal'] ?? '').toString(),
      statusSampah: isTrash,
      createdAt: DateTime.tryParse((json['created_at'] ?? '').toString()),
      updatedAt: DateTime.tryParse((json['updated_at'] ?? '').toString()),
    );
  }

  DateTime get tanggalAsDate {
    return DateTime.tryParse(tanggal) ?? DateTime(1970, 1, 1);
  }

  String get listPreview {
    if (!showPreview) {
      return '';
    }

    final preview = previewIsi.trim();
    if (preview.isNotEmpty) {
      return preview;
    }
    return '';
  }

  Catatan copyWith({
    int? id,
    String? localUuid,
    int? serverId,
    int? serverVersion,
    String? syncStatus,
    String? judul,
    String? isi,
    String? previewIsi,
    bool? showPreview,
    bool? hasFullIsi,
    String? tanggal,
    bool? statusSampah,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Catatan(
      id: id ?? this.id,
      localUuid: localUuid ?? this.localUuid,
      serverId: serverId ?? this.serverId,
      serverVersion: serverVersion ?? this.serverVersion,
      syncStatus: syncStatus ?? this.syncStatus,
      judul: judul ?? this.judul,
      isi: isi ?? this.isi,
      previewIsi: previewIsi ?? this.previewIsi,
      showPreview: showPreview ?? this.showPreview,
      hasFullIsi: hasFullIsi ?? this.hasFullIsi,
      tanggal: tanggal ?? this.tanggal,
      statusSampah: statusSampah ?? this.statusSampah,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
