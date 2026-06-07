import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_ver/core/sync/sync_models.dart';

void main() {
  group('Sync models', () {
    test('maps sync statuses to wire names', () {
      expect(SyncStatus.synced.wireName, 'synced');
      expect(SyncStatus.pendingCreate.wireName, 'pending_create');
      expect(SyncStatus.pendingUpdate.wireName, 'pending_update');
      expect(SyncStatus.pendingDelete.wireName, 'pending_delete');
      expect(SyncStatus.failed.wireName, 'failed');
      expect(SyncStatus.conflict.wireName, 'conflict');
      expect(SyncStatus.authRequired.wireName, 'auth_required');
    });

    test('builds outbox operation API payload without local-only fields', () {
      const operation = SyncOutboxOperation(
        operationId: 'op-1',
        userId: 42,
        entityType: 'catatan',
        entityLocalUuid: 'local-uuid',
        entityServerId: 9,
        action: 'update',
        payload: {'judul': 'Catatan'},
        baseServerVersion: 3,
        status: 'pending',
        attemptCount: 2,
      );

      expect(operation.toApiPayload(), {
        'operation_id': 'op-1',
        'entity_type': 'catatan',
        'action': 'update',
        'client_uuid': 'local-uuid',
        'server_id': 9,
        'base_server_version': 3,
        'payload': {'judul': 'Catatan'},
      });
    });
  });
}
