import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class LocalDb {
  static Future<Database> initDB() async {
    final dbPath = await getDatabasesPath();
    String path = join(dbPath, 'commandes.db');

    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE commandes (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            data_formulaire TEXT,
            client_sage TEXT,
            articles_sage TEXT,
            statut TEXT,
            id_sage TEXT,
            date_created TEXT
          )
        ''');
      },
    );
  }
}
