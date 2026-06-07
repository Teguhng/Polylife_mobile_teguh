class ReminderListItem {
  final int id;
  final String localUuid;
  final int? serverId;
  final int serverVersion;
  final String syncStatus;
  final String title;
  final String targetType;
  final String targetLabel;
  final String targetContext;
  final String destination;
  final bool active;
  final DateTime? scheduledAt;
  final String scheduledLabel;

  const ReminderListItem({
    required this.id,
    this.localUuid = '',
    this.serverId,
    this.serverVersion = 0,
    this.syncStatus = 'synced',
    required this.title,
    required this.targetType,
    required this.targetLabel,
    required this.targetContext,
    required this.destination,
    required this.active,
    required this.scheduledAt,
    required this.scheduledLabel,
  });

  factory ReminderListItem.fromJson(Map<String, dynamic> json) {
    final id = (json['id'] as num?)?.toInt() ?? 0;
    return ReminderListItem(
      id: id,
      localUuid: json['sync_uuid']?.toString() ?? '',
      serverId: id > 0 ? id : null,
      serverVersion: (json['server_version'] as num?)?.toInt() ?? 0,
      syncStatus: 'synced',
      title: json['title']?.toString() ?? 'Reminder',
      targetType: json['target_type']?.toString() ?? 'reminder',
      targetLabel: json['target_label']?.toString() ?? 'Reminder',
      targetContext: json['target_context']?.toString() ?? '',
      destination: json['destination']?.toString() ?? 'todo',
      active:
          json['active'] == true ||
          json['active'] == 1 ||
          json['active'] == '1',
      scheduledAt: DateTime.tryParse(json['scheduled_at']?.toString() ?? ''),
      scheduledLabel: json['scheduled_label']?.toString() ?? '',
    );
  }

  ReminderListItem copyWith({
    int? id,
    String? localUuid,
    int? serverId,
    int? serverVersion,
    String? syncStatus,
    String? title,
    String? targetType,
    String? targetLabel,
    String? targetContext,
    String? destination,
    bool? active,
    DateTime? scheduledAt,
    String? scheduledLabel,
  }) {
    return ReminderListItem(
      id: id ?? this.id,
      localUuid: localUuid ?? this.localUuid,
      serverId: serverId ?? this.serverId,
      serverVersion: serverVersion ?? this.serverVersion,
      syncStatus: syncStatus ?? this.syncStatus,
      title: title ?? this.title,
      targetType: targetType ?? this.targetType,
      targetLabel: targetLabel ?? this.targetLabel,
      targetContext: targetContext ?? this.targetContext,
      destination: destination ?? this.destination,
      active: active ?? this.active,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      scheduledLabel: scheduledLabel ?? this.scheduledLabel,
    );
  }
}
