import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class NoteDb {
  NoteDb._();
  static final NoteDb instance = NoteDb._();

  static const _dbName = 'notes.db';
  static const _dbVersion = 1;

  static const table = 'notes';

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDb();
    return _database!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);

    return openDatabase(
      path,
      version: _dbVersion,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $table (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            content TEXT NOT NULL,
            deadline INTEGER NULL,
            createdAt INTEGER NOT NULL
          )
        ''');
      },
    );
  }

  Future<int> insert(Map<String, Object?> row) async {
    final db = await database;
    return db.insert(table, row);
  }

  Future<List<Map<String, Object?>>> queryAll() async {
    final db = await database;

    // Urutan:
    // deadline (null dulu), deadline paling dekat di atas
    // deadline null (non-priority) di bawah
    // createdAt sebagai tie-breaker
    return db.rawQuery('''
      SELECT * FROM $table
      ORDER BY
        CASE WHEN deadline IS NULL THEN 1 ELSE 0 END,
        deadline ASC,
        createdAt DESC
    ''');
  }

  Future<int> update(int id, Map<String, Object?> row) async {
    final db = await database;
    return db.update(table, row, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> delete(int id) async {
    final db = await database;
    return db.delete(table, where: 'id = ?', whereArgs: [id]);
  }
}
