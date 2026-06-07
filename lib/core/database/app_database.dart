import 'package:path/path.dart' as p;
import 'package:mobile_ver/core/security/local_data_crypto.dart';
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  AppDatabase._();

  static final AppDatabase instance = AppDatabase._();

  static const int _version = 5;
  Database? _database;

  Future<Database> get database async {
    final existing = _database;
    if (existing != null) {
      return existing;
    }

    final root = await getDatabasesPath();
    final db = await openDatabase(
      p.join(root, 'polylife_mobile.db'),
      version: _version,
      onCreate: _create,
      onUpgrade: _upgrade,
    );
    _database = db;
    return db;
  }

  Future<T> transaction<T>(Future<T> Function(Transaction txn) action) async {
    final db = await database;
    return db.transaction(action);
  }

  Future<void> clearUserData(int userId) async {
    if (userId <= 0) {
      return;
    }

    await transaction((txn) async {
      for (final table in const [
        'catatan_local',
        'keuangan_local',
        'todo_local',
        'jadwal_local',
        'reminder_local',
        'pengumuman_local',
        'sync_outbox',
      ]) {
        await txn.delete(table, where: 'user_id = ?', whereArgs: [userId]);
      }
      await txn.delete(
        'sync_metadata',
        where: 'key = ?',
        whereArgs: ['sync_cursor'],
      );
    });

    await LocalDataCrypto.deleteUserKey(userId);
  }

  Future<void> _create(Database db, int version) async {
    await db.execute('''
      CREATE TABLE sync_metadata (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE catatan_local (
        local_uuid TEXT PRIMARY KEY,
        local_int_id INTEGER NOT NULL,
        user_id INTEGER NOT NULL,
        server_id INTEGER,
        judul TEXT NOT NULL,
        isi TEXT NOT NULL,
        preview_isi TEXT NOT NULL,
        show_preview INTEGER NOT NULL DEFAULT 0,
        has_full_isi INTEGER NOT NULL DEFAULT 1,
        tanggal TEXT NOT NULL,
        status_sampah INTEGER NOT NULL DEFAULT 0,
        server_version INTEGER NOT NULL DEFAULT 0,
        sync_status TEXT NOT NULL,
        deleted_locally INTEGER NOT NULL DEFAULT 0,
        created_at TEXT,
        updated_at TEXT,
        dirty_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE keuangan_local (
        local_uuid TEXT PRIMARY KEY,
        local_int_id INTEGER NOT NULL,
        user_id INTEGER NOT NULL,
        server_id INTEGER,
        jenis TEXT NOT NULL,
        kategori TEXT NOT NULL,
        deskripsi TEXT,
        nominal REAL NOT NULL,
        tanggal TEXT NOT NULL,
        server_version INTEGER NOT NULL DEFAULT 0,
        sync_status TEXT NOT NULL,
        deleted_locally INTEGER NOT NULL DEFAULT 0,
        created_at TEXT,
        updated_at TEXT,
        dirty_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE todo_local (
        local_uuid TEXT PRIMARY KEY,
        local_int_id INTEGER NOT NULL,
        user_id INTEGER NOT NULL,
        server_id INTEGER,
        title TEXT NOT NULL,
        description TEXT NOT NULL DEFAULT '',
        completed INTEGER NOT NULL DEFAULT 0,
        due_at TEXT,
        priority TEXT NOT NULL DEFAULT 'normal',
        server_version INTEGER NOT NULL DEFAULT 0,
        sync_status TEXT NOT NULL,
        deleted_locally INTEGER NOT NULL DEFAULT 0,
        created_at TEXT,
        updated_at TEXT,
        dirty_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE jadwal_local (
        local_uuid TEXT PRIMARY KEY,
        local_int_id INTEGER NOT NULL,
        user_id INTEGER NOT NULL,
        server_id INTEGER,
        title TEXT NOT NULL,
        type TEXT NOT NULL,
        start_at TEXT NOT NULL,
        end_at TEXT NOT NULL,
        location TEXT NOT NULL DEFAULT '',
        notes TEXT NOT NULL DEFAULT '',
        completed INTEGER NOT NULL DEFAULT 0,
        matkul_names_json TEXT NOT NULL DEFAULT '[]',
        primary_matkul_json TEXT,
        matkul_previews_json TEXT NOT NULL DEFAULT '[]',
        server_version INTEGER NOT NULL DEFAULT 0,
        sync_status TEXT NOT NULL,
        deleted_locally INTEGER NOT NULL DEFAULT 0,
        created_at TEXT,
        updated_at TEXT,
        dirty_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE pengumuman_local (
        server_id INTEGER PRIMARY KEY,
        user_id INTEGER NOT NULL,
        title TEXT NOT NULL,
        body TEXT,
        excerpt TEXT NOT NULL,
        image_url TEXT,
        target_mode TEXT NOT NULL,
        published_at TEXT NOT NULL,
        creator_json TEXT,
        updated_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE reminder_local (
        local_uuid TEXT PRIMARY KEY,
        local_int_id INTEGER NOT NULL,
        user_id INTEGER NOT NULL,
        server_id INTEGER,
        target_type TEXT NOT NULL,
        target_server_id INTEGER,
        title TEXT NOT NULL,
        target_label TEXT NOT NULL,
        target_context TEXT NOT NULL,
        destination TEXT NOT NULL,
        active INTEGER NOT NULL DEFAULT 1,
        scheduled_at TEXT,
        scheduled_label TEXT NOT NULL DEFAULT '',
        server_version INTEGER NOT NULL DEFAULT 0,
        sync_status TEXT NOT NULL,
        deleted_locally INTEGER NOT NULL DEFAULT 0,
        created_at TEXT,
        updated_at TEXT,
        dirty_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE sync_outbox (
        operation_id TEXT PRIMARY KEY,
        user_id INTEGER NOT NULL,
        entity_type TEXT NOT NULL,
        entity_local_uuid TEXT NOT NULL,
        entity_server_id INTEGER,
        action TEXT NOT NULL,
        payload_json TEXT NOT NULL,
        base_server_version INTEGER,
        depends_on_operation_id TEXT,
        status TEXT NOT NULL,
        attempt_count INTEGER NOT NULL DEFAULT 0,
        schema_version INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        locked_until TEXT,
        error_message TEXT
      )
    ''');

    await db.execute(
      'CREATE INDEX idx_catatan_user ON catatan_local(user_id, deleted_locally, tanggal, server_id)',
    );
    await db.execute(
      'CREATE INDEX idx_keuangan_user ON keuangan_local(user_id, deleted_locally, tanggal, server_id)',
    );
    await db.execute(
      'CREATE INDEX idx_todo_user ON todo_local(user_id, deleted_locally, completed, server_id)',
    );
    await db.execute(
      'CREATE INDEX idx_jadwal_user ON jadwal_local(user_id, deleted_locally, start_at, server_id)',
    );
    await db.execute(
      'CREATE INDEX idx_reminder_user ON reminder_local(user_id, deleted_locally, scheduled_at, server_id)',
    );
    await db.execute(
      'CREATE INDEX idx_outbox_pending ON sync_outbox(user_id, status, created_at)',
    );
  }

  Future<void> _upgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute(
        'ALTER TABLE catatan_local ADD COLUMN show_preview INTEGER NOT NULL DEFAULT 0',
      );
      await db.execute(
        "UPDATE catatan_local SET preview_isi = '' WHERE show_preview = 0",
      );
    }

    if (oldVersion < 3) {
      await _encryptExistingCatatanCache(db);
    }

    if (oldVersion < 4) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS reminder_local (
          local_uuid TEXT PRIMARY KEY,
          local_int_id INTEGER NOT NULL,
          user_id INTEGER NOT NULL,
          server_id INTEGER,
          target_type TEXT NOT NULL,
          target_server_id INTEGER,
          title TEXT NOT NULL,
          target_label TEXT NOT NULL,
          target_context TEXT NOT NULL,
          destination TEXT NOT NULL,
          active INTEGER NOT NULL DEFAULT 1,
          scheduled_at TEXT,
          scheduled_label TEXT NOT NULL DEFAULT '',
          server_version INTEGER NOT NULL DEFAULT 0,
          sync_status TEXT NOT NULL,
          deleted_locally INTEGER NOT NULL DEFAULT 0,
          created_at TEXT,
          updated_at TEXT,
          dirty_at TEXT
        )
      ''');
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_reminder_user ON reminder_local(user_id, deleted_locally, scheduled_at, server_id)',
      );
    }

    if (oldVersion < 5) {
      await db.execute(
        "ALTER TABLE jadwal_local ADD COLUMN matkul_names_json TEXT NOT NULL DEFAULT '[]'",
      );
      await db.execute(
        'ALTER TABLE jadwal_local ADD COLUMN primary_matkul_json TEXT',
      );
      await db.execute(
        "ALTER TABLE jadwal_local ADD COLUMN matkul_previews_json TEXT NOT NULL DEFAULT '[]'",
      );
      await db.delete(
        'sync_metadata',
        where: 'key = ?',
        whereArgs: ['sync_cursor'],
      );
    }
  }

  Future<void> _encryptExistingCatatanCache(Database db) async {
    final rows = await db.query(
      'catatan_local',
      columns: ['local_uuid', 'user_id', 'isi', 'preview_isi'],
    );

    for (final row in rows) {
      final localUuid = row['local_uuid']?.toString() ?? '';
      final userId = (row['user_id'] as num?)?.toInt() ?? 0;
      if (localUuid.isEmpty || userId <= 0) {
        continue;
      }

      final isi = row['isi']?.toString() ?? '';
      final previewIsi = row['preview_isi']?.toString() ?? '';
      final encryptedIsi = await LocalDataCrypto.encryptString(userId, isi);
      final encryptedPreview = await LocalDataCrypto.encryptString(
        userId,
        previewIsi,
      );

      if (encryptedIsi != isi || encryptedPreview != previewIsi) {
        await db.update(
          'catatan_local',
          {'isi': encryptedIsi, 'preview_isi': encryptedPreview},
          where: 'local_uuid = ?',
          whereArgs: [localUuid],
        );
      }
    }

    final outboxRows = await db.query(
      'sync_outbox',
      columns: ['operation_id', 'user_id', 'payload_json'],
      where: 'entity_type = ?',
      whereArgs: ['catatan'],
    );

    for (final row in outboxRows) {
      final operationId = row['operation_id']?.toString() ?? '';
      final userId = (row['user_id'] as num?)?.toInt() ?? 0;
      final payloadJson = row['payload_json']?.toString() ?? '';
      if (operationId.isEmpty ||
          userId <= 0 ||
          payloadJson.isEmpty ||
          LocalDataCrypto.isEncryptedString(payloadJson)) {
        continue;
      }

      final encryptedPayload = await LocalDataCrypto.encryptString(
        userId,
        payloadJson,
      );
      await db.update(
        'sync_outbox',
        {'payload_json': encryptedPayload},
        where: 'operation_id = ?',
        whereArgs: [operationId],
      );
    }
  }
}
