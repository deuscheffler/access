import 'package:flutter/material.dart';

import '../almacen.dart';
import '../formato.dart';
import '../modelos.dart';
import '../tema.dart';
import 'escaner.dart';
import 'pases.dart';

// =============================================================
// Lista de eventos
// =============================================================

class PaginaEventos extends StatelessWidget {
  const PaginaEventos({super.key});

  @override
  Widget build(BuildContext context) {
    final a = Almacen.i;
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            LogoOmega(tamano: 30, sobreOscuro: true),
            SizedBox(width: 12),
            Text('Omega Access Control'),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (v) => _menu(context, v),
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'prueba', child: Text('Cargar datos de prueba')),
              PopupMenuItem(value: 'borrar', child: Text('Borrar todos los datos')),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _nuevoEvento(context),
        backgroundColor: Paleta.tinta,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Nuevo evento',
            style: TextStyle(fontWeight: FontWeight.w600)),
      ),
      body: ListenableBuilder(
        listenable: a,
        builder: (context, _) {
          if (a.eventos.isEmpty) {
            return EstadoVacio(
              icono: Icons.event_available_outlined,
              titulo: 'Crea tu primer evento',
              texto: 'O carga datos de prueba: 180 estudiantes de 5.º a 7.º '
                  'y una inauguración deportiva lista para generar pases.',
              accion: FilledButton.icon(
                onPressed: a.cargarDatosPrueba,
                icon: const Icon(Icons.auto_awesome_outlined),
                label: const Text('Cargar datos de prueba'),
              ),
            );
          }
          final lista = [...a.eventos]
            ..sort((x, y) => x.fecha.compareTo(y.fecha));
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            itemCount: lista.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, i) => _TarjetaEvento(evento: lista[i]),
          );
        },
      ),
    );
  }

  Future<void> _menu(BuildContext context, String opcion) async {
    final a = Almacen.i;
    if (opcion == 'prueba') {
      a.cargarDatosPrueba();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Se cargaron 180 estudiantes y un evento de prueba.')));
    } else if (opcion == 'borrar') {
      final ok = await confirmar(
        context,
        titulo: 'Borrar todos los datos',
        texto: 'Se eliminarán eventos, estudiantes, pases y el registro. '
            'No se puede deshacer.',
        accion: 'Borrar todo',
      );
      if (ok) a.borrarTodo();
    }
  }

  Future<void> _nuevoEvento(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const _FormularioEvento(),
    );
  }
}

class _TarjetaEvento extends StatelessWidget {
  final Evento evento;
  const _TarjetaEvento({required this.evento});

  @override
  Widget build(BuildContext context) {
    final pases = Almacen.i.pasesDeEvento(evento.id);
    final usados = pases.where((p) => p.usado).length;
    final avance = pases.isEmpty ? 0.0 : usados / pases.length;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
          builder: (_) => DetalleEvento(eventoId: evento.id),
        )),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                evento.nombre,
                style: const TextStyle(
                  fontFamily: 'BarlowCondensed',
                  fontWeight: FontWeight.w700,
                  fontSize: 26,
                  height: 1.1,
                  color: Paleta.tinta,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                evento.lugar.isEmpty
                    ? fechaLarga(evento.fecha)
                    : '${fechaLarga(evento.fecha)}, ${evento.lugar}',
                style: const TextStyle(fontSize: 15, color: Paleta.pizarra),
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: avance,
                  minHeight: 6,
                  backgroundColor: Paleta.niebla,
                  color: Paleta.paso,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                pases.isEmpty
                    ? 'Aún no hay pases generados'
                    : 'Ingresaron $usados de ${pases.length} pases',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Paleta.pizarra,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FormularioEvento extends StatefulWidget {
  const _FormularioEvento();

  @override
  State<_FormularioEvento> createState() => _FormularioEventoState();
}

class _FormularioEventoState extends State<_FormularioEvento> {
  final _nombre = TextEditingController();
  final _lugar = TextEditingController();
  DateTime _fecha = DateTime.now();

  @override
  void dispose() {
    _nombre.dispose();
    _lugar.dispose();
    super.dispose();
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
            'Nuevo evento',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Paleta.tinta,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _nombre,
            autofocus: true,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(labelText: 'Nombre del evento'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _lugar,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(labelText: 'Lugar (opcional)'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () async {
              final elegida = await showDatePicker(
                context: context,
                initialDate: _fecha,
                firstDate: DateTime.now().subtract(const Duration(days: 30)),
                lastDate: DateTime.now().add(const Duration(days: 730)),
              );
              if (elegida != null) setState(() => _fecha = elegida);
            },
            icon: const Icon(Icons.calendar_today_outlined),
            label: Text(fechaLarga(_fecha)),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: () {
              final nombre = _nombre.text.trim();
              if (nombre.isEmpty) return;
              Almacen.i.crearEvento(
                nombre: nombre,
                lugar: _lugar.text.trim(),
                fecha: _fecha,
              );
              Navigator.of(context).pop();
            },
            child: const Text('Crear evento'),
          ),
        ],
      ),
    );
  }
}

// =============================================================
// Detalle del evento
// =============================================================

class DetalleEvento extends StatelessWidget {
  final String eventoId;
  const DetalleEvento({super.key, required this.eventoId});

  @override
  Widget build(BuildContext context) {
    final a = Almacen.i;
    return ListenableBuilder(
      listenable: a,
      builder: (context, _) {
        final ev = a.eventoPorId(eventoId);
        if (ev == null) {
          return const Scaffold(body: SizedBox.shrink());
        }
        final pases = a.pasesDeEvento(ev.id);
        final usados = pases.where((p) => p.usado).length;

        // Agrupa estudiantes con pases por curso.
        final porEstudiante = <String, List<Pase>>{};
        for (final p in pases) {
          porEstudiante.putIfAbsent(p.estudianteId, () => []).add(p);
        }
        final cursos = <String, Curso>{};
        final estudiantesPorCurso = <String, List<Estudiante>>{};
        for (final id in porEstudiante.keys) {
          final e = a.estudiantePorId(id);
          if (e == null) continue;
          cursos.putIfAbsent(e.claveCurso, () => Curso(e.grado, e.paralelo));
          estudiantesPorCurso.putIfAbsent(e.claveCurso, () => []).add(e);
        }
        final listaCursos = cursos.values.toList()..sort(compararCursos);

        return Scaffold(
          appBar: AppBar(
            title: Text(ev.nombre),
            actions: [
              IconButton(
                tooltip: 'Eliminar evento',
                icon: const Icon(Icons.delete_outline),
                onPressed: () async {
                  final ok = await confirmar(
                    context,
                    titulo: 'Eliminar evento',
                    texto: 'Se eliminarán sus ${pases.length} pases y el '
                        'registro de accesos.',
                    accion: 'Eliminar',
                  );
                  if (ok && context.mounted) {
                    Navigator.of(context).pop();
                    a.eliminarEvento(ev.id);
                  }
                },
              ),
            ],
          ),
          body: ListView(
            padding: EdgeInsets.zero,
            children: [
              Container(
                color: Paleta.tinta,
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ev.lugar.isEmpty
                          ? fechaLarga(ev.fecha)
                          : '${fechaLarga(ev.fecha)}, ${ev.lugar}',
                      style: const TextStyle(color: Colors.white70, fontSize: 15),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '$usados',
                          style: const TextStyle(
                            fontFamily: 'BarlowCondensed',
                            fontWeight: FontWeight.w800,
                            fontSize: 56,
                            height: 1.0,
                            color: Colors.white,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 8, bottom: 8),
                          child: Text(
                            'de ${pases.length} ingresaron',
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 17),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: Paleta.paso,
                            ),
                            onPressed: pases.isEmpty
                                ? null
                                : () => Navigator.of(context).push(
                                      MaterialPageRoute<void>(
                                        builder: (_) =>
                                            PaginaEscaner(eventoId: ev.id),
                                      ),
                                    ),
                            icon: const Icon(Icons.qr_code_scanner),
                            label: const Text('Escanear'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: const BorderSide(
                                  color: Colors.white38, width: 1.5),
                            ),
                            onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => GenerarPases(eventoId: ev.id),
                              ),
                            ),
                            icon: const Icon(Icons.add_card_outlined),
                            label: const Text('Generar pases'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (listaCursos.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 24),
                  child: EstadoVacio(
                    icono: Icons.confirmation_number_outlined,
                    titulo: 'Sin pases todavía',
                    texto: 'Usa «Generar pases» para elegir los grados y '
                        'paralelos que participan.',
                  ),
                ),
              for (final curso in listaCursos)
                _BloqueCurso(
                  evento: ev,
                  curso: curso,
                  estudiantes: (estudiantesPorCurso[curso.clave] ?? [])
                    ..sort((x, y) => x.apellidos.compareTo(y.apellidos)),
                  porEstudiante: porEstudiante,
                ),
              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }
}

class _BloqueCurso extends StatelessWidget {
  final Evento evento;
  final Curso curso;
  final List<Estudiante> estudiantes;
  final Map<String, List<Pase>> porEstudiante;

  const _BloqueCurso({
    required this.evento,
    required this.curso,
    required this.estudiantes,
    required this.porEstudiante,
  });

  @override
  Widget build(BuildContext context) {
    var total = 0;
    var usados = 0;
    for (final e in estudiantes) {
      final ps = porEstudiante[e.id] ?? const <Pase>[];
      total += ps.length;
      usados += ps.where((p) => p.usado).length;
    }
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          title: Text(
            curso.nombre,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 18,
              color: Paleta.tinta,
            ),
          ),
          subtitle: Text(
            '${estudiantes.length} estudiantes, $usados de $total pases usados',
            style: const TextStyle(color: Paleta.pizarra),
          ),
          children: [
            for (final e in estudiantes)
              ListTile(
                title: Text(e.nombreCompleto),
                subtitle: Text(_estadoPases(porEstudiante[e.id] ?? const [])),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
                  builder: (_) => PasesEstudiante(
                    eventoId: evento.id,
                    estudianteId: e.id,
                  ),
                )),
              ),
          ],
        ),
      ),
    );
  }

  String _estadoPases(List<Pase> ps) {
    final usados = ps.where((p) => p.usado).length;
    if (usados == 0) return '${ps.length} pases, ninguno usado';
    if (usados == ps.length) return '${ps.length} pases, todos usados';
    return '${ps.length} pases, $usados usado${usados == 1 ? '' : 's'}';
  }
}

// =============================================================
// Generar pases por grado y paralelo
// =============================================================

class GenerarPases extends StatefulWidget {
  final String eventoId;
  const GenerarPases({super.key, required this.eventoId});

  @override
  State<GenerarPases> createState() => _GenerarPasesState();
}

class _GenerarPasesState extends State<GenerarPases> {
  final Set<String> _seleccion = {};
  late int _porPersona;

  @override
  void initState() {
    super.initState();
    _porPersona = Almacen.i.eventoPorId(widget.eventoId)?.pasesPorPersona ?? 2;
  }

  @override
  Widget build(BuildContext context) {
    final a = Almacen.i;
    final ev = a.eventoPorId(widget.eventoId);
    if (ev == null) return const Scaffold(body: SizedBox.shrink());

    final cursos = a.cursos();
    final grados = <String, List<Curso>>{};
    for (final c in cursos) {
      grados.putIfAbsent(c.grado, () => []).add(c);
    }
    final nuevos = a.estudiantesSinPases(ev.id, _seleccion);
    final totalPases = nuevos * _porPersona;

    return Scaffold(
      appBar: AppBar(title: const Text('Generar pases')),
      body: cursos.isEmpty
          ? EstadoVacio(
              icono: Icons.groups_outlined,
              titulo: 'No hay estudiantes',
              texto: 'Agrega estudiantes en la pestaña Estudiantes o carga '
                  'los datos de prueba.',
              accion: FilledButton(
                onPressed: () {
                  a.cargarDatosPrueba();
                  setState(() {});
                },
                child: const Text('Cargar datos de prueba'),
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                const Text(
                  'Pases por estudiante',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 17,
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
                        onPressed: _porPersona > 1
                            ? () => setState(() => _porPersona--)
                            : null,
                        icon: const Icon(Icons.remove_circle_outline),
                      ),
                      Expanded(
                        child: Text(
                          '$_porPersona',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontFamily: 'BarlowCondensed',
                            fontWeight: FontWeight.w800,
                            fontSize: 36,
                            color: Paleta.tinta,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: _porPersona < 10
                            ? () => setState(() => _porPersona++)
                            : null,
                        icon: const Icon(Icons.add_circle_outline),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Grados y paralelos que participan',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 17,
                    color: Paleta.tinta,
                  ),
                ),
                const SizedBox(height: 8),
                for (final grado in grados.entries)
                  _BloqueGrado(
                    grado: grado.key,
                    cursos: grado.value,
                    seleccion: _seleccion,
                    alCambiar: () => setState(() {}),
                  ),
              ],
            ),
      bottomNavigationBar: cursos.isEmpty
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: FilledButton(
                  onPressed: totalPases == 0
                      ? null
                      : () {
                          final n = a.generarPases(ev, _seleccion, _porPersona);
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Se generaron $n pases.')),
                          );
                        },
                  child: Text(totalPases == 0
                      ? (_seleccion.isEmpty
                          ? 'Elige al menos un paralelo'
                          : 'Estos estudiantes ya tienen pases')
                      : 'Generar $totalPases pases para $nuevos estudiantes'),
                ),
              ),
            ),
    );
  }
}

class _BloqueGrado extends StatelessWidget {
  final String grado;
  final List<Curso> cursos;
  final Set<String> seleccion;
  final VoidCallback alCambiar;

  const _BloqueGrado({
    required this.grado,
    required this.cursos,
    required this.seleccion,
    required this.alCambiar,
  });

  @override
  Widget build(BuildContext context) {
    final a = Almacen.i;
    final marcados = cursos.where((c) => seleccion.contains(c.clave)).length;
    final bool? estadoGrado = marcados == 0
        ? false
        : (marcados == cursos.length ? true : null);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          CheckboxListTile(
            tristate: true,
            value: estadoGrado,
            controlAffinity: ListTileControlAffinity.leading,
            title: Text(
              grado,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 18,
                color: Paleta.tinta,
              ),
            ),
            subtitle: const Text('Todo el grado'),
            onChanged: (_) {
              if (estadoGrado == true) {
                for (final c in cursos) {
                  seleccion.remove(c.clave);
                }
              } else {
                for (final c in cursos) {
                  seleccion.add(c.clave);
                }
              }
              alCambiar();
            },
          ),
          for (final c in cursos)
            CheckboxListTile(
              contentPadding: const EdgeInsets.only(left: 40, right: 16),
              value: seleccion.contains(c.clave),
              controlAffinity: ListTileControlAffinity.leading,
              title: Text('Paralelo ${c.paralelo}'),
              subtitle:
                  Text('${a.estudiantesDeCurso(c.clave).length} estudiantes'),
              onChanged: (v) {
                if (v == true) {
                  seleccion.add(c.clave);
                } else {
                  seleccion.remove(c.clave);
                }
                alCambiar();
              },
            ),
        ],
      ),
    );
  }
}

// =============================================================
// Utilidades
// =============================================================

Future<bool> confirmar(
  BuildContext context, {
  required String titulo,
  required String texto,
  required String accion,
}) async {
  final r = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(titulo),
      content: Text(texto),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: const Text('Cancelar'),
        ),
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          style: TextButton.styleFrom(foregroundColor: Paleta.alto),
          child: Text(accion),
        ),
      ],
    ),
  );
  return r ?? false;
}
