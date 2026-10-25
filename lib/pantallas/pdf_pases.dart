import 'dart:io';

import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../almacen.dart';
import '../codigo_qr.dart';
import '../formato.dart';
import '../modelos.dart';

const pdfTinta = PdfColor.fromInt(0xFF0E3E80);
const pdfPizarra = PdfColor.fromInt(0xFF4A5A6E);
const pdfLinea = PdfColor.fromInt(0xFFB8C6D6);
const pdfVerde = PdfColor.fromInt(0xFF109B4E);
const pdfCeleste = PdfColor.fromInt(0xFFEFF5FB);

/// Recursos compartidos por los PDF (fuentes y logos).
class RecursosPdf {
  final pw.Font normal;
  final pw.Font seminegrita;
  final pw.Font condensada;
  final pw.MemoryImage icono;
  final pw.MemoryImage escuela;
  final pw.MemoryImage omegaAccess;

  RecursosPdf._(this.normal, this.seminegrita, this.condensada, this.icono,
      this.escuela, this.omegaAccess);

  static Future<RecursosPdf> cargar() async {
    Future<pw.MemoryImage> img(String ruta) async =>
        pw.MemoryImage((await rootBundle.load(ruta)).buffer.asUint8List());
    return RecursosPdf._(
      pw.Font.ttf(await rootBundle.load('assets/fonts/Barlow-Regular.ttf')),
      pw.Font.ttf(await rootBundle.load('assets/fonts/Barlow-SemiBold.ttf')),
      pw.Font.ttf(
          await rootBundle.load('assets/fonts/BarlowCondensed-ExtraBold.ttf')),
      await img('assets/img/icono.png'),
      await img('assets/img/escuela.png'),
      await img('assets/img/omega_access.png'),
    );
  }
}

/// Datos de una tarjeta del PDF, sea de estudiante o acceso adicional.
class _DatosTarjeta {
  final String codigo;
  final String etiqueta; // "Invitado de" o "Acceso adicional"
  final String nombre;
  final String detalle;
  final String pase;
  const _DatosTarjeta(
      this.codigo, this.etiqueta, this.nombre, this.detalle, this.pase);
}

String _nombreArchivo(String base) {
  final limpio = base
      .replaceAll('.º', '')
      .replaceAll(RegExp(r'[^A-Za-z0-9áéíóúñÁÉÍÓÚÑ]+'), '_')
      .replaceAll(RegExp(r'_+'), '_');
  return 'Pases_$limpio.pdf';
}

/// Un PDF con los pases de uno o varios cursos. Cada curso empieza en una
/// hoja nueva para que se pueda repartir por separado.
Future<File> crearPdfDeCursos(Evento ev, List<Curso> cursos,
    {String? titulo}) async {
  final a = Almacen.i;
  final r = await RecursosPdf.cargar();
  final doc = pw.Document(
    title: 'Pases - ${ev.nombre}',
    author: 'Omega Access Control',
  );
  for (final c in cursos) {
    final tarjetas = <_DatosTarjeta>[
      for (final e in a.estudiantesDeCurso(c.clave))
        for (final p in a.pasesDe(ev, e))
          _DatosTarjeta(codificarPase(p), 'Invitado de', e.nombre, e.curso,
              'Pase ${p.numero} de ${p.total}'),
    ];
    _agregarHojas(doc, r, ev, tarjetas, c.nombre, a.institucion);
  }
  final nombre = titulo ??
      (cursos.length == 1 ? cursos.first.nombre : '${cursos.length}_cursos');
  return _guardar(doc, _nombreArchivo('${nombre}_${ev.id}'));
}

Future<File> crearPdfDeExtra(Evento ev, AccesoExtra x) async {
  final a = Almacen.i;
  final r = await RecursosPdf.cargar();
  final doc = pw.Document(title: 'Pases - ${ev.nombre}');
  final tarjetas = [
    for (final p in a.pasesExtraDe(x))
      _DatosTarjeta(codificarPaseExtra(p), 'Acceso adicional', x.nombre,
          x.detalle, 'Pase ${p.numero} de ${x.total}'),
  ];
  _agregarHojas(doc, r, ev, tarjetas, 'Acceso adicional: ${x.nombre}',
      a.institucion);
  return _guardar(doc, _nombreArchivo('${x.nombre}_${ev.id}'));
}

Future<void> compartirPdfDeCurso(Evento ev, Curso curso) async {
  final archivo = await crearPdfDeCursos(ev, [curso]);
  await Share.shareXFiles(
    [XFile(archivo.path, mimeType: 'application/pdf')],
    text: mensajePases(ev, curso.nombre),
  );
}

String mensajePases(Evento ev, String grupo) =>
    'Pases de $grupo para «${ev.nombre}», ${fechaLarga(ev.fecha)}. '
    'Cada estudiante tiene ${ev.pasesPorPersona} pases y cada pase permite un '
    'ingreso. Por favor, reenvíe a cada familia sus pases o imprímalos.';

Future<File> _guardar(pw.Document doc, String nombre) async {
  final dir = await getTemporaryDirectory();
  final archivo = File('${dir.path}/$nombre');
  await archivo.writeAsBytes(await doc.save());
  return archivo;
}

void _agregarHojas(pw.Document doc, RecursosPdf r, Evento ev,
    List<_DatosTarjeta> tarjetas, String grupo, String institucion) {
  const porHoja = 6;
  final hojas = (tarjetas.length / porHoja).ceil();
  for (var h = 0; h < hojas; h++) {
    final g = tarjetas.skip(h * porHoja).take(porHoja).toList();
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(22, 22, 22, 18),
        build: (context) => pw.Column(
          children: [
            pw.Expanded(
              child: pw.Column(
                children: [
                  for (var fila = 0; fila < 3; fila++)
                    pw.Expanded(
                      child: pw.Row(
                        children: [
                          for (var col = 0; col < 2; col++)
                            pw.Expanded(
                              child: (fila * 2 + col) < g.length
                                  ? _tarjeta(r, ev, g[fila * 2 + col],
                                      institucion)
                                  : pw.SizedBox(),
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            pw.SizedBox(height: 6),
            pw.Row(
              children: [
                pw.Expanded(
                  child: pw.Text(
                    '$grupo. ${ev.nombre}',
                    style: pw.TextStyle(
                        font: r.normal, fontSize: 8, color: pdfPizarra),
                  ),
                ),
                pw.Text(
                  'Hoja ${h + 1} de $hojas',
                  style: pw.TextStyle(
                      font: r.normal, fontSize: 8, color: pdfPizarra),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

pw.Widget _tarjeta(
    RecursosPdf r, Evento ev, _DatosTarjeta t, String institucion) {
  return pw.Container(
    margin: const pw.EdgeInsets.all(4),
    decoration: pw.BoxDecoration(
      border: pw.Border.all(
        color: pdfLinea,
        width: 0.8,
        style: pw.BorderStyle.dashed,
      ),
    ),
    child: pw.Stack(
      children: [
        // Marca de agua con el escudo de la institución
        pw.Positioned.fill(
          child: pw.Center(
            child: pw.Opacity(
              opacity: 0.07,
              child: pw.Image(r.escuela, width: 170, height: 170),
            ),
          ),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.fromLTRB(12, 10, 12, 8),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                children: [
                  pw.ClipRRect(
                    horizontalRadius: 3,
                    verticalRadius: 3,
                    child: pw.Image(r.icono, width: 18, height: 18),
                  ),
                  pw.SizedBox(width: 6),
                  pw.Expanded(
                    child: pw.Text(
                      institucion,
                      maxLines: 2,
                      style: pw.TextStyle(
                          font: r.normal, fontSize: 7, color: pdfPizarra),
                    ),
                  ),
                  pw.SizedBox(width: 6),
                  pw.Image(r.escuela, width: 22, height: 22),
                ],
              ),
              pw.SizedBox(height: 5),
              pw.Text(
                ev.nombre,
                maxLines: 2,
                style: pw.TextStyle(
                    font: r.condensada, fontSize: 13.5, color: pdfTinta),
              ),
              pw.Text(
                ev.lugar.isEmpty
                    ? fechaLarga(ev.fecha)
                    : '${fechaLarga(ev.fecha)}, ${ev.lugar}',
                maxLines: 1,
                style:
                    pw.TextStyle(font: r.normal, fontSize: 8, color: pdfPizarra),
              ),
              pw.Expanded(
                child: pw.Center(
                  child: pw.Container(
                    color: PdfColors.white,
                    padding: const pw.EdgeInsets.all(3),
                    child: pw.BarcodeWidget(
                      barcode: pw.Barcode.qrCode(),
                      data: t.codigo,
                      width: 104,
                      height: 104,
                      color: pdfTinta,
                      backgroundColor: PdfColors.white,
                    ),
                  ),
                ),
              ),
              pw.Text(
                t.etiqueta,
                style:
                    pw.TextStyle(font: r.normal, fontSize: 7, color: pdfPizarra),
              ),
              pw.Text(
                t.nombre,
                maxLines: 2,
                style: pw.TextStyle(
                    font: r.seminegrita, fontSize: 10, color: pdfTinta),
              ),
              pw.SizedBox(height: 2),
              pw.Row(
                children: [
                  pw.Expanded(
                    child: pw.Text(
                      t.detalle,
                      maxLines: 1,
                      style: pw.TextStyle(
                          font: r.normal, fontSize: 8, color: pdfPizarra),
                    ),
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                        horizontal: 5, vertical: 1.5),
                    decoration: pw.BoxDecoration(
                      color: pdfVerde,
                      borderRadius: pw.BorderRadius.circular(6),
                    ),
                    child: pw.Text(
                      t.pase,
                      style: pw.TextStyle(
                          font: r.seminegrita,
                          fontSize: 7.5,
                          color: PdfColors.white),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
