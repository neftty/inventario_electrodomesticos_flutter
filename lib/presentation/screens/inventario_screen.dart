import 'package:flutter/material.dart';

import '../../data/models/electrodomestico.dart';
import '../controllers/inventario_controller.dart';
import '../widgets/electrodomestico_card.dart';
import 'formulario_screen.dart';

class InventarioScreen extends StatefulWidget {
  const InventarioScreen({super.key, required this.controller});

  final InventarioController controller;

  @override
  State<InventarioScreen> createState() => _InventarioScreenState();
}

class _InventarioScreenState extends State<InventarioScreen> {
  InventarioController get _ctrl => widget.controller;
  late final TextEditingController _busquedaCtrl;

  @override
  void initState() {
    super.initState();
    _busquedaCtrl = TextEditingController(text: _ctrl.busqueda);
    _ctrl.cargar();
  }

  @override
  void dispose() {
    _busquedaCtrl.dispose();
    super.dispose();
  }

  void _limpiarBusqueda() {
    _busquedaCtrl.clear();
    _ctrl.buscar('');
  }

  Future<void> _abrirFormulario([Electrodomestico? existente]) async {
    final resultado = await Navigator.of(context).push<Electrodomestico>(
      MaterialPageRoute(
        builder: (_) => FormularioScreen(electrodomestico: existente),
      ),
    );
    if (resultado == null) return; // Operación cancelada por el usuario.

    await _ctrl.guardar(resultado);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(existente == null
            ? '"${resultado.nombre}" registrado'
            : '"${resultado.nombre}" actualizado'),
      ),
    );
  }

  Future<void> _confirmarEliminar(Electrodomestico e) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar electrodoméstico'),
        content: Text('¿Seguro que quieres eliminar "${e.nombre}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmado == true) await _ctrl.eliminar(e);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventario'),
        actions: [
          ListenableBuilder(
            listenable: _ctrl,
            builder: (context, _) => Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(child: Text('${_ctrl.totalUnidades} uds.')),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(116),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: _BarraBusqueda(
                  controller: _busquedaCtrl,
                  onChanged: _ctrl.buscar,
                  onLimpiar: _limpiarBusqueda,
                ),
              ),
              ListenableBuilder(
                listenable: _ctrl,
                builder: (context, _) => _FiltroCategorias(
                  seleccionada: _ctrl.categoriaSeleccionada,
                  onSeleccionar: _ctrl.seleccionarCategoria,
                ),
              ),
            ],
          ),
        ),
      ),
      body: ListenableBuilder(
        listenable: _ctrl,
        builder: (context, _) {
          if (_ctrl.cargando && _ctrl.items.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (_ctrl.error != null && _ctrl.items.isEmpty) {
            return Center(child: Text(_ctrl.error!));
          }
          if (_ctrl.items.isEmpty) {
            return const _EstadoVacio();
          }
          final visibles = _ctrl.itemsFiltrados;
          if (visibles.isEmpty) {
            return const _SinResultados();
          }
          return RefreshIndicator(
            onRefresh: _ctrl.cargar,
            child: ListView.builder(
              padding: const EdgeInsets.only(top: 8, bottom: 96),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              itemCount: visibles.length,
              itemBuilder: (context, i) {
                final item = visibles[i];
                return ElectrodomesticoCard(
                  key: ValueKey(item.id),
                  item: item,
                  onTap: () => _abrirFormulario(item),
                  onEliminar: () => _confirmarEliminar(item),
                  onIncrementar: () => _ctrl.ajustarStock(item, 1),
                  onDecrementar: () => _ctrl.ajustarStock(item, -1),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _abrirFormulario(),
        icon: const Icon(Icons.add),
        label: const Text('Agregar'),
      ),
    );
  }
}

class _BarraBusqueda extends StatelessWidget {
  const _BarraBusqueda({
    required this.controller,
    required this.onChanged,
    required this.onLimpiar,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onLimpiar;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return TextField(
      controller: controller,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: 'Buscar por nombre o marca',
        prefixIcon: const Icon(Icons.search),
        // El botón de limpieza ("X") solo se muestra cuando el campo contiene texto.
        suffixIcon: ValueListenableBuilder<TextEditingValue>(
          valueListenable: controller,
          builder: (context, value, _) => value.text.isEmpty
              ? const SizedBox.shrink()
              : IconButton(
                  tooltip: 'Limpiar',
                  icon: const Icon(Icons.close),
                  onPressed: onLimpiar,
                ),
        ),
        filled: true,
        fillColor: scheme.surfaceContainerHighest,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class _FiltroCategorias extends StatelessWidget {
  const _FiltroCategorias({
    required this.seleccionada,
    required this.onSeleccionar,
  });

  final String seleccionada;
  final ValueChanged<String> onSeleccionar;

  @override
  Widget build(BuildContext context) {
    const opciones = InventarioController.filtrosCategoria;
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: opciones.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final opcion = opciones[i];
          return Center(
            child: ChoiceChip(
              label: Text(opcion),
              selected: opcion == seleccionada,
              onSelected: (_) => onSeleccionar(opcion),
            ),
          );
        },
      ),
    );
  }
}

class _SinResultados extends StatelessWidget {
  const _SinResultados();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off, size: 64, color: scheme.outline),
          const SizedBox(height: 12),
          const Text('No se encontraron electrodomésticos'),
        ],
      ),
    );
  }
}

class _EstadoVacio extends StatelessWidget {
  const _EstadoVacio();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.kitchen_outlined, size: 64, color: scheme.outline),
          const SizedBox(height: 12),
          const Text('Todavía no hay electrodomésticos registrados'),
        ],
      ),
    );
  }
}
