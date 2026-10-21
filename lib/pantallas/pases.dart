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

/// Nombre de la institución que aparece en el pase. En la versión con
/// servidor, viene de la organización junto con su logo.
const String institucionDemo = 'Unidad Educativa (demo)';

class TarjetaPase extends StatelessWidget {
  final Pase pase;
  final Evento evento;
  final Estudiante? estudiante;

  const TarjetaPase({
    super.key,
    required this.pase,
    required this.evento,
    required this.estudiante,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 340,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Paleta.linea),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Cabecera institucional
          Container(
            color: Paleta.tinta,
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
            child: const Row(
              children: [
                LogoOmega(tamano: 30, sobreOscuro: true),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    institucionDemo,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 18, 22, 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  evento.nombre,
                  style: const TextStyle(
                    fontFamily: 'BarlowCondensed',
                    fontWeight: FontWeight.w800,
                    fontSize: 30,
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
                    fontSize: 14,
                    height: 1.35,
                    color: Paleta.pizarra,
                  ),
                ),
              ],
            ),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: QrImageView(
                data: codificarPase(pase),
                version: QrVersions.auto,
                size: 230,
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
            margin: const EdgeInsets.fromLTRB(22, 4, 22, 0),
            padding: const EdgeInsets.only(top: 12),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Paleta.linea)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Invitado de',
                  style: TextStyle(fontSize: 13, color: Paleta.pizarra),
                ),
                Text(
                  estudiante?.nombreCompleto ?? 'Invitado',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Paleta.tinta,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${estudiante?.curso ?? ''}, pase ${pase.numero} de ${pase.total}',
                  style: const TextStyle(fontSize: 15, color: Paleta.pizarra),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 12, 22, 18),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Código ${pase.id.toUpperCase()}',
                    style: const TextStyle(
                      fontSize: 12,
                      letterSpacing: 0.5,
                      color: Paleta.pizarra,
                    ),
                  ),
                ),
                if (pase.usado)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Paleta.paso.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Usado a las ${hora(pase.usadoEn!)}',
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
    );
  }
}

class PasesEstudiante extends StatefulWidget {
  final String eventoId;
  final String estudianteId;

  const PasesEstudiante({
    super.key,
    required this.eventoId,
    required this.estudianteId,
  });

  @override
  State<PasesEstudiante> createState() => _PasesEstudianteState();
}

class _PasesEstudianteState extends State<PasesEstudiante> {
  final Map<String, GlobalKey> _claves = {};
  bool _compartiendo = false;

  GlobalKey _clave(String paseId) =>
      _claves.putIfAbsent(paseId, () => GlobalKey());

  Future<void> _compartir(
      Evento ev, Estudiante? est, List<Pase> pases) async {
    setState(() => _compartiendo = true);
    try {
      // Pequeña espera para asegurar que las tarjetas estén pintadas.
      await Future<void>.delayed(const Duration(milliseconds: 60));
      final dir = await getTemporaryDirectory();
      final archivos = <XFile>[];
      for (final p in pases) {
        final ctx = _clave(p.id).currentContext;
        if (ctx == null) continue;
        final limite = ctx.findRenderObject() as RenderRepaintBoundary;
        final imagen = await limite.toImage(pixelRatio: 3);
        final datos = await imagen.toByteData(format: ui.ImageByteFormat.png);
        if (datos == null) continue;
        final archivo = File('${dir.path}/pase_${p.id}.png');
        await archivo.writeAsBytes(datos.buffer.asUint8List());
        archivos.add(XFile(archivo.path, mimeType: 'image/png'));
      }
      if (archivos.isEmpty) return;
      final nombre = est?.nombreCompleto ?? 'el estudiante';
      final curso = est == null ? '' : ' (${est.curso})';
      await Share.shareXFiles(
        archivos,
        text: 'Hola, te comparto ${archivos.length == 1 ? 'el pase' : 'los ${archivos.length} pases'} '
            'de $nombre$curso para «${ev.nombre}», ${fechaLarga(ev.fecha)}. '
            'Presenta el código QR en la entrada; cada pase permite un ingreso.',
      );
    } finally {
      if (mounted) setState(() => _compartiendo = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final a = Almacen.i;
    return ListenableBuilder(
      listenable: a,
      builder: (context, _) {
        final ev = a.eventoPorId(widget.eventoId);
        final est = a.estudiantePorId(widget.estudianteId);
        if (ev == null) return const Scaffold(body: SizedBox.shrink());
        final pases = a.pasesDeEstudiante(ev.id, widget.estudianteId);

        return Scaffold(
          appBar: AppBar(title: Text(est?.nombreCompleto ?? 'Pases')),
          body: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
            child: Center(
              child: Column(
                children: [
                  for (final p in pases) ...[
                    RepaintBoundary(
                      key: _clave(p.id),
                      child: TarjetaPase(pase: p, evento: ev, estudiante: est),
                    ),
                    const SizedBox(height: 16),
                  ],
                ],
              ),
            ),
          ),
          bottomNavigationBar: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: FilledButton.icon(
                onPressed: _compartiendo || pases.isEmpty
                    ? null
                    : () => _compartir(ev, est, pases),
                icon: _compartiendo
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.share_outlined),
                label: Text(_compartiendo
                    ? 'Preparando imágenes'
                    : 'Compartir por WhatsApp u otra app'),
              ),
            ),
          ),
        );
      },
    );
  }
}
