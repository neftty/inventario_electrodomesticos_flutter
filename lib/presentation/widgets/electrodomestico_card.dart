import 'package:flutter/material.dart';

import '../../data/models/electrodomestico.dart';

class ElectrodomesticoCard extends StatelessWidget {
  const ElectrodomesticoCard({
    super.key,
    required this.item,
    required this.onTap,
    required this.onEliminar,
    required this.onIncrementar,
    required this.onDecrementar,
  });

  final Electrodomestico item;
  final VoidCallback onTap;
  final VoidCallback onEliminar;
  final VoidCallback onIncrementar;
  final VoidCallback onDecrementar;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.nombre,
                        style: text.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text('${item.marca} · ${item.categoria}',
                        style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
                    const SizedBox(height: 6),
                    Text(formatearPrecio(item.precio),
                        style: text.bodyLarge?.copyWith(color: scheme.primary)),
                    if (item.stockBajo) ...[
                      const SizedBox(height: 6),
                      Chip(
                        label: Text(item.stock == 0 ? 'Agotado' : 'Stock bajo'),
                        visualDensity: VisualDensity.compact,
                        backgroundColor: scheme.errorContainer,
                        labelStyle: TextStyle(color: scheme.onErrorContainer),
                        side: BorderSide.none,
                      ),
                    ],
                  ],
                ),
              ),
              _ControlStock(
                stock: item.stock,
                onIncrementar: onIncrementar,
                onDecrementar: item.stock > 0 ? onDecrementar : null,
              ),
              IconButton(
                tooltip: 'Eliminar',
                icon: const Icon(Icons.delete_outline),
                onPressed: onEliminar,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ControlStock extends StatelessWidget {
  const _ControlStock({
    required this.stock,
    required this.onIncrementar,
    required this.onDecrementar,
  });

  final int stock;
  final VoidCallback onIncrementar;
  final VoidCallback? onDecrementar; // Valor nulo: botón deshabilitado.

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton.filledTonal(
          tooltip: 'Agregar unidad',
          icon: const Icon(Icons.add),
          onPressed: onIncrementar,
        ),
        Text('$stock', style: Theme.of(context).textTheme.titleMedium),
        IconButton.filledTonal(
          tooltip: 'Quitar unidad',
          icon: const Icon(Icons.remove),
          onPressed: onDecrementar,
        ),
      ],
    );
  }
}

/// Formato de moneda en pesos colombianos sin dependencia de `intl`: 1500000 -> $1.500.000
String formatearPrecio(double valor) {
  final digitos = valor.round().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digitos.length; i++) {
    if (i > 0 && (digitos.length - i) % 3 == 0) buffer.write('.');
    buffer.write(digitos[i]);
  }
  return '\$$buffer';
}
