import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../almacen.dart';
import '../codigo_qr.dart';
import '../formato.dart';
import '../modelos.dart';
import '../tema.dart';
import 'accesos_extra.dart';
import 'pdf_pases.dart';

/// Datos que muestra una tarjeta de pase.
class DatosPase {
  final String clave;
  final String codigo;
  final String etiqueta;
  final String nombre;
  final String detalle;
  final String numero;
  final DateTime? usadoEn;

  const DatosPase({
    required this.clave,
    required this.codigo,
    required this.etiqueta,
    required this.nombre,
    required this.detalle,
    required this.numero,
    required this.usadoEn,
  });

  factory DatosPase.deEstudiante(Pase p, Estudiante e) => DatosPase(
        clave: p.clave,
        codigo: codificarPase(p),
        etiqueta: 'Invitado de',
        nombre: e.nombre,
        detalle: e.curso,
        numero: 'Pase ${p.numero} de ${p.total}',
        usadoEn: Almacen.i.usoDe(p),
      );

  factory DatosPase.deExtra(PaseExtra p) => DatosPase(
        clave: p.clave,
        codigo: codificarPaseExtra(p),
        etiqueta: 'Acceso adicional',
        nombre: p.acceso.nombre,
        detalle: p.acceso.detalle,
        numero: 'Pase ${p.numero} de ${p.acceso.total}',
        usadoEn: Almacen.i.usoDeExtra(p),
      );
}

class TarjetaPase extends StatelessWidget {
  final DatosPase datos;
  final Evento evento;

  const TarjetaPase({super.key, required this.datos, required this.evento});

  @override
  Widget build(BuildContext context) {
    final usado = datos.usadoEn;
    return Container(
      width: 340,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Paleta.linea),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          const Positioned.fill(
            child: MarcaAguaEscuela(tamano: 260, opacidad: 0.06),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Cabecera: Omega Access, institución y escudo
              Container(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                decoration: const BoxDecoration(
                  border: Border(
                      bottom: BorderSide(color: Paleta.tinta, width: 3)),
                ),
                child: Row(
                  children: [
                    const LogoOmega(tamano: 34),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        Almacen.i.institucion,
                        maxLines: 2,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 12.5,
                          height: 1.2,
                          color: Paleta.tinta,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    const EscudoEscuela(tamano: 40),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      evento.nombre,
                      style: const TextStyle(
                        fontFamily: 'BarlowCondensed',
                        fontWeight: FontWeight.w800,
                        fontSize: 26,
                        height: 1.05,
                        color: Paleta.tinta,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      evento.lugar.isEmpty
                          ? fechaLarga(evento.fecha)
                          : '${fechaLarga(evento.fecha)}\n${evento.lugar}',
                      style: const TextStyle(
                          fontSize: 14, height: 1.35, color: Paleta.pizarra),
                    ),
                  ],
                ),
              ),
              Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  color: Colors.white,
                  padding: const EdgeInsets.all(6),
                  child: QrImageView(
                    data: datos.codigo,
                    version: QrVersions.auto,
                    size: 220,
                    backgroundColor: Colors.white,
                    eyeStyle: const QrEyeStyle(
                      eyeShape: QrEyeShape.square,
                      color: Paleta.tinta,
                    ),
                    dataModuleStyle: const QrDataModuleStyle(
                      dataModuleShape: QrDataModuleShape.square,
                      color: Paleta.tinta,
                    ),
                  ),
                ),
              ),
              Container(
                margin: const EdgeInsets.fromLTRB(20, 2, 20, 0),
                padding: const EdgeInsets.only(top: 12),
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: Paleta.linea)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(datos.etiqueta,
                        style: const TextStyle(
                            fontSize: 13, color: Paleta.pizarra)),
                    Text(
                      datos.nombre,
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                        color: Paleta.tinta,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      datos.detalle.isEmpty
                          ? datos.numero
                          : '${datos.detalle}, ${datos.numero.toLowerCase()}',
                      style: const TextStyle(
                          fontSize: 15, color: Paleta.pizarra),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
                child: Row(
                  children: [
                    const Text(
                      'Omega Access',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Paleta.pizarra,
                      ),
                    ),
                    const Spacer(),
                    if (usado != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Paleta.paso.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Usado a las ${hora(usado)}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Paleta.paso,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Muestra una lista de pases y permite compartirlos como imágenes.
class _ListaPases extends StatefulWidget {
  final Evento evento;
  final List<DatosPase> pases;
  final String mensaje;
  final List<Widget> accionesExtra;

  const _ListaPases({
    required this.evento,
    required this.pases,
    required this.mensaje,
    this.accionesExtra = const [],
  });

  @override
  State<_ListaPases> createState() => _ListaPasesState();
}

class _ListaPasesState extends State<_ListaPases> {
  final Map<String, GlobalKey> _claves = {};
  bool _compartiendo = false;

  GlobalKey _clave(String k) => _claves.putIfAbsent(k, () => GlobalKey());

  Future<void> _compartir() async {
    setState(() => _compartiendo = true);
    try {
      await Future<void>.delayed(const Duration(milliseconds: 60));
      final dir = await getTemporaryDirectory();
      final archivos = <XFile>[];
      for (final p in widget.pases) {
        final ctx = _clave(p.clave).currentContext;
        if (ctx == null) continue;
        final limite = ctx.findRenderObject() as RenderRepaintBoundary;
        final imagen = await limite.toImage(pixelRatio: 3);
        final datos = await imagen.toByteData(format: ui.ImageByteFormat.png);
        if (datos == null) continue;
        final nombre = p.clave.replaceAll('.', '_');
        final archivo = File('${dir.path}/pase_$nombre.png');
        await archivo.writeAsBytes(datos.buffer.asUint8List());
        archivos.add(XFile(archivo.path, mimeType: 'image/png'));
      }
      if (archivos.isEmpty) return;
      await Share.shareXFiles(archivos, text: widget.mensaje);
    } finally {
      if (mounted) setState(() => _compartiendo = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
        child: Center(
          child: Column(
            children: [
              for (final p in widget.pases) ...[
                RepaintBoundary(
                  key: _clave(p.clave),
                  child: TarjetaPase(datos: p, evento: widget.evento),
                ),
                const SizedBox(height: 16),
              ],
              ...widget.accionesExtra,
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: FilledButton.icon(
            onPressed:
                _compartiendo || widget.pases.isEmpty ? null : _compartir,
            icon: _compartiendo
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.share_outlined),
            label: Text(_compartiendo
                ? 'Preparando imágenes'
                : 'Compartir por WhatsApp u otra app'),
          ),
        ),
      ),
    );
  }
}

class PasesEstudiante extends StatelessWidget {
  final String eventoId;
  final String estudianteId;

  const PasesEstudiante({
    super.key,
    required this.eventoId,
    required this.estudianteId,
  });

  @override
  Widget build(BuildContext context) {
    final a = Almacen.i;
    return ListenableBuilder(
      listenable: a,
      builder: (context, _) {
        final ev = a.eventoPorId(eventoId);
        final est = a.estudiantePorId(estudianteId);
        if (ev == null || est == null) {
          return const Scaffold(body: SizedBox.shrink());
        }
        final pases = [
          for (final p in a.pasesDe(ev, est)) DatosPase.deEstudiante(p, est),
        ];
        return Scaffold(
          appBar: AppBar(title: Text(est.nombre)),
          body: _ListaPases(
            evento: ev,
            pases: pases,
            mensaje: 'Hola, te comparto los ${pases.length} pases de '
                '${est.nombre} (${est.curso}) para «${ev.nombre}», '
                '${fechaLarga(ev.fecha)}. Presenta el código QR en la '
                'entrada; cada pase permite un ingreso.',
            accionesExtra: [
              OutlinedButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => FormularioAccesoExtra(
                      eventoId: ev.id,
                      nombreInicial: 'Invitado de ${est.nombre}',
                      detalleInicial: est.curso,
                    ),
                  ),
                ),
                icon: const Icon(Icons.person_add_alt),
                label: const Text('Agregar un pase más para este estudiante'),
              ),
            ],
          ),
        );
      },
    );
  }
}

class PasesExtra extends StatelessWidget {
  final String eventoId;
  final String accesoId;

  const PasesExtra({super.key, required this.eventoId, required this.accesoId});

  @override
  Widget build(BuildContext context) {
    final a = Almacen.i;
    return ListenableBuilder(
      listenable: a,
      builder: (context, _) {
        final ev = a.eventoPorId(eventoId);
        AccesoExtra? x;
        for (final e in a.extras) {
          if (e.id == accesoId) x = e;
        }
        final acceso = x;
        if (ev == null || acceso == null) {
          return const Scaffold(body: SizedBox.shrink());
        }
        final pases = [
          for (final p in a.pasesExtraDe(acceso)) DatosPase.deExtra(p),
        ];
        return Scaffold(
          appBar: AppBar(
            title: Text(acceso.nombre),
            actions: [
              IconButton(
                tooltip: 'PDF',
                icon: const Icon(Icons.picture_as_pdf_outlined),
                onPressed: () async {
                  final f = await crearPdfDeExtra(ev, acceso);
                  await Share.shareXFiles(
                    [XFile(f.path, mimeType: 'application/pdf')],
                    text: 'Pases de acceso adicional para «${ev.nombre}».',
                  );
                },
              ),
              IconButton(
                tooltip: 'Eliminar',
                icon: const Icon(Icons.delete_outline),
                onPressed: () async {
                  final ok = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Eliminar acceso adicional'),
                      content: const Text(
                          'Se quitará de este celular. Los pases ya enviados '
                          'seguirán siendo válidos en la puerta.'),
                      actions: [
                        TextButton(
                            onPressed: () => Navigator.of(ctx).pop(false),
                            child: const Text('Cancelar')),
                        TextButton(
                            onPressed: () => Navigator.of(ctx).pop(true),
                            child: const Text('Eliminar')),
                      ],
                    ),
                  );
                  if (ok == true && context.mounted) {
                    Navigator.of(context).pop();
                    a.eliminarExtra(acceso.id);
                  }
                },
              ),
            ],
          ),
          body: _ListaPases(
            evento: ev,
            pases: pases,
            mensaje: 'Hola, te comparto ${pases.length == 1 ? 'el pase' : 'los ${pases.length} pases'} '
                'de acceso para «${ev.nombre}», ${fechaLarga(ev.fecha)}. '
                'Presenta el código QR en la entrada.',
          ),
        );
      },
    );
  }
}
