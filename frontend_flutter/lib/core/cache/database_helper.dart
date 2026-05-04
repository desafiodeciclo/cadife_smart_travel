import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final path = join(await getDatabasesPath(), 'cadife_offline.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE offline_events(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT,
            payload TEXT,
            created_at TEXT,
            is_synced INTEGER
          )
        ''');
      },
    );
  }

  /// Fecha a conexão com o banco de dados e libera a referência.
  /// Deve ser chamado em [disposeDependencies] ou em testes.
  Future<void> close() async {
    if (_db != null) {
      await _db!.close();
      _db = null;
    }
  }
}
