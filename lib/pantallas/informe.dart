import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../almacen.dart';
import '../empresa.dart';
import '../formato.dart';
import '../modelos.dart';
import '../tema.dart';
import 'pdf_pases.dart';

/// Hoja con las opciones de informe de un evento.
Future<void> mostrarOpcionesInforme(BuildContext context, Evento ev) async {
  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
            child: Text(
              'Informe de ${ev.nombre}',
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w700,
                color: Paleta.tinta,
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Text(
              'Incluye las lecturas hechas en este celular. Para el total del '
              'evento, reúne los informes de todas las puertas.',
              style: TextStyle(color: Paleta.pizarra, height: 1.35),
            ),
          ),
          ListTile(
            leading:
                const Icon(Icons.picture_as_pdf_outlined, color: Paleta.tinta),
            title: const Text('Informe en PDF'),
            subtitle: const Text('Resumen por curso y lista de ingresos'),
            onTap: () async {
              Navigator.of(ctx).pop();
              await _ejecutar(context, () => compartirInformePdf(ev));
            },
          ),
          ListTile(
            leading: const Icon(Icons.table_view_outlined, color: Paleta.tinta),
            title: const Text('Datos para Excel (CSV)'),
            subtitle: const Text('Una fila por lectura, para unir puertas'),
            onTap: () async {
              Navigator.of(ctx).pop();
              await _ejecutar(context, () => compartirCsv(ev));
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
}

Future<void> _ejecutar(
    BuildContext context, Future<void> Function() tarea) async {
  final mensajero = ScaffoldMessenger.of(context);
  mensajero.showSnackBar(
      const SnackBar(content: Text('Preparando informe…')));
  try {
    await tarea();
  } catch (e) {
    mensajero.showSnackBar(
        SnackBar(content: Text('No se pudo crear el informe: $e')));
  }
}

String _puerta() {
  final n = Almacen.i.nombreCelular;
  return n.isEmpty ? 'Celular sin nombre' : n;
}

String _archivoBase(Evento ev) {
  final f = ev.fecha;
  final d = '${f.year}${f.month.toString().padLeft(2, '0')}'
      '${f.day.toString().padLeft(2, '0')}';
  final p = _puerta().replaceAll(RegExp(r'[^A-Za-z0-9]+'), '_');
  return 'Informe_${ev.id}_${d}_$p';
}

// ------------------------- CSV -------------------------

Future<void> compartirCsv(Evento ev) async {
  final a = Almacen.i;
  String c(Object? v) {
    final s = (v ?? '').toString().replaceAll('"', '""');
    return '"$s"';
  }

  final filas = <String>[
    [
      'Fecha', 'Hora', 'Evento', 'Puerta', 'Resultado', 'Motivo', 'Persona',
      'Curso', 'Pase', 'Detalle',
    ].map(c).join(';'),
  ];
  final lecturas = a.escaneos.where((e) => e.eventoId == ev.id).toList()
    ..sort((x, y) => x.fecha.compareTo(y.fecha));
  for (final e in lecturas) {
    filas.add([
      '${e.fecha.year}-${e.fecha.month.toString().padLeft(2, '0')}-'
          '${e.fecha.day.toString().padLeft(2, '0')}',
      '${hora(e.fecha)}:${e.fecha.second.toString().padLeft(2, '0')}',
      ev.nombre,
      e.puerta.isEmpty ? _puerta() : e.puerta,
      switch (e.veredicto) {
        Veredicto.valido => 'Ingreso',
        Veredicto.rechazado => 'Rechazado',
        Veredicto.advertencia => 'Verificar',
      },
      e.titulo,
      e.persona ?? '',
      e.curso ?? '',
      e.numero?.toString() ?? '',
      e.detalle,
    ].map(c).join(';'));
  }
  final dir = await getTemporaryDirectory();
  final archivo = File('${dir.path}/${_archivoBase(ev)}.csv');
  // BOM para que Excel reconozca tildes y eñes.
  await archivo.writeAsBytes([
    0xEF, 0xBB, 0xBF,
    ...utf8.encode(filas.join('\r\n')),
  ]);
  await Share.shareXFiles(
    [XFile(archivo.path, mimeType: 'text/csv')],
    text: 'Lecturas de «${ev.nombre}» en ${_puerta()}.',
  );
}

// ------------------------- PDF -------------------------

Future<void> compartirInformePdf(Evento ev) async {
  final a = Almacen.i;
  final r = await RecursosPdf.cargar();
  final lecturas = a.escaneos.where((e) => e.eventoId == ev.id).toList()
    ..sort((x, y) => x.fecha.compareTo(y.fecha));
  final ingresos =
      lecturas.where((e) => e.veredicto == Veredicto.valido).toList();
  final rechazos =
      lecturas.where((e) => e.veredicto == Veredicto.rechazado).length;
  final avisos =
      lecturas.where((e) => e.veredicto == Veredicto.advertencia).toList();
  final totalPases = a.totalPases(ev);
  final cursos = a.cursosDeEvento(ev);
  final extras = a.extrasDe(ev);
  final usadosExtra = extras.fold<int>(0, (s, x) {
    var n = 0;
    for (final p in a.pasesExtraDe(x)) {
      if (a.usoDeExtra(p) != null) n++;
    }
    return s + n;
  });
  final generado = DateTime.now();

  pw.TextStyle t(double tam, {bool negrita = false, PdfColor? color}) =>
      pw.TextStyle(
        font: negrita ? r.seminegrita : r.normal,
        fontSize: tam,
        color: color ?? PdfColors.black,
      );

  pw.Widget cifra(String valor, String etiqueta, PdfColor color) =>
      pw.Expanded(
        child: pw.Container(
          margin: const pw.EdgeInsets.symmetric(horizontal: 3),
          padding: const pw.EdgeInsets.all(10),
          decoration: pw.BoxDecoration(
            color: pdfCeleste,
            borderRadius: pw.BorderRadius.circular(6),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(valor,
                  style: pw.TextStyle(
                      font: r.condensada, fontSize: 22, color: color)),
              pw.Text(etiqueta, style: t(8, color: pdfPizarra)),
            ],
          ),
        ),
      );

  final doc = pw.Document(
    title: 'Informe - ${ev.nombre}',
    author: Empresa.producto,
  );

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.fromLTRB(36, 32, 36, 32),
      maxPages: 400,
      header: (context) => pw.Container(
        padding: const pw.EdgeInsets.only(bottom: 8),
        margin: const pw.EdgeInsets.only(bottom: 12),
        decoration: const pw.BoxDecoration(
          border: pw.Border(bottom: pw.BorderSide(color: pdfTinta, width: 2)),
        ),
        child: pw.Row(
          children: [
            pw.Image(r.escuela, width: 38, height: 38),
            pw.SizedBox(width: 10),
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(a.institucion, style: t(10, negrita: true, color: pdfTinta)),
                  pw.Text('Informe de accesos, periodo ${a.periodo}',
                      style: t(8.5, color: pdfPizarra)),
                ],
              ),
            ),
            pw.Image(r.omegaAccess, height: 30),
          ],
        ),
      ),
      footer: (context) => pw.Row(
        children: [
          pw.Expanded(
            child: pw.Text(
              'Generado con ${Empresa.producto} el ${fechaLarga(generado)} a las '
              '${hora(generado)}. ${Empresa.nombre}, ${Empresa.web}',
              style: t(7.5, color: pdfPizarra),
            ),
          ),
          pw.Text('Página ${context.pageNumber} de ${context.pagesCount}',
              style: t(7.5, color: pdfPizarra)),
        ],
      ),
      build: (context) => [
        pw.Text(ev.nombre,
            style: pw.TextStyle(font: r.condensada, fontSize: 22, color: pdfTinta)),
        pw.Text(
          '${fechaLarga(ev.fecha)}${ev.lugar.isEmpty ? '' : ', ${ev.lugar}'}. '
          'Puerta: ${_puerta()}.',
          style: t(10, color: pdfPizarra),
        ),
        if (lecturas.isNotEmpty)
          pw.Text(
            'Primera lectura ${hora(lecturas.first.fecha)}, última '
            '${hora(lecturas.last.fecha)}.',
            style: t(10, color: pdfPizarra),
          ),
        pw.SizedBox(height: 12),
        pw.Row(
          children: [
            cifra('$totalPases', 'Pases emitidos', pdfTinta),
            cifra('${ingresos.length}', 'Ingresos en esta puerta', pdfVerde),
            cifra('$rechazos', 'Rechazados', const PdfColor.fromInt(0xFFD12F2F)),
            cifra('${avisos.length}', 'Por verificar',
                const PdfColor.fromInt(0xFFE39B12)),
          ],
        ),
        pw.SizedBox(height: 18),
        pw.Text('Ingresos por curso', style: t(13, negrita: true, color: pdfTinta)),
        pw.SizedBox(height: 6),
        pw.TableHelper.fromTextArray(
          headers: ['Curso', 'Estudiantes', 'Pases', 'Ingresos', '%'],
          data: [
            for (final c in cursos)
              () {
                final est = a.estudiantesDeCurso(c.clave).length;
                final pases = est * ev.pasesPorPersona;
                final usados = a.usadosDeCurso(ev, c.clave);
                return [
                  c.nombre,
                  '$est',
                  '$pases',
                  '$usados',
                  pases == 0 ? '0' : '${(usados * 100 / pases).round()}',
                ];
              }(),
            if (extras.isNotEmpty)
              [
                'Accesos adicionales',
                '${extras.length}',
                '${extras.fold<int>(0, (s, x) => s + x.total)}',
                '$usadosExtra',
                '',
              ],
          ],
          headerStyle: t(9, negrita: true, color: PdfColors.white),
          headerDecoration: const pw.BoxDecoration(color: pdfTinta),
          cellStyle: t(9),
          cellAlignments: {
            1: pw.Alignment.centerRight,
            2: pw.Alignment.centerRight,
            3: pw.Alignment.centerRight,
            4: pw.Alignment.centerRight,
          },
          oddRowDecoration: const pw.BoxDecoration(color: pdfCeleste),
          border: null,
          cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        ),
        pw.SizedBox(height: 18),
        pw.Text('Detalle de ingresos (${ingresos.length})',
            style: t(13, negrita: true, color: pdfTinta)),
        pw.SizedBox(height: 6),
        if (ingresos.isEmpty)
          pw.Text('Sin ingresos registrados en este celular.', style: t(10))
        else
          pw.TableHelper.fromTextArray(
            headers: ['Hora', 'Invitado de', 'Curso', 'Pase'],
            data: [
              for (final e in ingresos)
                [
                  hora(e.fecha),
                  (e.persona ?? '').replaceFirst('Invitado de ', ''),
                  e.curso ?? '',
                  e.numero?.toString() ?? '',
                ],
            ],
            headerStyle: t(9, negrita: true, color: PdfColors.white),
            headerDecoration: const pw.BoxDecoration(color: pdfTinta),
            cellStyle: t(8.5),
            oddRowDecoration: const pw.BoxDecoration(color: pdfCeleste),
            border: null,
            cellPadding:
                const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            columnWidths: {
              0: const pw.FixedColumnWidth(40),
              1: const pw.FlexColumnWidth(3),
              2: const pw.FlexColumnWidth(2),
              3: const pw.FixedColumnWidth(32),
            },
          ),
        if (lecturas.any((e) => e.veredicto != Veredicto.valido)) ...[
          pw.SizedBox(height: 18),
          pw.Text('Lecturas rechazadas o por verificar',
              style: t(13, negrita: true, color: pdfTinta)),
          pw.SizedBox(height: 6),
          pw.TableHelper.fromTextArray(
            headers: ['Hora', 'Motivo', 'Detalle'],
            data: [
              for (final e in lecturas)
                if (e.veredicto != Veredicto.valido)
                  [
                    hora(e.fecha),
                    e.titulo,
                    [if (e.persona != null) e.persona!, e.detalle].join('. '),
                  ],
            ],
            headerStyle: t(9, negrita: true, color: PdfColors.white),
            headerDecoration: const pw.BoxDecoration(color: pdfTinta),
            cellStyle: t(8.5),
            oddRowDecoration: const pw.BoxDecoration(color: pdfCeleste),
            border: null,
            cellPadding:
                const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            columnWidths: {
              0: const pw.FixedColumnWidth(40),
              1: const pw.FlexColumnWidth(2),
              2: const pw.FlexColumnWidth(4),
            },
          ),
        ],
      ],
    ),
  );

  final dir = await getTemporaryDirectory();
  final archivo = File('${dir.path}/${_archivoBase(ev)}.pdf');
  await archivo.writeAsBytes(await doc.save());
  await Share.shareXFiles(
    [XFile(archivo.path, mimeType: 'application/pdf')],
    text: 'Informe de accesos de «${ev.nombre}», ${_puerta()}.',
  );
}
