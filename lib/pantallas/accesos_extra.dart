import 'package:flutter/material.dart';

import '../almacen.dart';
import '../tema.dart';
import 'pases.dart';

/// Crea un acceso adicional: un estudiante que aún no está en la nómina,
/// un invitado especial (autoridad, prensa, proveedor) o un pase extra para
/// un estudiante. El nombre y el detalle viajan dentro del QR.
class FormularioAccesoExtra extends StatefulWidget {
  final String eventoId;
  final String nombreInicial;
  final String detalleInicial;

  const FormularioAccesoExtra({
    super.key,
    required this.eventoId,
    this.nombreInicial = '',
    this.detalleInicial = '',
  });

  @override
  State<FormularioAccesoExtra> createState() => _FormularioAccesoExtraState();
}

class _FormularioAccesoExtraState extends State<FormularioAccesoExtra> {
  late final TextEditingController _nombre;
  late final TextEditingController _detalle;
  int _cantidad = 1;
  String? _error;

  static const _sugerencias = [
    'Estudiante nuevo',
    'Autoridad',
    'Docente',
    'Prensa',
    'Invitado especial',
  ];

  @override
  void initState() {
    super.initState();
    _nombre = TextEditingController(text: widget.nombreInicial);
    _detalle = TextEditingController(text: widget.detalleInicial);
  }

  @override
  void dispose() {
    _nombre.dispose();
    _detalle.dispose();
    super.dispose();
  }

  void _guardar() {
    final ev = Almacen.i.eventoPorId(widget.eventoId);
    final nombre = _nombre.text.trim();
    if (ev == null) return;
    if (nombre.isEmpty) {
      setState(() => _error = 'Escribe el nombre de la persona.');
      return;
    }
    final x = Almacen.i.crearExtra(
      ev,
      nombre: nombre,
      detalle: _detalle.text.trim(),
      total: _cantidad,
    );
    Navigator.of(context).pushReplacement(MaterialPageRoute<void>(
      builder: (_) => PasesExtra(eventoId: ev.id, accesoId: x.id),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Agregar acceso')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
        children: [
          const Text(
            'Para un estudiante que no está en la nómina, una autoridad o '
            'un invitado. Su nombre queda dentro del código, así que '
            'cualquier celular de la puerta lo reconoce.',
            style: TextStyle(color: Paleta.pizarra, height: 1.4),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _nombre,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Nombre',
              hintText: 'Ej.: Pérez Gómez Ana Lucía',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _detalle,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Detalle (curso, cargo o motivo)',
              hintText: 'Ej.: 5.º A matutina',
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (final s in _sugerencias)
                ActionChip(
                  label: Text(s),
                  onPressed: () => setState(() => _detalle.text = s),
                ),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            'Número de pases',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: Paleta.tinta,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                IconButton(
                  onPressed:
                      _cantidad > 1 ? () => setState(() => _cantidad--) : null,
                  icon: const Icon(Icons.remove_circle_outline),
                ),
                Expanded(
                  child: Text(
                    '$_cantidad',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'BarlowCondensed',
                      fontWeight: FontWeight.w800,
                      fontSize: 34,
                      color: Paleta.tinta,
                    ),
                  ),
                ),
                IconButton(
                  onPressed:
                      _cantidad < 10 ? () => setState(() => _cantidad++) : null,
                  icon: const Icon(Icons.add_circle_outline),
                ),
              ],
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: Paleta.alto)),
          ],
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: FilledButton(
            onPressed: _guardar,
            child: Text(_cantidad == 1
                ? 'Crear 1 pase'
                : 'Crear $_cantidad pases'),
          ),
        ),
      ),
    );
  }
}
