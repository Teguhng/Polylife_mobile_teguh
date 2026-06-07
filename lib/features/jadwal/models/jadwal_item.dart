enum JadwalType { kuliah, tugas, ujian, rapat, personal }

class JadwalMatkulPreview {
  final int? id;
  final String name;
  final String? kelas;
  final String? ruangan;
  final String? timeLabel;
  final String? warnaLabel;
  final List<String> scheduleDays;
  final List<JadwalMatkulScheduleEntry> scheduleEntries;

  const JadwalMatkulPreview({
    this.id,
    required this.name,
    this.kelas,
    this.ruangan,
    this.timeLabel,
    this.warnaLabel,
    this.scheduleDays = const <String>[],
    this.scheduleEntries = const <JadwalMatkulScheduleEntry>[],
  });
}

class JadwalMatkulScheduleEntry {
  final String? hari;
  final String? jamMulai;
  final String? jamSelesai;
  final String? ruangan;
  final String? kelas;

  const JadwalMatkulScheduleEntry({
    this.hari,
    this.jamMulai,
    this.jamSelesai,
    this.ruangan,
    this.kelas,
  });
}

extension JadwalTypeLabel on JadwalType {
  String get label {
    switch (this) {
      case JadwalType.kuliah:
        return 'Kuliah';
      case JadwalType.tugas:
        return 'Tugas';
      case JadwalType.ujian:
        return 'Ujian';
      case JadwalType.rapat:
        return 'Rapat';
      case JadwalType.personal:
        return 'Personal';
    }
  }
}

class JadwalItem {
  final int id;
  final String localUuid;
  final int? serverId;
  final int serverVersion;
  final String syncStatus;
  final String title;
  final JadwalType type;
  final DateTime startAt;
  final DateTime endAt;
  final String location;
  final String notes;
  final bool completed;
  final List<String> matkulNames;
  final JadwalMatkulPreview? primaryMatkul;
  final List<JadwalMatkulPreview> matkulPreviews;

  const JadwalItem({
    required this.id,
    this.localUuid = '',
    this.serverId,
    this.serverVersion = 0,
    this.syncStatus = 'synced',
    required this.title,
    required this.type,
    required this.startAt,
    required this.endAt,
    required this.location,
    required this.notes,
    required this.completed,
    this.matkulNames = const <String>[],
    this.primaryMatkul,
    this.matkulPreviews = const <JadwalMatkulPreview>[],
  });

  JadwalItem copyWith({
    int? id,
    String? localUuid,
    int? serverId,
    int? serverVersion,
    String? syncStatus,
    String? title,
    JadwalType? type,
    DateTime? startAt,
    DateTime? endAt,
    String? location,
    String? notes,
    bool? completed,
    List<String>? matkulNames,
    JadwalMatkulPreview? primaryMatkul,
    List<JadwalMatkulPreview>? matkulPreviews,
  }) {
    return JadwalItem(
      id: id ?? this.id,
      localUuid: localUuid ?? this.localUuid,
      serverId: serverId ?? this.serverId,
      serverVersion: serverVersion ?? this.serverVersion,
      syncStatus: syncStatus ?? this.syncStatus,
      title: title ?? this.title,
      type: type ?? this.type,
      startAt: startAt ?? this.startAt,
      endAt: endAt ?? this.endAt,
      location: location ?? this.location,
      notes: notes ?? this.notes,
      completed: completed ?? this.completed,
      matkulNames: matkulNames ?? this.matkulNames,
      primaryMatkul: primaryMatkul ?? this.primaryMatkul,
      matkulPreviews: matkulPreviews ?? this.matkulPreviews,
    );
  }
}

class JadwalInput {
  final String title;
  final JadwalType type;
  final DateTime startAt;
  final DateTime endAt;
  final String location;
  final String notes;
  final bool completed;

  const JadwalInput({
    required this.title,
    required this.type,
    required this.startAt,
    required this.endAt,
    required this.location,
    required this.notes,
    required this.completed,
  });
}
