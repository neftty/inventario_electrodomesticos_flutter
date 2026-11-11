import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/models/electrodomestico.dart';

/// Formulario de registro y edición. No accede a la base de datos: retorna el objeto
/// mediante Navigator.pop y delega su procesamiento en la pantalla principal.
class FormularioScreen extends StatefulWidget {
  const FormularioScreen({super.key, this.electrodomestico});

  /// Un valor nulo indica modo registro; un valor no nulo indica modo edición.
  final Electrodomestico? electrodomestico;

  @override
  State<FormularioScreen> createState() => _FormularioScreenState();
}

class _FormularioScreenState extends State<FormularioScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nombreCtrl;
  late final TextEditingController _marcaCtrl;
  late final TextEditingController _precioCtrl;
  late final TextEditingController _stockCtrl;
  String? _categoria;

  bool get _esEdicion => widget.electrodomestico != null;

  @override
  void initState() {
    super.initState();
    final e = widget.electrodomestico;
    _nombreCtrl = TextEditingController(text: e?.nombre ?? '');
    _marcaCtrl = TextEditingController(text: e?.marca ?? '');
    _precioCtrl = TextEditingController(text: e != null ? e.precio.round().toString() : '');
    _stockCtrl = TextEditingController(text: e?.stock.toString() ?? '0');
    _categoria = e?.categoria;
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _marcaCtrl.dispose();
    _precioCtrl.dispose();
    _stockCtrl.dispose();
    super.dispose();
  }

  // ---------- Validaciones ----------

  String? _requerido(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Campo obligatorio' : null;

  String? _validarPrecio(String? v) {
    final base = _requerido(v);
    if (base != null) return base;
    final precio = double.tryParse(v!.trim());
    if (precio == null) return 'Precio inválido';
    if (precio <= 0) return 'El precio debe ser mayor a 0';
    return null;
  }

  String? _validarStock(String? v) {
    final base = _requerido(v);
    if (base != null) return base;
    final stock = int.tryParse(v!.trim());
    if (stock == null) return 'Stock inválido';
    if (stock < 0) return 'El stock no puede ser negativo';
    return null;
  }

  void _guardar() {
    if (!_formKey.currentState!.validate()) return;

    final resultado = Electrodomestico(
      id: widget.electrodomestico?.id,
      nombre: _nombreCtrl.text.trim(),
      marca: _marcaCtrl.text.trim(),
      categoria: _categoria!,
      precio: double.parse(_precioCtrl.text.trim()),
      stock: int.parse(_stockCtrl.text.trim()),
    );
    Navigator.of(context).pop(resultado);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_esEdicion ? 'Editar electrodoméstico' : 'Nuevo electrodoméstico'),
      ),
      body: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nombreCtrl,
              decoration: const InputDecoration(
                labelText: 'Nombre *',
                hintText: 'Ej: Nevera No Frost 300L',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.next,
              validator: _requerido,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _marcaCtrl,
              decoration: const InputDecoration(
                labelText: 'Marca *',
                hintText: 'Ej: Samsung',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              validator: _requerido,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _categoria,
              decoration: const InputDecoration(
                labelText: 'Categoría *',
                border: OutlineInputBorder(),
              ),
              items: Electrodomestico.categorias
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) => setState(() => _categoria = v),
              validator: (v) => v == null ? 'Selecciona una categoría' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _precioCtrl,
              decoration: const InputDecoration(
                labelText: 'Precio (COP) *',
                prefixText: '\$ ',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              textInputAction: TextInputAction.next,
              validator: _validarPrecio,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _stockCtrl,
              decoration: const InputDecoration(
                labelText: 'Stock *',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: _validarStock,
              onFieldSubmitted: (_) => _guardar(),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _guardar,
              icon: const Icon(Icons.save_outlined),
              label: Text(_esEdicion ? 'Guardar cambios' : 'Registrar'),
            ),
          ],
        ),
      ),
    );
  }
}
