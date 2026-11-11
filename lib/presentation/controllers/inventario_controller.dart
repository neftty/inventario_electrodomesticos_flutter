import 'package:flutter/foundation.dart';

import '../../data/models/electrodomestico.dart';
import '../../data/repositories/electrodomestico_repository.dart';

/// Estado de la pantalla principal. La interfaz lo observa mediante ListenableBuilder,
/// lo que provoca la reconstrucción automática de la lista ante cada cambio de estado.
class InventarioController extends ChangeNotifier {
  InventarioController(this._repo);

  final ElectrodomesticoRepository _repo;

  /// Opciones del filtro horizontal. "Todos" deshabilita el filtrado por categoría.
  static const String todas = 'Todos';
  /// Se derivan del modelo para garantizar la consistencia entre los chips y el formulario.
  static const List<String> filtrosCategoria = [
    todas,
    ...Electrodomestico.categorias,
  ];

  List<Electrodomestico> _items = [];
  bool _cargando = false;
  String? _error;
  String _busqueda = '';
  String _categoria = todas;

  /// Inventario completo (sin filtrar).
  List<Electrodomestico> get items => List.unmodifiable(_items);
  bool get cargando => _cargando;
  String? get error => _error;
  String get busqueda => _busqueda;
  String get categoriaSeleccionada => _categoria;

  /// Lista visible: aplica el criterio de búsqueda (nombre o marca) y el filtro de categoría.
  List<Electrodomestico> get itemsFiltrados {
    final q = _normalizar(_busqueda.trim());
    return _items.where((e) {
      if (_categoria != todas && e.categoria != _categoria) return false;
      if (q.isEmpty) return true;
      return _normalizar(e.nombre).contains(q) ||
          _normalizar(e.marca).contains(q);
    }).toList(growable: false);
  }

  void buscar(String texto) {
    if (texto == _busqueda) return;
    _busqueda = texto;
    notifyListeners();
  }

  void seleccionarCategoria(String categoria) {
    if (categoria == _categoria) return;
    _categoria = categoria;
    notifyListeners();
  }

  /// Normaliza el texto (minúsculas y sin tildes) para que "refrigeracion" coincida con "Refrigeración".
  static String _normalizar(String s) {
    const conTilde = 'áéíóúüàèìòùñ';
    const sinTilde = 'aeiouuaeioun';
    final buffer = StringBuffer();
    for (final ch in s.toLowerCase().split('')) {
      final i = conTilde.indexOf(ch);
      buffer.write(i == -1 ? ch : sinTilde[i]);
    }
    return buffer.toString();
  }

  int get totalUnidades => _items.fold(0, (suma, e) => suma + e.stock);

  Future<void> cargar() async {
    _cargando = true;
    _error = null;
    notifyListeners();
    try {
      _items = await _repo.obtenerTodos();
    } catch (e) {
      _error = 'No se pudo cargar el inventario: $e';
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  Future<void> guardar(Electrodomestico e) async {
    await _repo.guardar(e);
    await cargar();
  }

  Future<void> eliminar(Electrodomestico e) async {
    if (e.id == null) return;
    await _repo.eliminar(e.id!);
    _items.removeWhere((x) => x.id == e.id);
    notifyListeners();
  }

  /// Control rápido de stock (+1 / -1) con actualización optimista:
  /// el cambio se refleja de inmediato en la interfaz y se revierte si falla la persistencia.
  Future<void> ajustarStock(Electrodomestico e, int delta) async {
    final nuevo = e.stock + delta;
    if (e.id == null || nuevo < 0) return; // Regla de negocio: el stock no admite valores negativos.

    final index = _items.indexWhere((x) => x.id == e.id);
    if (index == -1) return;

    final anterior = _items[index];
    _items[index] = anterior.copyWith(stock: nuevo);
    notifyListeners();

    try {
      await _repo.actualizarStock(e.id!, nuevo);
    } catch (err) {
      _items[index] = anterior;
      _error = 'No se pudo actualizar el stock';
      notifyListeners();
    }
  }
}
