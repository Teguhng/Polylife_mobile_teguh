enum SyncStatus {
  synced,
  pendingCreate,
  pendingUpdate,
  pendingDelete,
  failed,
  conflict,
  authRequired,
}

extension SyncStatusWire on SyncStatus {
  String get wireName {
    switch (this) {
      case SyncStatus.synced:
        return 'synced';
      case SyncStatus.pendingCreate:
        return 'pending_create';
      case SyncStatus.pendingUpdate:
        return 'pending_update';
      case SyncStatus.pendingDelete:
        return 'pending_delete';
      case SyncStatus.failed:
        return 'failed';
      case SyncStatus.conflict:
        return 'conflict';
      case SyncStatus.authRequired:
        return 'auth_required';
    }
  }
}

class SyncOutboxOperation {
  final String operationId;
  final int userId;
  final String entityType;
  final String entityLocalUuid;
  final int? entityServerId;
  final String action;
  final Map<String, dynamic> payload;
  final int? baseServerVersion;
  final String status;
  final int attemptCount;

  const SyncOutboxOperation({
    required this.operationId,
    required this.userId,
    required this.entityType,
    required this.entityLocalUuid,
    required this.entityServerId,
    required this.action,
    required this.payload,
    required this.baseServerVersion,
    required this.status,
    required this.attemptCount,
  });

  Map<String, dynamic> toApiPayload() {
    return {
      'operation_id': operationId,
      'entity_type': entityType,
      'action': action,
      'client_uuid': entityLocalUuid,
      'server_id': entityServerId,
      'base_server_version': baseServerVersion,
      'payload': payload,
    };
  }
}
