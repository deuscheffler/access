import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:archive/archive.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../almacen.dart';
import '../formato.dart';
import '../modelos.dart';
import '../tema.dart';
import 'pases.dart';

/// WhatsApp permite enviar hasta 100 imágenes en un solo envío.
const int limiteWhatsApp = 100;

/// Dibuja cada pase como una imagen PNG independiente (1000 x 1400 px), con
/// el nombre del estudiante escrito, para que la docente reenvíe a cada
/// familia únicamente sus propios pases.
class GeneradorImagenes {
  final ui.Image _icono;
  final ui.Image _escudo;
  final String _institucion;

  GeneradorImagenes._(this._icono, this._escudo, this._institucion);

  static Future<ui.Image> _cargar(String ruta) async {
    final datos = await rootBundle.load(ruta);
    final codec = await ui.instantiateImageCodec(datos.buffer.asUint8List());
    return (await codec.getNextFrame()).image;
  }

  static Future<GeneradorImagenes> crear() async => GeneradorImagenes._(
        await _cargar('assets/img/icono.png'),
        await _cargar('assets/img/escuela.png'),
        Almacen.i.institucion,
      );

  static const double _ancho = 1000;
  static const double _alto = 1400;
  static const double _margen = 56;

  ui.Paragraph _texto(
    String texto, {
    required double tam,
    Color color = Paleta.tinta,
    String familia = 'Barlow',
    FontWeight peso = FontWeight.w400,
    int lineas = 2,
    double? ancho,
  }) {
    final b = ui.ParagraphBuilder(ui.ParagraphStyle(
      fontFamily: familia,
      fontSize: tam,
      fontWeight: peso,
      maxLines: lineas,
      ellipsis: '…',
      height: 1.15,
    ))
      ..pushStyle(ui.TextStyle(
        color: color,
        fontFamily: familia,
        fontSize: tam,
        fontWeight: peso,
      ))
      ..addText(texto);
    return b.build()
      ..layout(ui.ParagraphConstraints(width: ancho ?? _ancho - 2 * _margen));
  }

  void _imagen(Canvas c, ui.Image img, Rect destino, {double opacidad = 1}) {
    final origen =
        Rect.fromLTWH(0, 0, img.width.toDouble(), img.height.toDouble());
    final paint = Paint()
      ..filterQuality = FilterQuality.high
      ..color = Color.fromRGBO(0, 0, 0, opacidad);
    c.drawImageRect(img, origen, destino, paint);
  }

  Future<Uint8List> dibujar(DatosPase d, Evento ev) async {
    final grabadora = ui.PictureRecorder();
    final c = Canvas(grabadora, const Rect.fromLTWH(0, 0, _ancho, _alto));
    const m = _margen;

    // Fondo y borde
    c.drawRect(const Rect.fromLTWH(0, 0, _ancho, _alto),
        Paint()..color = Colors.white);
    c.drawRRect(
      RRect.fromRectAndRadius(
          const Rect.fromLTWH(14, 14, _ancho - 28, _alto - 28),
          const Radius.circular(36)),
      Paint()
        ..color = Paleta.linea
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4,
    );

    // Marca de agua con el escudo
    _imagen(c, _escudo,
        Rect.fromCenter(center: const Offset(_ancho / 2, 820), width: 720, height: 720),
        opacidad: 0.06);

    // Cabecera: ícono, institución y escudo
    c.save();
    c.clipRRect(RRect.fromRectAndRadius(
        const Rect.fromLTWH(m, 52, 104, 104), const Radius.circular(24)));
    _imagen(c, _icono, const Rect.fromLTWH(m, 52, 104, 104));
    c.restore();
    _imagen(c, _escudo, const Rect.fromLTWH(_ancho - m - 120, 44, 120, 120));
    final inst = _texto(_institucion,
        tam: 30, peso: FontWeight.w600, ancho: _ancho - 2 * m - 104 - 120 - 48);
    c.drawParagraph(inst, Offset(m + 104 + 24, 104 - inst.height / 2));
    c.drawRect(const Rect.fromLTWH(m, 190, _ancho - 2 * m, 7),
        Paint()..color = Paleta.tinta);

    // Evento y fecha
    var y = 228.0;
    final titulo = _texto(ev.nombre,
        tam: 62, familia: 'BarlowCondensed', peso: FontWeight.w800);
    c.drawParagraph(titulo, Offset(m, y));
    y += titulo.height + 8;
    final fecha = _texto(
      ev.lugar.isEmpty ? fechaLarga(ev.fecha) : '${fechaLarga(ev.fecha)}, ${ev.lugar}',
      tam: 32,
      color: Paleta.pizarra,
      lineas: 1,
    );
    c.drawParagraph(fecha, Offset(m, y));

    // Código QR sobre un recuadro blanco
    const lado = 560.0;
    const qrY = 470.0;
    const qrX = (_ancho - lado) / 2;
    c.drawRRect(
      RRect.fromRectAndRadius(
          const Rect.fromLTWH(qrX - 24, qrY - 24, lado + 48, lado + 48),
          const Radius.circular(24)),
      Paint()..color = Colors.white,
    );
    final qr = QrPainter(
      data: d.codigo,
      version: QrVersions.auto,
      gapless: true,
      eyeStyle: const QrEyeStyle(
          eyeShape: QrEyeShape.square, color: Paleta.tinta),
      dataModuleStyle: const QrDataModuleStyle(
          dataModuleShape: QrDataModuleShape.square, color: Paleta.tinta),
    );
    c.save();
    c.translate(qrX, qrY);
    qr.paint(c, const Size(lado, lado));
    c.restore();

    // Persona
    y = qrY + lado + 60;
    c.drawRect(Rect.fromLTWH(m, y, _ancho - 2 * m, 2),
        Paint()..color = Paleta.linea);
    y += 26;
    final etiqueta = _texto(d.etiqueta, tam: 30, color: Paleta.pizarra, lineas: 1);
    c.drawParagraph(etiqueta, Offset(m, y));
    y += etiqueta.height + 4;
    final nombre = _texto(d.nombre, tam: 50, peso: FontWeight.w700);
    c.drawParagraph(nombre, Offset(m, y));
    y += nombre.height + 6;
    if (d.detalle.isNotEmpty) {
      final det = _texto(d.detalle, tam: 34, color: Paleta.pizarra, lineas: 1);
      c.drawParagraph(det, Offset(m, y));
    }

    // Pie: marca y número de pase
    const pieY = _alto - 120;
    final marca = _texto('Omega Access', tam: 28, color: Paleta.pizarra,
        peso: FontWeight.w600, lineas: 1);
    c.drawParagraph(marca, Offset(m, pieY + 30 - marca.height / 2));
    final numero = _texto(d.numero, tam: 36, color: Colors.white,
        peso: FontWeight.w700, lineas: 1, ancho: 400);
    final anchoPill = numero.longestLine + 56;
    final pill = RRect.fromRectAndRadius(
      Rect.fromLTWH(_ancho - m - anchoPill, pieY, anchoPill, 60),
      const Radius.circular(30),
    );
    c.drawRRect(pill, Paint()..color = Paleta.paso);
    c.drawParagraph(numero,
        Offset(pill.left + 28, pieY + 30 - numero.height / 2));

    final imagen =
        await grabadora.endRecording().toImage(_ancho.toInt(), _alto.toInt());
    final bytes = await imagen.toByteData(format: ui.ImageByteFormat.png);
    imagen.dispose();
    return bytes!.buffer.asUint8List();
  }
}

String _limpiar(String s) => s
    .replaceAll('.º', '')
    .replaceAll(RegExp(r'[^A-Za-z0-9áéíóúñÁÉÍÓÚÑ]+'), '_')
    .replaceAll(RegExp(r'_+'), '_')
    .replaceAll(RegExp(r'^_|_$'), '');

/// Pases de los cursos en orden: por curso, por estudiante y por número,
/// así los dos pases de cada estudiante quedan juntos.
List<DatosPase> pasesDeCursos(Evento ev, List<Curso> cursos) {
  final a = Almacen.i;
  return [
    for (final c in cursos)
      for (final e in a.estudiantesDeCurso(c.clave))
        for (final p in a.pasesDe(ev, e)) DatosPase.deEstudiante(p, e),
  ];
}

/// Crea los archivos PNG. Cada nombre lleva un número de orden, el curso,
/// el estudiante y el número de pase.
Future<List<File>> crearImagenes(
  Evento ev,
  List<DatosPase> pases, {
  void Function(int hecho, int total)? progreso,
}) async {
  final gen = await GeneradorImagenes.crear();
  final base = await getTemporaryDirectory();
  final dir = Directory('${base.path}/pases_${ev.id}');
  if (await dir.exists()) await dir.delete(recursive: true);
  await dir.create(recursive: true);

  final archivos = <File>[];
  for (var i = 0; i < pases.length; i++) {
    final d = pases[i];
    final bytes = await gen.dibujar(d, ev);
    final orden = (i + 1).toString().padLeft(3, '0');
    final pase = d.numero.replaceAll(RegExp(r'[^0-9]+'), '_');
    final nombre = '${orden}_${_limpiar(d.detalle)}_${_limpiar(d.nombre)}'
        '_pase$pase.png';
    final f = File('${dir.path}/$nombre');
    await f.writeAsBytes(bytes);
    archivos.add(f);
    progreso?.call(i + 1, pases.length);
  }
  return archivos;
}

Future<void> compartirImagenes(List<File> archivos, String texto) async {
  await Share.shareXFiles(
    [for (final f in archivos) XFile(f.path, mimeType: 'image/png')],
    text: texto,
  );
}

/// Empaqueta las imágenes en un ZIP, útil para guardarlas en una computadora
/// o en Drive y enviarlas desde ahí.
Future<File> crearZip(List<File> archivos, String nombre) async {
  final zip = Archive();
  for (final f in archivos) {
    final bytes = await f.readAsBytes();
    zip.addFile(ArchiveFile(f.uri.pathSegments.last, bytes.length, bytes));
  }
  final datos = ZipEncoder().encode(zip)!;
  final dir = await getTemporaryDirectory();
  final archivo = File('${dir.path}/${_limpiar(nombre)}.zip');
  await archivo.writeAsBytes(datos);
  return archivo;
}

String mensajeImagenes(Evento ev, String grupo) =>
    'Pases individuales de $grupo para «${ev.nombre}», '
    '${fechaLarga(ev.fecha)}. Cada imagen lleva el nombre del estudiante: '
    'por favor, reenvíe a cada familia solo los pases de su hijo o hija. '
    'Cada pase permite un ingreso.';

/// Ejecuta una tarea larga mostrando un diálogo con el avance.
Future<T?> conProgreso<T>(
  BuildContext context,
  String titulo,
  Future<T> Function(void Function(int hecho, int total) avance) tarea,
) async {
  final estado = ValueNotifier<String>('Preparando…');
  final navegador = Navigator.of(context, rootNavigator: true);
  final mensajero = ScaffoldMessenger.of(context);
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => PopScope(
      canPop: false,
      child: AlertDialog(
        title: Text(titulo),
        content: Row(
          children: [
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(strokeWidth: 3),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: ValueListenableBuilder<String>(
                valueListenable: estado,
                builder: (_, v, __) => Text(v),
              ),
            ),
          ],
        ),
      ),
    ),
  );
  try {
    final r = await tarea((h, t) => estado.value = 'Imagen $h de $t');
    navegador.pop();
    return r;
  } catch (e) {
    navegador.pop();
    mensajero.showSnackBar(SnackBar(content: Text('No se pudo completar: $e')));
    return null;
  } finally {
    estado.dispose();
  }
}

/// Opciones para compartir los pases de uno o varios cursos.
Future<void> mostrarOpcionesCompartir(
    BuildContext context, Evento ev, List<Curso> cursos, String grupo,
    {Future<void> Function()? alEnviarPdf}) async {
  final total = cursos.fold<int>(
      0,
      (s, c) =>
          s + Almacen.i.estudiantesDeCurso(c.clave).length * ev.pasesPorPersona);
  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Text(
              'Compartir pases de $grupo',
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w700,
                color: Paleta.tinta,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined,
                color: Paleta.paso),
            title: const Text('Imágenes individuales'),
            subtitle: Text(total <= limiteWhatsApp
                ? '$total imágenes, una por pase, para reenviar a cada familia'
                : '$total imágenes; WhatsApp acepta $limiteWhatsApp por envío, '
                    'se enviarán por paralelo'),
            onTap: () async {
              Navigator.of(ctx).pop();
              await enviarImagenes(context, ev, cursos, grupo);
            },
          ),
          ListTile(
            leading: const Icon(Icons.folder_zip_outlined, color: Paleta.tinta),
            title: const Text('Descargar todas en un ZIP'),
            subtitle: const Text('Para guardar en Drive o en una computadora'),
            onTap: () async {
              Navigator.of(ctx).pop();
              final pases = pasesDeCursos(ev, cursos);
              final zip = await conProgreso<File>(
                context,
                'Creando imágenes',
                (avance) async {
                  final f = await crearImagenes(ev, pases, progreso: avance);
                  return crearZip(f, 'Pases_${grupo}_${ev.id}');
                },
              );
              if (zip != null) {
                await Share.shareXFiles(
                  [XFile(zip.path, mimeType: 'application/zip')],
                  text: mensajeImagenes(ev, grupo),
                );
              }
            },
          ),
          if (alEnviarPdf != null)
            ListTile(
              leading: const Icon(Icons.print_outlined, color: Paleta.tinta),
              title: const Text('PDF para imprimir'),
              subtitle: const Text('6 pases por hoja, con líneas de corte. '
                  'No lo envíes a las familias.'),
              onTap: () async {
                Navigator.of(ctx).pop();
                await alEnviarPdf();
              },
            ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
}

/// Genera y comparte las imágenes. Si superan el límite de WhatsApp, deja
/// elegir paralelo por paralelo.
Future<void> enviarImagenes(
    BuildContext context, Evento ev, List<Curso> cursos, String grupo) async {
  final a = Almacen.i;
  final total = cursos.fold<int>(
      0, (s, c) => s + a.estudiantesDeCurso(c.clave).length * ev.pasesPorPersona);

  Future<void> enviar(List<Curso> lista, String nombre) async {
    final pases = pasesDeCursos(ev, lista);
    final archivos = await conProgreso<List<File>>(
      context,
      'Creando imágenes',
      (avance) => crearImagenes(ev, pases, progreso: avance),
    );
    if (archivos != null && archivos.isNotEmpty) {
      await compartirImagenes(archivos, mensajeImagenes(ev, nombre));
    }
  }

  if (total <= limiteWhatsApp || cursos.length == 1) {
    await enviar(cursos, grupo);
    return;
  }
  if (!context.mounted) return;
  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (ctx) => SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
            maxHeight: MediaQuery.of(ctx).size.height * 0.75),
        child: ListView(
          shrinkWrap: true,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, 4),
              child: Text(
                'Enviar por paralelo',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                  color: Paleta.tinta,
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Text(
                'WhatsApp acepta hasta 100 imágenes por envío. Envía cada '
                'paralelo por separado al mismo chat.',
                style: TextStyle(color: Paleta.pizarra, height: 1.35),
              ),
            ),
            for (final c in cursos)
              ListTile(
                leading: const Icon(Icons.photo_library_outlined,
                    color: Paleta.paso),
                title: Text(c.nombre),
                subtitle: Text(
                    '${a.estudiantesDeCurso(c.clave).length * ev.pasesPorPersona} imágenes'),
                trailing: const Icon(Icons.send_outlined),
                onTap: () async {
                  Navigator.of(ctx).pop();
                  await enviar([c], c.nombre);
                },
              ),
          ],
        ),
      ),
    ),
  );
}
