class Electrodomestico {
  const Electrodomestico({
    this.id,
    required this.nombre,
    required this.marca,
    required this.categoria,
    required this.precio,
    required this.stock,
  });

  /// Nulo mientras el registro no se haya persistido; SQLite lo genera automáticamente.
  final int? id;
  final String nombre;
  final String marca;
  final String categoria;
  final double precio;
  final int stock;

  /// Categorías permitidas. Regla de negocio: el formulario restringe la selección a estos valores.
  static const List<String> categorias = [
    'Refrigeración',
    'Lavado',
    'Cocina',
    'Climatización',
    'Entretenimiento',
    'Pequeños electrodomésticos',
  ];

  /// Umbral a partir del cual un producto se clasifica como "stock bajo".
  static const int umbralStockBajo = 3;

  bool get stockBajo => stock <= umbralStockBajo;

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'nombre': nombre,
      'marca': marca,
      'categoria': categoria,
      'precio': precio,
      'stock': stock,
    };
  }

  factory Electrodomestico.fromMap(Map<String, dynamic> map) {
    return Electrodomestico(
      id: map['id'] as int?,
      nombre: map['nombre'] as String,
      marca: map['marca'] as String,
      categoria: map['categoria'] as String,
      // SQLite puede retornar valores REAL como int cuando carecen de parte decimal.
      precio: (map['precio'] as num).toDouble(),
      stock: map['stock'] as int,
    );
  }

  Electrodomestico copyWith({
    int? id,
    String? nombre,
    String? marca,
    String? categoria,
    double? precio,
    int? stock,
  }) {
    return Electrodomestico(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      marca: marca ?? this.marca,
      categoria: categoria ?? this.categoria,
      precio: precio ?? this.precio,
      stock: stock ?? this.stock,
    );
  }

  @override
  String toString() =>
      'Electrodomestico(id: $id, nombre: $nombre, marca: $marca, '
      'categoria: $categoria, precio: $precio, stock: $stock)';
}
