import '../datasources/database_helper.dart';
import '../models/electrodomestico.dart';

/// Punto de acceso a la capa de datos desde la capa de presentación.
/// Desacopla la fuente de datos: sustituir SQLite por una API solo requiere modificar esta clase y el datasource.
class ElectrodomesticoRepository {
  ElectrodomesticoRepository(this._db);

  final DatabaseHelper _db;

  Future<List<Electrodomestico>> obtenerTodos() => _db.listar();

  /// Inserta el registro si carece de id; en caso contrario, lo actualiza.
  Future<void> guardar(Electrodomestico e) async {
    if (e.id == null) {
      await _db.insertar(e);
    } else {
      await _db.actualizar(e);
    }
  }

  Future<void> actualizarStock(int id, int nuevoStock) {
    if (nuevoStock < 0) {
      throw ArgumentError('El stock no puede ser negativo');
    }
    return _db.actualizarStock(id, nuevoStock);
  }

  Future<void> eliminar(int id) => _db.eliminar(id);
}
