import 'dart:io';

import 'package:flutter/material.dart';

import '../almacen.dart';
import '../formato.dart';
import '../modelos.dart';
import '../tema.dart';
import '../whatsapp.dart';
import 'imagenes_pases.dart';

/// Envía a cada docente las imágenes de los pases de su paralelo.
///
/// Con «Enviar a todos», la app prepara las imágenes del primer paralelo y
/// abre WhatsApp en el chat de la docente con todo adjunto. Al tocar
/// «Enviar» y volver a la app, marca ese paralelo como enviado y prepara el
/// siguiente automáticamente.
class PaginaEnvioDocentes extends StatefulWidget {
  final String eventoId;
  const PaginaEnvioDocentes({super.key, required this.eventoId});

  @override
  State<PaginaEnvioDocentes> createState() => _PaginaEnvioDocentesState();
}

class _PaginaEnvioDocentesState extends State<PaginaEnvioDocentes>
    with WidgetsBindingObserver {
  String? _esperando; // curso abierto en WhatsApp
  bool _enCola = false;
  bool _trabajando = false;
  bool? _whatsappDirecto;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WhatsAppDirecto.disponible().then((v) {
      if (mounted) setState(() => _whatsappDirecto = v);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed || _esperando == null) return;
    final ev = Almacen.i.eventoPorId(widget.eventoId);
    if (ev == null) return;
    final curso = _esperando!;
    _esperando = null;
    Almacen.i.marcarEnviado(ev, curso);
    if (_enCola) {
      Future<void>.delayed(const Duration(milliseconds: 700), _siguiente);
    } else {
      setState(() {});
    }
  }

  String _mensaje(Evento ev, Curso c) =>
      'Estimado/a docente de ${c.nombre}: le envío los pases individuales de '
      'sus estudiantes para «${ev.nombre}», ${fechaLarga(ev.fecha)}. Cada '
      'imagen lleva el nombre del estudiante; por favor, reenvíe a cada '
      'familia solo los pases de su hijo o hija. Cada pase permite un ingreso.';

  Future<void> _enviar(Evento ev, Curso c) async {
    final a = Almacen.i;
    final docente = a.docenteDe(c.clave);
    final numero = docente == null ? null : numeroWhatsApp(docente.celular);
    if (numero == null) {
      _aviso('${c.nombre} no tiene un número válido. Tócalo para editarlo.');
      setState(() => _enCola = false);
      return;
    }
    setState(() => _trabajando = true);
    final archivos = await conProgreso<List<File>>(
      context,
      'Pases de ${c.nombre}',
      (avance) => crearImagenes(ev, pasesDeCursos(ev, [c]), progreso: avance),
    );
    if (!mounted) return;
    setState(() => _trabajando = false);
    if (archivos == null || archivos.isEmpty) {
      setState(() => _enCola = false);
      return;
    }
    final texto = _mensaje(ev, c);
    final directo = await WhatsAppDirecto.enviar(
        numero: numero, archivos: archivos, texto: texto);
    if (directo) {
      _esperando = c.clave;
    } else {
      // Sin WhatsApp directo: menú de compartir, la persona elige el chat.
      setState(() => _enCola = false);
      await compartirImagenes(archivos, texto);
      if (mounted) _preguntarSiEnvio(ev, c);
    }
  }

  Future<void> _preguntarSiEnvio(Evento ev, Curso c) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('¿Se enviaron los pases de ${c.nombre}?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('No')),
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Sí, marcar enviado')),
        ],
      ),
    );
    if (ok == true) Almacen.i.marcarEnviado(ev, c.clave);
  }

  void _siguiente() {
    if (!mounted || !_enCola) return;
    final a = Almacen.i;
    final ev = a.eventoPorId(widget.eventoId);
    if (ev == null) return;
    for (final c in a.cursosDeEvento(ev)) {
      if (a.enviadoA(ev, c.clave) == null) {
        _enviar(ev, c);
        return;
      }
    }
    setState(() => _enCola = false);
    _aviso('Listo: todos los paralelos tienen sus pases.');
  }

  void _aviso(String t) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t)));
  }

  Future<void> _editar(Curso c) async {
    final a = Almacen.i;
    final actual = a.docenteDe(c.clave);
    final nombre = TextEditingController(text: actual?.nombre ?? '');
    final celular = TextEditingController(text: actual?.celular ?? '');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Docente de ${c.nombre}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nombre,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Nombre'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: celular,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                  labelText: 'Celular con WhatsApp', hintText: '0991234567'),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancelar')),
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Guardar')),
        ],
      ),
    );
    if (ok == true) {
      a.guardarContacto(c.clave, '${celular.text.trim()}|${nombre.text.trim()}');
    }
    nombre.dispose();
    celular.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final a = Almacen.i;
    return ListenableBuilder(
      listenable: a,
      builder: (context, _) {
        final ev = a.eventoPorId(widget.eventoId);
        if (ev == null) return const Scaffold(body: SizedBox.shrink());
        final cursos = a.cursosDeEvento(ev);
        final enviados = cursos.where((c) => a.enviadoA(ev, c.clave) != null);
        final pendientes = cursos.length - enviados.length;

        return Scaffold(
          appBar: AppBar(title: const Text('Enviar a docentes')),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              Text(
                ev.nombre,
                style: const TextStyle(
                  fontFamily: 'BarlowCondensed',
                  fontWeight: FontWeight.w700,
                  fontSize: 22,
                  color: Paleta.tinta,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _whatsappDirecto == false
                    ? 'No se encontró WhatsApp en este celular. Se usará el '
                        'menú de compartir y tendrás que elegir cada chat.'
                    : 'Cada docente recibe una imagen por pase de su paralelo. '
                        'La app abre su chat con las imágenes adjuntas: toca '
                        'Enviar en WhatsApp y vuelve a la app para continuar '
                        'con el siguiente. Mantén presionado un paralelo para '
                        'marcarlo otra vez como pendiente.',
                style: const TextStyle(color: Paleta.pizarra, height: 1.35),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Text(
                      '${enviados.length}/${cursos.length}',
                      style: const TextStyle(
                        fontFamily: 'BarlowCondensed',
                        fontWeight: FontWeight.w800,
                        fontSize: 34,
                        color: Paleta.paso,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text('paralelos enviados',
                          style: TextStyle(color: Paleta.pizarra)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              for (final c in cursos) _fila(ev, c),
            ],
          ),
          bottomNavigationBar: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: _enCola
                  ? OutlinedButton.icon(
                      onPressed: () => setState(() => _enCola = false),
                      icon: const Icon(Icons.pause),
                      label: const Text('Pausar después de este paralelo'),
                    )
                  : FilledButton.icon(
                      style:
                          FilledButton.styleFrom(backgroundColor: Paleta.paso),
                      onPressed: pendientes == 0 || _trabajando
                          ? null
                          : () {
                              setState(() => _enCola = true);
                              _siguiente();
                            },
                      icon: const Icon(Icons.send),
                      label: Text(pendientes == 0
                          ? 'Todos enviados'
                          : 'Enviar a los $pendientes pendientes'),
                    ),
            ),
          ),
        );
      },
    );
  }

  Widget _fila(Evento ev, Curso c) {
    final a = Almacen.i;
    final d = a.docenteDe(c.clave);
    final enviado = a.enviadoA(ev, c.clave);
    final imagenes = a.estudiantesDeCurso(c.clave).length * ev.pasesPorPersona;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.fromLTRB(16, 6, 8, 6),
        onTap: () => _editar(c),
        onLongPress: enviado == null
            ? null
            : () => a.marcarEnviado(ev, c.clave, enviado: false),
        title: Text(
          c.nombre,
          style: const TextStyle(
              fontWeight: FontWeight.w700, color: Paleta.tinta),
        ),
        subtitle: Text(
          [
            if (d == null || d.celular.isEmpty)
              'Sin docente: toca para agregar'
            else
              '${d.nombre.isEmpty ? 'Docente' : d.nombre}, ${d.celular}',
            enviado == null
                ? '$imagenes imágenes, pendiente'
                : 'Enviado ${fechaYHora(enviado)}',
          ].join('\n'),
          style: TextStyle(
            height: 1.35,
            color: enviado == null ? Paleta.pizarra : Paleta.paso,
          ),
        ),
        isThreeLine: true,
        trailing: IconButton(
          tooltip: enviado == null ? 'Enviar' : 'Reenviar',
          icon: Icon(
            enviado == null ? Icons.send_outlined : Icons.replay,
            color: Paleta.tinta,
          ),
          onPressed: _trabajando || _enCola ? null : () => _enviar(ev, c),
        ),
      ),
    );
  }
}
