import 'package:flutter_test/flutter_test.dart';
import 'package:inventario_electrodomesticos/data/datasources/database_helper.dart';
import 'package:inventario_electrodomesticos/data/datasources/datos_iniciales.dart';
import 'package:inventario_electrodomesticos/data/models/electrodomestico.dart';
import 'package:inventario_electrodomesticos/data/repositories/electrodomestico_repository.dart';
import 'package:inventario_electrodomesticos/presentation/controllers/inventario_controller.dart';

/// Repositorio en memoria que sustituye a SQLite durante las pruebas.
/// Permite validar la lógica del controlador sin acceder a la base de datos.
class RepositorioFalso extends ElectrodomesticoRepository {
  RepositorioFalso(this.datos, {this.fallarAlActualizar = false})
      : super(DatabaseHelper.instance);

  final List<Electrodomestico> datos;
  final bool fallarAlActualizar;
  final List<int> stocksPersistidos = [];

  @override
  Future<List<Electrodomestico>> obtenerTodos() async => List.of(datos);

  @override
  Future<void> actualizarStock(int id, int nuevoStock) async {
    if (fallarAlActualizar) throw Exception('Fallo simulado de persistencia');
    stocksPersistidos.add(nuevoStock);
  }
}

Electrodomestico producto({int id = 1, int stock = 5, String nombre = 'Nevera', String marca = 'Mabe', String categoria = 'Refrigeración'}) {
  return Electrodomestico(
    id: id,
    nombre: nombre,
    marca: marca,
    categoria: categoria,
    precio: 100000,
    stock: stock,
  );
}

Future<InventarioController> controladorCon(RepositorioFalso repo) async {
  final controlador = InventarioController(repo);
  await controlador.cargar();
  return controlador;
}

void main() {
  group('Regla de stock bajo (stock <= 3)', () {
    test('El umbral de stock bajo es 3 unidades', () {
      expect(Electrodomestico.umbralStockBajo, 3);
    });

    test('Stock de 1, 2 y 3 unidades se clasifica como stock bajo', () {
      for (final s in [1, 2, 3]) {
        expect(producto(stock: s).stockBajo, isTrue, reason: 'stock = $s');
      }
    });

    test('Stock mayor a 3 unidades no genera alerta', () {
      expect(producto(stock: 4).stockBajo, isFalse);
      expect(producto(stock: 50).stockBajo, isFalse);
    });
  });

  group('Producto agotado (stock = 0)', () {
    test('Un producto con stock 0 también activa la alerta', () {
      final agotado = producto(stock: 0);
      expect(agotado.stock, 0);
      expect(agotado.stockBajo, isTrue);
    });

    test('El catálogo inicial contiene exactamente un producto agotado', () {
      final agotados = datosIniciales.where((e) => e.stock == 0).toList();
      expect(agotados, hasLength(1));
      expect(agotados.first.nombre, 'Aire acondicionado');
    });
  });

  group('No negatividad de existencias', () {
    test('El controlador no decrementa un producto agotado', () async {
      final repo = RepositorioFalso([producto(stock: 0)]);
      final controlador = await controladorCon(repo);

      await controlador.ajustarStock(controlador.items.first, -1);

      expect(controlador.items.first.stock, 0);
      expect(repo.stocksPersistidos, isEmpty);
    });

    test('El controlador incrementa y decrementa el stock correctamente', () async {
      final repo = RepositorioFalso([producto(stock: 1)]);
      final controlador = await controladorCon(repo);

      await controlador.ajustarStock(controlador.items.first, -1);
      expect(controlador.items.first.stock, 0);

      await controlador.ajustarStock(controlador.items.first, 1);
      expect(controlador.items.first.stock, 1);
      expect(repo.stocksPersistidos, [0, 1]);
    });

    test('El repositorio rechaza un stock negativo con ArgumentError', () {
      final repo = ElectrodomesticoRepository(DatabaseHelper.instance);
      expect(() => repo.actualizarStock(1, -1), throwsArgumentError);
    });

    test('La actualización optimista se revierte si falla la persistencia', () async {
      final repo = RepositorioFalso([producto(stock: 2)], fallarAlActualizar: true);
      final controlador = await controladorCon(repo);

      await controlador.ajustarStock(controlador.items.first, 1);

      expect(controlador.items.first.stock, 2);
      expect(controlador.error, isNotNull);
    });
  });

  group('Normalización de búsqueda', () {
    late InventarioController controlador;

    setUp(() async {
      controlador = await controladorCon(RepositorioFalso([
        producto(id: 1, nombre: 'Nevera', marca: 'Mabe', categoria: 'Refrigeración'),
        producto(id: 2, nombre: 'Televisor 50\'', marca: 'LG', categoria: 'Entretenimiento'),
        producto(id: 3, nombre: 'Aire acondicionado', marca: 'Mabe', categoria: 'Climatización'),
        producto(id: 4, nombre: 'Cafetera eléctrica', marca: 'Oster', categoria: 'Pequeños electrodomésticos'),
      ]));
    });

    List<String> nombresVisibles() =>
        controlador.itemsFiltrados.map((e) => e.nombre).toList();

    test('La búsqueda ignora mayúsculas', () {
      controlador.buscar('NEVERA');
      expect(nombresVisibles(), ['Nevera']);
    });

    test('La búsqueda ignora tildes', () {
      controlador.buscar('electrica');
      expect(nombresVisibles(), ['Cafetera eléctrica']);
    });

    test('Un texto con tilde encuentra un registro sin tilde', () {
      controlador.buscar('NÉVERA');
      expect(nombresVisibles(), ['Nevera']);
    });

    test('La búsqueda también considera la marca', () {
      controlador.buscar('mabe');
      expect(nombresVisibles(), containsAll(['Nevera', 'Aire acondicionado']));
      expect(nombresVisibles(), hasLength(2));
    });

    test('La búsqueda por coincidencia parcial "te" encuentra el televisor', () {
      controlador.buscar('te');
      expect(nombresVisibles(), contains('Televisor 50\''));
    });

    test('Búsqueda y filtro de categoría se combinan', () {
      controlador.buscar('mabe');
      controlador.seleccionarCategoria('Climatización');
      expect(nombresVisibles(), ['Aire acondicionado']);
    });

    test('Una búsqueda sin coincidencias retorna una lista vacía', () {
      controlador.buscar('lavadora');
      expect(nombresVisibles(), isEmpty);
    });
  });

  group('Catálogo inicial (seeding)', () {
    test('Contiene exactamente los 3 productos base', () {
      expect(datosIniciales.map((e) => e.nombre).toList(),
          ['Aire acondicionado', 'Nevera', 'Televisor 50\'']);
    });

    test('Todas las categorías del catálogo son válidas', () {
      for (final e in datosIniciales) {
        expect(Electrodomestico.categorias, contains(e.categoria));
      }
    });
  });
}
