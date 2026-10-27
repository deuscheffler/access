import 'package:flutter/material.dart';

import '../almacen.dart';
import '../formato.dart';
import '../modelos.dart';
import '../tema.dart';

/// Nómina que viaja dentro de la app. Es de solo lectura: para actualizarla
/// se regenera assets/nomina.json con tool/convertir_nominas.py.
class PaginaEstudiantes extends StatefulWidget {
  const PaginaEstudiantes({super.key});

  @override
  State<PaginaEstudiantes> createState() => _PaginaEstudiantesState();
}

class _PaginaEstudiantesState extends State<PaginaEstudiantes> {
  final _buscar = TextEditingController();
  String _filtro = '';

  @override
  void dispose() {
    _buscar.dispose();
    super.dispose();
  }

  static String _normalizar(String s) => normalizar(s);

  @override
  Widget build(BuildContext context) {
    final a = Almacen.i;
    final cursos = a.cursos;
    final filtro = _normalizar(_filtro.trim());
    final resultados = filtro.isEmpty
        ? const <Estudiante>[]
        : a.estudiantes
            .where((e) => _normalizar(e.nombre).contains(filtro))
            .take(100)
            .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Nómina')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          TextField(
            controller: _buscar,
            onChanged: (v) => setState(() => _filtro = v),
            decoration: InputDecoration(
              hintText: 'Buscar estudiante por nombre o apellido',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _filtro.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        _buscar.clear();
                        setState(() => _filtro = '');
                      },
                    ),
            ),
          ),
          const SizedBox(height: 12),
          if (filtro.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 8),
              child: Text(
                resultados.isEmpty
                    ? 'Nadie coincide con «${_filtro.trim()}».'
                    : '${resultados.length} coincidencias',
                style: const TextStyle(color: Paleta.pizarra),
              ),
            ),
            for (final e in resultados)
              Container(
                margin: const EdgeInsets.only(bottom: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  title: Text(e.nombre),
                  subtitle: Text(e.curso),
                ),
              ),
          ] else ...[
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 12),
              child: Text(
                '${a.estudiantes.length} estudiantes en ${cursos.length} '
                'cursos, periodo ${a.periodo}',
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
                          fontSize: 17,
                          color: Paleta.tinta,
                        ),
                      ),
                      subtitle: Text('${lista.length} estudiantes',
                          style: const TextStyle(color: Paleta.pizarra)),
                      children: [
                        for (var k = 0; k < lista.length; k++)
                          ListTile(
                            dense: true,
                            leading: Text(
                              '${k + 1}',
                              style: const TextStyle(color: Paleta.pizarra),
                            ),
                            title: Text(lista[k].nombre,
                                style: const TextStyle(fontSize: 16)),
                          ),
                      ],
                    );
                  }),
                ),
              ),
          ],
        ],
      ),
    );
  }
}
