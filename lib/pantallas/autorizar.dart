import 'package:flutter/material.dart';

import '../almacen.dart';
import '../formato.dart';
import '../modelos.dart';
import '../tema.dart';

/// Busca a un estudiante para autorizar el ingreso de un invitado que no
/// presenta su QR, o para habilitar de nuevo un pase usado (reingreso).
class PaginaAutorizar extends StatefulWidget {
  final String eventoId;
  const PaginaAutorizar({super.key, required this.eventoId});

  @override
  State<PaginaAutorizar> createState() => _PaginaAutorizarState();
}

class _PaginaAutorizarState extends State<PaginaAutorizar> {
  final _buscar = TextEditingController();
  String _filtro = '';
  String? _curso;

  @override
  void dispose() {
    _buscar.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final a = Almacen.i;
    final ev = a.eventoPorId(widget.eventoId);
    if (ev == null) return const Scaffold(body: SizedBox.shrink());

    final cursos = a.cursosDeEvento(ev);
    final f = normalizar(_filtro.trim());
    final estudiantes = (_curso != null
            ? a.estudiantesDeCurso(_curso!)
            : (f.isEmpty ? const <Estudiante>[] : a.participantes(ev)))
        .where((e) => f.isEmpty || normalizar(e.nombre).contains(f))
        .take(80)
        .toList();
    final extras = f.isEmpty
        ? const <AccesoExtra>[]
        : a
            .extrasDe(ev)
            .where((x) => normalizar(x.nombre).contains(f))
            .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Autorizar sin QR')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Paleta.celeste,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Text(
              'Pregunta de qué estudiante y curso viene la persona. Antes de '
              'autorizar, confirma su identidad con la docente o con el '
              'estudiante. Aquí también puedes habilitar un pase usado para '
              'que alguien vuelva a entrar con el mismo código.',
              style: TextStyle(color: Paleta.tinta, height: 1.4),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _buscar,
            onChanged: (v) => setState(() => _filtro = v),
            decoration: InputDecoration(
              hintText: 'Nombre o apellido del estudiante',
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
          const SizedBox(height: 10),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (final c in cursos)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(c.nombreCorto),
                      selected: _curso == c.clave,
                      selectedColor: Paleta.celeste,
                      onSelected: (v) =>
                          setState(() => _curso = v ? c.clave : null),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (estudiantes.isEmpty && extras.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 20),
              child: Text(
                f.isEmpty && _curso == null
                    ? 'Escribe un nombre o elige un curso.'
                    : 'No hay coincidencias en los cursos de este evento.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Paleta.pizarra),
              ),
            ),
          for (final e in estudiantes)
            _FilaPersona(
              titulo: e.nombre,
              subtitulo: e.curso,
              pases: a.pasesDe(ev, e).map((p) => p.clave).toList(),
              evento: ev,
              alTocar: () => _ficha(context, ev, estudiante: e),
            ),
          for (final x in extras)
            _FilaPersona(
              titulo: x.nombre,
              subtitulo: x.detalle.isEmpty ? 'Acceso adicional' : x.detalle,
              pases: a.pasesExtraDe(x).map((p) => p.clave).toList(),
              evento: ev,
              alTocar: () => _ficha(context, ev, extra: x),
            ),
        ],
      ),
    );
  }

  Future<void> _ficha(BuildContext context, Evento ev,
      {Estudiante? estudiante, AccesoExtra? extra}) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) =>
          FichaAcceso(evento: ev, estudiante: estudiante, extra: extra),
    );
    if (mounted) setState(() {});
  }
}

class _FilaPersona extends StatelessWidget {
  final String titulo;
  final String subtitulo;
  final List<String> pases;
  final Evento evento;
  final VoidCallback alTocar;

  const _FilaPersona({
    required this.titulo,
    required this.subtitulo,
    required this.pases,
    required this.evento,
    required this.alTocar,
  });

  @override
  Widget build(BuildContext context) {
    final usados =
        pases.where((k) => Almacen.i.usoPorClave(evento, k) != null).length;
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        title: Text(titulo),
        subtitle: Text(subtitulo),
        trailing: Text(
          '$usados/${pases.length}',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: usados == pases.length ? Paleta.paso : Paleta.pizarra,
          ),
        ),
        onTap: alTocar,
      ),
    );
  }
}

/// Ficha con el estado de cada pase y las acciones de la puerta.
class FichaAcceso extends StatelessWidget {
  final Evento evento;
  final Estudiante? estudiante;
  final AccesoExtra? extra;

  const FichaAcceso({
    super.key,
    required this.evento,
    this.estudiante,
    this.extra,
  });

  @override
  Widget build(BuildContext context) {
    final a = Almacen.i;
    return ListenableBuilder(
      listenable: a,
      builder: (context, _) {
        final est = estudiante;
        final x = extra;
        final String nombre;
        final String curso;
        final List<(String, int, int)> pases; // clave, número, total
        if (est != null) {
          nombre = est.nombre;
          curso = est.curso;
          pases = [
            for (final p in a.pasesDe(evento, est)) (p.clave, p.numero, p.total)
          ];
        } else {
          final acceso = x!;
          nombre = acceso.nombre;
          curso = acceso.detalle.isEmpty ? 'Acceso adicional' : acceso.detalle;
          pases = [
            for (final p in a.pasesExtraDe(acceso))
              (p.clave, p.numero, acceso.total)
          ];
        }
        final persona = est != null ? 'Invitado de $nombre' : nombre;

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  nombre,
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w700,
                    color: Paleta.tinta,
                  ),
                ),
                Text(curso, style: const TextStyle(color: Paleta.pizarra)),
                const SizedBox(height: 14),
                for (final (clave, n, total) in pases)
                  _FilaPase(
                    evento: evento,
                    clave: clave,
                    numero: n,
                    total: total,
                    persona: persona,
                    curso: curso,
                    estudianteId: est?.id,
                  ),
                const SizedBox(height: 6),
                const Text(
                  'Estas acciones quedan en el registro y en el informe, con '
                  'la hora y el nombre de esta puerta. Solo afectan a este '
                  'celular.',
                  style: TextStyle(fontSize: 13, color: Paleta.pizarra),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _FilaPase extends StatelessWidget {
  final Evento evento;
  final String clave;
  final int numero;
  final int total;
  final String persona;
  final String curso;
  final String? estudianteId;

  const _FilaPase({
    required this.evento,
    required this.clave,
    required this.numero,
    required this.total,
    required this.persona,
    required this.curso,
    required this.estudianteId,
  });

  @override
  Widget build(BuildContext context) {
    final a = Almacen.i;
    final uso = a.usoPorClave(evento, clave);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: uso == null ? Paleta.niebla : Paleta.paso.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pase $numero de $total',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: Paleta.tinta,
                  ),
                ),
                Text(
                  uso == null ? 'Disponible' : 'Ingresó a las ${hora(uso)}',
                  style: TextStyle(
                    color: uso == null ? Paleta.pizarra : Paleta.paso,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          if (uso == null)
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: Paleta.paso,
                minimumSize: const Size(0, 44),
              ),
              onPressed: () => _autorizar(context),
              icon: const Icon(Icons.how_to_reg, size: 20),
              label: const Text('Autorizar'),
            )
          else
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(minimumSize: const Size(0, 44)),
              onPressed: () => _habilitar(context),
              icon: const Icon(Icons.replay, size: 20),
              label: const Text('Habilitar'),
            ),
        ],
      ),
    );
  }

  Future<bool> _confirmar(BuildContext context, String titulo, String texto,
      String accion) async {
    final r = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(titulo),
        content: Text(texto),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancelar')),
          FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(accion)),
        ],
      ),
    );
    return r ?? false;
  }

  Future<void> _autorizar(BuildContext context) async {
    final ok = await _confirmar(
      context,
      'Autorizar ingreso sin QR',
      '$persona ($curso), pase $numero de $total. El pase quedará usado: si '
          'luego alguien presenta este mismo QR, será rechazado.',
      'Autorizar',
    );
    if (!ok || !context.mounted) return;
    Almacen.i.autorizarSinQr(evento,
        clave: clave,
        persona: persona,
        curso: curso,
        numero: numero,
        total: total,
        estudianteId: estudianteId);
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingreso registrado.')));
  }

  Future<void> _habilitar(BuildContext context) async {
    final ok = await _confirmar(
      context,
      'Habilitar pase de nuevo',
      'El pase $numero de $total volverá a estar disponible y su dueño podrá '
          'reingresar con el mismo código.',
      'Habilitar',
    );
    if (!ok || !context.mounted) return;
    Almacen.i.habilitarDeNuevo(evento,
        clave: clave,
        persona: persona,
        curso: curso,
        numero: numero,
        total: total,
        estudianteId: estudianteId);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Pase habilitado. Puede volver a escanearse.')));
  }
}
