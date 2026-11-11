import 'package:flutter/material.dart';

import 'data/datasources/database_helper.dart';
import 'data/repositories/electrodomestico_repository.dart';
import 'presentation/controllers/inventario_controller.dart';
import 'presentation/screens/inventario_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Inyección manual de dependencias: datasource -> repositorio -> controlador.
  final repository = ElectrodomesticoRepository(DatabaseHelper.instance);
  final controller = InventarioController(repository);

  runApp(InventarioApp(controller: controller));
}

class InventarioApp extends StatelessWidget {
  const InventarioApp({super.key, required this.controller});

  final InventarioController controller;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Inventario de Electrodomésticos',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
      ),
      home: InventarioScreen(controller: controller),
    );
  }
}
