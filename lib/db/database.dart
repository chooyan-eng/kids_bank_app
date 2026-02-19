import 'package:sqflite/sqflite.dart';

class AppDatabase {
  static const _dbName = 'kids_bank.db';
  static const _dbVersion = 1;

  static Database? _database;

  static Future<Database> get database async {
    _database ??= await _open();
    return _database!;
  }

  static Future<Database> _open() async {
    final dbPath = await getDatabasesPath();
    final path = '$dbPath/$_dbName';

    return openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
  }

  static Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE children (
        id                       TEXT PRIMARY KEY,
        name                     TEXT NOT NULL,
        icon_type                TEXT,
        icon_image_path          TEXT,
        interest_rate_percent    REAL NOT NULL DEFAULT 0.0,
        balance                  REAL NOT NULL DEFAULT 0.0,
        last_interest_applied_at TEXT,
        created_at               TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE transactions (
        id            TEXT PRIMARY KEY,
        child_id      TEXT NOT NULL,
        type          TEXT NOT NULL,
        amount        REAL NOT NULL,
        balance_after REAL NOT NULL,
        memo          TEXT NOT NULL DEFAULT '',
        date          TEXT NOT NULL,
        created_at    TEXT NOT NULL,
        FOREIGN KEY (child_id) REFERENCES children(id) ON DELETE CASCADE
      )
    ''');
  }

  static Future<void> _onUpgrade(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    // Future migrations go here.
    // Example:
    // if (oldVersion < 2) {
    //   await db.execute('ALTER TABLE children ADD COLUMN ...');
    // }
  }
}
