import 'package:flutter/material.dart';

import '../almacen.dart';
import '../tema.dart';

class PaginaEstudiantes extends StatelessWidget {
  const PaginaEstudiantes({super.key});

  @override
  Widget build(BuildContext context) {
    final a = Almacen.i;
    return Scaffold(
      appBar: AppBar(title: const Text('Estudiantes')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          showDragHandle: true,
          builder: (_) => const _FormularioEstudiante(),
        ),
        backgroundColor: Paleta.tinta,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add_alt),
        label: const Text('Agregar',
            style: TextStyle(fontWeight: FontWeight.w600)),
      ),
      body: ListenableBuilder(
        listenable: a,
        builder: (context, _) {
          final cursos = a.cursos();
          if (cursos.isEmpty) {
            return EstadoVacio(
              icono: Icons.groups_outlined,
              titulo: 'Agrega estudiantes',
              texto: 'Regístralos uno por uno con el botón Agregar, o carga '
                  'datos de prueba para ver la app funcionando.',
              accion: FilledButton(
                onPressed: a.cargarDatosPrueba,
                child: const Text('Cargar datos de prueba'),
              ),
            );
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 12),
                child: Text(
                  '${a.estudiantes.length} estudiantes en ${cursos.length} paralelos',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Paleta.pizarra,
                  ),
                ),
              ),
              for (final c in cursos)
                Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Theme(
                    data: Theme.of(context)
                        .copyWith(dividerColor: Colors.transparent),
                    child: Builder(builder: (context) {
                      final lista = a.estudiantesDeCurso(c.clave);
                      return ExpansionTile(
                        title: Text(
                          c.nombre,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                            color: Paleta.tinta,
                          ),
                        ),
                        subtitle: Text('${lista.length} estudiantes',
                            style: const TextStyle(color: Paleta.pizarra)),
                        children: [
                          for (final e in lista)
                            ListTile(
                              dense: true,
                              title: Text('${e.apellidos}, ${e.nombres}',
                                  style: const TextStyle(fontSize: 16)),
                            ),
                        ],
                      );
                    }),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _FormularioEstudiante extends StatefulWidget {
  const _FormularioEstudiante();

  @override
  State<_FormularioEstudiante> createState() => _FormularioEstudianteState();
}

class _FormularioEstudianteState extends State<_FormularioEstudiante> {
  final _nombres = TextEditingController();
  final _apellidos = TextEditingController();
  final _grado = TextEditingController();
  final _paralelo = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _nombres.dispose();
    _apellidos.dispose();
    _grado.dispose();
    _paralelo.dispose();
    super.dispose();
  }

  void _guardar() {
    final n = _nombres.text.trim();
    final ap = _apellidos.text.trim();
    final g = _grado.text.trim();
    final p = _paralelo.text.trim().toUpperCase();
    if (n.isEmpty || ap.isEmpty || g.isEmpty || p.isEmpty) {
      setState(() => _error = 'Completa los cuatro campos.');
      return;
    }
    Almacen.i.agregarEstudiante(
        nombres: n, apellidos: ap, grado: g, paralelo: p);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final inferior = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + inferior),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Nuevo estudiante',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Paleta.tinta,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _nombres,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(labelText: 'Nombres'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _apellidos,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(labelText: 'Apellidos'),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _grado,
                  decoration: const InputDecoration(
                    labelText: 'Grado',
                    hintText: '5.º',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _paralelo,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                    labelText: 'Paralelo',
                    hintText: 'A',
                  ),
                ),
              ),
            ],
          ),
          if (_error != null) ...[
            const SizedBox(height: 10),
            Text(_error!, style: const TextStyle(color: Paleta.alto)),
          ],
          const SizedBox(height: 20),
          FilledButton(onPressed: _guardar, child: const Text('Guardar')),
        ],
      ),
    );
  }
}
