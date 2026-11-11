import '../models/electrodomestico.dart';

/// Catálogo inicial (seeding) persistido en SQLite.
/// Precios expresados en pesos colombianos (COP).
const List<Electrodomestico> datosIniciales = [
  // Producto agotado (stock = 0): activa la alerta visual "Agotado".
  Electrodomestico(nombre: "Aire acondicionado", marca: "Mabe", categoria: "Climatización", precio: 1000000, stock: 0),
  // Producto con stock bajo (1 a 3 unidades): activa la alerta visual "Stock bajo".
  Electrodomestico(nombre: "Nevera", marca: "Mabe", categoria: "Refrigeración", precio: 200000, stock: 2),
  // Producto con stock suficiente (> 3 unidades): no genera alerta.
  Electrodomestico(nombre: "Televisor 50'", marca: "LG", categoria: "Entretenimiento", precio: 1850000, stock: 5),
];
