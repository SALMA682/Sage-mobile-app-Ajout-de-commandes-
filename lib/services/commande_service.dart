import 'package:sqflite/sqflite.dart';
import 'local_db.dart';
import '../models/commande.dart';

class CommandeService {
  static Future<int> insertCommande(Commande commande) async {
    final db = await LocalDb.initDB();
    return await db.insert(
      'commandes',
      commande.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<Commande?> getCommandeById(int id) async {
    final db = await LocalDb.initDB();
    final List<Map<String, dynamic>> maps = await db.query(
      'commandes',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return Commande.fromMap(maps.first);
    }
    return null;
  }

  static Future<List<Commande>> getAllCommandes() async {
    final db = await LocalDb.initDB();
    final List<Map<String, dynamic>> maps = await db.query('commandes');
    return List.generate(maps.length, (i) => Commande.fromMap(maps[i]));
  }

  static Future<List<Commande>> getCommandesByStatut(String statut) async {
    final db = await LocalDb.initDB();
    final List<Map<String, dynamic>> maps = await db.query(
      'commandes',
      where: 'statut = ?',
      whereArgs: [statut],
      orderBy: 'date_created DESC',
    );
    return List.generate(maps.length, (i) => Commande.fromMap(maps[i]));
  }

  static Future<int> updateCommande(Commande commande) async {
    final db = await LocalDb.initDB();
    return await db.update(
      'commandes',
      commande.toMap(),
      where: 'id = ?',
      whereArgs: [commande.id],
    );
  }
}
