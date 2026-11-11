import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/electrodomestico.dart';
import 'datos_iniciales.dart';

class DatabaseHelper {
  // Patrón Singleton: constructor privado e instancia estática única.
  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();

  static const _nombreDb = 'inventario.db';
  static const _version = 3;
  static const tabla = 'electrodomesticos';

  // Se almacena el Future (y no la instancia de Database) para evitar la apertura
  // concurrente de múltiples instancias de la base de datos (Patrón Singleton).
  static Future<Database>? _dbFuture;

  Future<Database> get database => _dbFuture ??= _initDb();

  Future<Database> _initDb() async {
    final ruta = join(await getDatabasesPath(), _nombreDb);
    return openDatabase(
      ruta,
      version: _version,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Las restricciones de integridad se definen también a nivel de base de datos, no solo en la interfaz.
    await db.execute('''
      CREATE TABLE $tabla (
        id        INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre    TEXT    NOT NULL,
        marca     TEXT    NOT NULL,
        categoria TEXT    NOT NULL,
        precio    REAL    NOT NULL CHECK (precio > 0),
        stock     INTEGER NOT NULL DEFAULT 0 CHECK (stock >= 0)
      )
    ''');
    await _sembrarDatosIniciales(db);
  }

  /// Migración a la versión 3: depura la tabla y la restablece con el
  /// catálogo inicial.
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 3) {
      await _sembrarDatosIniciales(db);
    }
  }

  /// Carga el catálogo inicial (seeding). Vacía previamente la tabla para
  /// eliminar registros anteriores e inserta únicamente [datosIniciales].
  Future<void> _sembrarDatosIniciales(Database db) async {
    await db.transaction((txn) async {
      await txn.delete(tabla);
      // Reinicia la secuencia de autoincremento para que los identificadores comiencen en 1.
      await txn.delete('sqlite_sequence', where: 'name = ?', whereArgs: [tabla]);

      final batch = txn.batch();
      for (final e in datosIniciales) {
        batch.insert(tabla, e.toMap());
      }
      await batch.commit(noResult: true);
    });
  }

  // ---------- CRUD ----------

  Future<int> insertar(Electrodomestico e) async {
    final db = await database;
    return db.insert(tabla, e.toMap());
  }

  Future<List<Electrodomestico>> listar() async {
    final db = await database;
    final filas = await db.query(tabla, orderBy: 'nombre COLLATE NOCASE ASC');
    return filas.map(Electrodomestico.fromMap).toList();
  }

  Future<Electrodomestico?> obtenerPorId(int id) async {
    final db = await database;
    final filas = await db.query(tabla, where: 'id = ?', whereArgs: [id], limit: 1);
    return filas.isEmpty ? null : Electrodomestico.fromMap(filas.first);
  }

  Future<int> actualizar(Electrodomestico e) async {
    if (e.id == null) {
      throw ArgumentError('No se puede actualizar un registro sin id');
    }
    final db = await database;
    return db.update(tabla, e.toMap(), where: 'id = ?', whereArgs: [e.id]);
  }

  /// Actualización parcial del campo stock, sin reescribir el registro completo.
  Future<int> actualizarStock(int id, int nuevoStock) async {
    final db = await database;
    return db.update(
      tabla,
      {'stock': nuevoStock},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> eliminar(int id) async {
    final db = await database;
    return db.delete(tabla, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> cerrar() async {
    final db = await _dbFuture;
    await db?.close();
    _dbFuture = null;
  }
}
