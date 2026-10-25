import 'package:flutter/material.dart';

import '../almacen.dart';
import '../formato.dart';
import '../modelos.dart';
import '../tema.dart';
import 'accesos_extra.dart';
import 'compartir_evento.dart';
import 'envio_grupo.dart';
import 'informe.dart';
import 'escaner.dart';
import 'pases.dart';
import 'pdf_pases.dart';

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
          IconButton(
            tooltip: 'Agregar evento desde otro celular',
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: () => _unirse(context),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (v) async {
              if (v != 'borrar') return;
              final ok = await confirmar(
                context,
                titulo: 'Borrar datos de este celular',
                texto: 'Se eliminarán los eventos, los pases marcados como '
                    'usados y el registro. La nómina no se modifica.',
                accion: 'Borrar',
              );
              if (ok) a.borrarDatosDelCelular();
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                  value: 'borrar', child: Text('Borrar datos de este celular')),
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
              titulo: 'Crea un evento o agrégalo desde otro celular',
              texto: 'Un celular crea el evento y elige los cursos. Los demás '
                  'lo agregan escaneando el código que muestra.',
              accion: OutlinedButton.icon(
                onPressed: () => _unirse(context),
                icon: const Icon(Icons.qr_code_scanner),
                label: const Text('Agregar desde otro celular'),
              ),
            );
          }
          final lista = [...a.eventos]
            ..sort((x, y) => x.fecha.compareTo(y.fecha));
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 12),
                child: Text(
                  '${a.institucion}\n${a.estudiantes.length} estudiantes, '
                  'periodo ${a.periodo}',
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.35,
                    color: Paleta.pizarra,
                  ),
                ),
              ),
              for (final ev in lista) ...[
                _TarjetaEvento(evento: ev),
                const SizedBox(height: 12),
              ],
            ],
          );
        },
      ),
    );
  }

  void _unirse(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => const PaginaAgregarEvento(),
    ));
  }

  Future<void> _nuevoEvento(BuildContext context) async {
    final ev = await showModalBottomSheet<Evento>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const _FormularioEvento(),
    );
    if (ev == null || !context.mounted) return;
    final nav = Navigator.of(context);
    nav.push(MaterialPageRoute<void>(
      builder: (_) => DetalleEvento(eventoId: ev.id),
    ));
    nav.push(MaterialPageRoute<void>(
      builder: (_) => SeleccionCursos(eventoId: ev.id),
    ));
  }
}

class _TarjetaEvento extends StatelessWidget {
  final Evento evento;
  const _TarjetaEvento({required this.evento});

  @override
  Widget build(BuildContext context) {
    final a = Almacen.i;
    final total = a.totalPases(evento);
    final usados = a.usadosEn(evento);
    final avance = total == 0 ? 0.0 : (usados / total).clamp(0.0, 1.0);

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
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      evento.nombre,
                      style: const TextStyle(
                        fontFamily: 'BarlowCondensed',
                        fontWeight: FontWeight.w700,
                        fontSize: 25,
                        height: 1.1,
                        color: Paleta.tinta,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const EscudoEscuela(tamano: 44),
                ],
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
                total == 0
                    ? 'Aún no hay cursos elegidos'
                    : 'En este celular ingresaron $usados de $total pases',
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
              final ev = Almacen.i.crearEvento(
                nombre: nombre,
                lugar: _lugar.text.trim(),
                fecha: _fecha,
              );
              Navigator.of(context).pop(ev);
            },
            child: const Text('Crear y elegir cursos'),
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
        if (ev == null) return const Scaffold(body: SizedBox.shrink());
        final total = a.totalPases(ev);
        final usados = a.usadosEn(ev);
        final cursos = a.cursosDeEvento(ev);

        return Scaffold(
          appBar: AppBar(
            title: Text(ev.nombre),
            actions: [
              IconButton(
                tooltip: 'Informe de accesos',
                icon: const Icon(Icons.summarize_outlined),
                onPressed: () => mostrarOpcionesInforme(context, ev),
              ),
              IconButton(
                tooltip: 'Eliminar evento de este celular',
                icon: const Icon(Icons.delete_outline),
                onPressed: () async {
                  final ok = await confirmar(
                    context,
                    titulo: 'Eliminar evento',
                    texto: 'Se eliminará de este celular junto con su '
                        'registro de accesos. Los demás celulares no se ven '
                        'afectados.',
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
          body: Stack(
            children: [
              const Positioned.fill(
                top: 260,
                child: MarcaAguaEscuela(tamano: 300, opacidad: 0.07),
              ),
              ListView(
            padding: EdgeInsets.zero,
            children: [
              Container(
                color: Paleta.tinta,
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            ev.lugar.isEmpty
                                ? fechaLarga(ev.fecha)
                                : '${fechaLarga(ev.fecha)}, ${ev.lugar}',
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 15),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const EscudoEscuela(tamano: 46),
                        ),
                      ],
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
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(left: 8, bottom: 6),
                            child: Text(
                              'de $total pases ingresaron por este celular',
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 16),
                            ),
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
                                backgroundColor: Paleta.paso),
                            onPressed: total == 0
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
                                builder: (_) => SeleccionCursos(eventoId: ev.id),
                              ),
                            ),
                            icon: const Icon(Icons.checklist),
                            label: const Text('Cursos'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: TextButton.icon(
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white,
                          minimumSize: const Size(64, 48),
                        ),
                        onPressed: total == 0
                            ? null
                            : () => Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) =>
                                        PaginaCompartirEvento(eventoId: ev.id),
                                  ),
                                ),
                        icon: const Icon(Icons.phonelink_ring_outlined),
                        label: const Text('Pasar este evento a otro celular'),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: _Accion(
                        icono: Icons.forward_to_inbox_outlined,
                        texto: 'Enviar por grupo',
                        alTocar: cursos.isEmpty
                            ? null
                            : () => Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) =>
                                        PaginaEnvioGrupo(eventoId: ev.id),
                                  ),
                                ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _Accion(
                        icono: Icons.person_add_alt,
                        texto: 'Agregar acceso',
                        alTocar: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) =>
                                FormularioAccesoExtra(eventoId: ev.id),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _Accion(
                        icono: Icons.summarize_outlined,
                        texto: 'Informe',
                        alTocar: () => mostrarOpcionesInforme(context, ev),
                      ),
                    ),
                  ],
                ),
              ),
              if (a.extrasDe(ev).isNotEmpty) ...[
                const Padding(
                  padding: EdgeInsets.fromLTRB(20, 18, 20, 4),
                  child: Text(
                    'Accesos adicionales',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: Paleta.tinta,
                    ),
                  ),
                ),
                for (final x in a.extrasDe(ev))
                  Container(
                    margin: const EdgeInsets.fromLTRB(16, 6, 16, 0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: ListTile(
                      leading: const Icon(Icons.confirmation_number_outlined,
                          color: Paleta.tinta),
                      title: Text(x.nombre),
                      subtitle: Text([
                        if (x.detalle.isNotEmpty) x.detalle,
                        '${x.total} pase${x.total == 1 ? '' : 's'}',
                      ].join(', ')),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) =>
                              PasesExtra(eventoId: ev.id, accesoId: x.id),
                        ),
                      ),
                    ),
                  ),
              ],
              if (cursos.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 24),
                  child: EstadoVacio(
                    icono: Icons.checklist,
                    titulo: 'Elige los cursos que participan',
                    texto: 'Usa «Cursos» para marcar grados y paralelos y '
                        'definir cuántos pases recibe cada estudiante.',
                  ),
                ),
              if (cursos.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Text(
                    '${cursos.length} cursos, ${ev.pasesPorPersona} pases por '
                    'estudiante. Comparte el PDF de cada curso con su presidente.',
                    style: const TextStyle(fontSize: 14, color: Paleta.pizarra),
                  ),
                ),
              for (final c in cursos)
                _BloqueCurso(key: ValueKey(c.clave), evento: ev, curso: c),
              const SizedBox(height: 32),
            ],
          ),
            ],
          ),
        );
      },
    );
  }
}

class _BloqueCurso extends StatefulWidget {
  final Evento evento;
  final Curso curso;
  const _BloqueCurso({super.key, required this.evento, required this.curso});

  @override
  State<_BloqueCurso> createState() => _BloqueCursoState();
}

class _BloqueCursoState extends State<_BloqueCurso> {
  bool _generando = false;

  Future<void> _compartirPdf() async {
    setState(() => _generando = true);
    try {
      await compartirPdfDeCurso(widget.evento, widget.curso);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo crear el PDF: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _generando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final a = Almacen.i;
    final ev = widget.evento;
    final c = widget.curso;
    final lista = a.estudiantesDeCurso(c.clave);
    final total = lista.length * ev.pasesPorPersona;
    final usados = a.usadosDeCurso(ev, c.clave);

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
            c.nombre,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 18,
              color: Paleta.tinta,
            ),
          ),
          subtitle: Text(
            '${lista.length} estudiantes, $usados de $total pases usados',
            style: const TextStyle(color: Paleta.pizarra),
          ),
          trailing: _generando
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                )
              : IconButton(
                  tooltip: 'Compartir PDF del curso',
                  icon: const Icon(Icons.picture_as_pdf_outlined,
                      color: Paleta.tinta),
                  onPressed: _compartirPdf,
                ),
          children: [
            for (final e in lista)
              ListTile(
                title: Text(e.nombre),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
                  builder: (_) =>
                      PasesEstudiante(eventoId: ev.id, estudianteId: e.id),
                )),
              ),
          ],
        ),
      ),
    );
  }
}

// =============================================================
// Elegir cursos participantes
// =============================================================

class SeleccionCursos extends StatefulWidget {
  final String eventoId;
  const SeleccionCursos({super.key, required this.eventoId});

  @override
  State<SeleccionCursos> createState() => _SeleccionCursosState();
}

class _SeleccionCursosState extends State<SeleccionCursos> {
  late Set<String> _seleccion;
  late int _porPersona;

  @override
  void initState() {
    super.initState();
    final ev = Almacen.i.eventoPorId(widget.eventoId);
    _seleccion = {...?ev?.cursos};
    _porPersona = ev?.pasesPorPersona ?? 2;
  }

  @override
  Widget build(BuildContext context) {
    final a = Almacen.i;
    final ev = a.eventoPorId(widget.eventoId);
    if (ev == null) return const Scaffold(body: SizedBox.shrink());

    // jornada -> grado -> cursos
    final arbol = <String, Map<int, List<Curso>>>{};
    for (final c in a.cursos) {
      arbol
          .putIfAbsent(c.jornada, () => {})
          .putIfAbsent(c.grado, () => [])
          .add(c);
    }
    final estudiantes = a.contarParticipantes(_seleccion);
    final pases = estudiantes * _porPersona;

    return Scaffold(
      appBar: AppBar(title: const Text('Cursos participantes')),
      body: ListView(
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
          for (final jornada in arbol.entries) ...[
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Jornada ${nombreJornada(jornada.key)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 17,
                      color: Paleta.tinta,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    final claves = [
                      for (final l in jornada.value.values)
                        for (final c in l) c.clave
                    ];
                    setState(() {
                      if (claves.every(_seleccion.contains)) {
                        _seleccion.removeAll(claves);
                      } else {
                        _seleccion.addAll(claves);
                      }
                    });
                  },
                  child: const Text('Toda la jornada'),
                ),
              ],
            ),
            const SizedBox(height: 4),
            for (final grado in jornada.value.entries)
              _BloqueGrado(
                titulo: nombreGrado(grado.key),
                cursos: grado.value,
                seleccion: _seleccion,
                alCambiar: () => setState(() {}),
              ),
          ],
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: FilledButton(
            onPressed: () {
              final yaTenia = ev.cursos.isNotEmpty;
              a.guardarCursos(ev, _seleccion, _porPersona);
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(yaTenia
                    ? 'Cursos guardados. Si ya pasaste el evento a otros '
                        'celulares, vuelve a pasarlo.'
                    : 'Cursos guardados: $estudiantes estudiantes, $pases pases.'),
              ));
            },
            child: Text(_seleccion.isEmpty
                ? 'Guardar sin cursos'
                : 'Guardar: $estudiantes estudiantes, $pases pases'),
          ),
        ),
      ),
    );
  }
}

class _BloqueGrado extends StatelessWidget {
  final String titulo;
  final List<Curso> cursos;
  final Set<String> seleccion;
  final VoidCallback alCambiar;

  const _BloqueGrado({
    required this.titulo,
    required this.cursos,
    required this.seleccion,
    required this.alCambiar,
  });

  @override
  Widget build(BuildContext context) {
    final a = Almacen.i;
    final marcados = cursos.where((c) => seleccion.contains(c.clave)).length;
    final bool? estado =
        marcados == 0 ? false : (marcados == cursos.length ? true : null);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          CheckboxListTile(
            tristate: true,
            value: estado,
            controlAffinity: ListTileControlAffinity.leading,
            title: Text(
              titulo,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 18,
                color: Paleta.tinta,
              ),
            ),
            onChanged: (_) {
              if (estado == true) {
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

class _Accion extends StatelessWidget {
  final IconData icono;
  final String texto;
  final VoidCallback? alTocar;
  const _Accion({required this.icono, required this.texto, this.alTocar});

  @override
  Widget build(BuildContext context) {
    final activo = alTocar != null;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: alTocar,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
          child: Column(
            children: [
              Icon(icono,
                  color: activo ? Paleta.tinta : Paleta.linea, size: 26),
              const SizedBox(height: 6),
              Text(
                texto,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13.5,
                  color: activo ? Paleta.tinta : Paleta.pizarra,
                ),
              ),
            ],
          ),
        ),
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
