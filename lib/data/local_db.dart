import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class LocalDb {
  static Database? _database;

  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDb();
    return _database!;
  }

  static Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'rampcheck.db');

    return await openDatabase(
      path,
      version: 3, // v3 adds updatedAt column + supports edits
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE jobs (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            aircraftReg TEXT NOT NULL,
            status TEXT NOT NULL,
            createdAt TEXT NOT NULL,
            updatedAt TEXT NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE sync_queue (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            entityType TEXT NOT NULL,
            entityId INTEGER NOT NULL,
            action TEXT NOT NULL,
            payload TEXT NOT NULL,
            createdAt TEXT NOT NULL
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        // v1/v2 -> v2: ensure sync_queue exists
        if (oldVersion < 2) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS sync_queue (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              entityType TEXT NOT NULL,
              entityId INTEGER NOT NULL,
              action TEXT NOT NULL,
              payload TEXT NOT NULL,
              createdAt TEXT NOT NULL
            )
          ''');
        }

        // v2 -> v3: add updatedAt column
        if (oldVersion < 3) {
          await db.execute('ALTER TABLE jobs ADD COLUMN updatedAt TEXT');
          // Backfill for existing rows
          await db.execute("UPDATE jobs SET updatedAt = createdAt WHERE updatedAt IS NULL");
        }
      },
    );
  }

  // -------------------------------
  // JOB DATABASE FUNCTIONS
  // -------------------------------

  static Future<int> insertJob(Map<String, dynamic> job) async {
    final db = await database;
    return await db.insert('jobs', job);
  }

  static Future<List<Map<String, dynamic>>> getJobs() async {
    final db = await database;
    return await db.query(
      'jobs',
      orderBy: 'updatedAt DESC',
    );
  }

  static Future<int> updateJob(int id, Map<String, dynamic> job) async {
    final db = await database;
    return await db.update(
      'jobs',
      job,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  static Future<int> deleteJob(int id) async {
    final db = await database;
    return await db.delete(
      'jobs',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // -------------------------------
  // SYNC QUEUE FUNCTIONS
  // -------------------------------

  static Future<int> enqueueSyncItem({
    required String entityType,
    required int entityId,
    required String action,
    required String payload,
  }) async {
    final db = await database;
    return await db.insert('sync_queue', {
      'entityType': entityType,
      'entityId': entityId,
      'action': action,
      'payload': payload,
      'createdAt': DateTime.now().toIso8601String(),
    });
  }

  static Future<List<Map<String, dynamic>>> getSyncQueue() async {
    final db = await database;
    return await db.query(
      'sync_queue',
      orderBy: 'createdAt ASC',
    );
  }

  static Future<int> getSyncQueueCount() async {
    final db = await database;
    final rows = await db.rawQuery('SELECT COUNT(*) as c FROM sync_queue');
    return (rows.first['c'] as int?) ?? 0;
  }

  static Future<int> clearSyncQueue() async {
    final db = await database;
    return await db.delete('sync_queue');
  }
}
