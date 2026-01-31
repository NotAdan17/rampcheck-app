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
      version: 2, // <-- bumped version so new tables get created via onUpgrade
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE jobs (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            aircraftReg TEXT NOT NULL,
            status TEXT NOT NULL,
            createdAt TEXT NOT NULL
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
        // If upgrading from v1 -> v2, add the sync_queue table
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
      orderBy: 'createdAt DESC',
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

  static Future<int> clearSyncQueue() async {
    final db = await database;
    return await db.delete('sync_queue');
  }
}
