import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import 'codigo_qr.dart';
import 'formato.dart';
import 'modelos.dart';

/// Guarda todo en un archivo JSON dentro del celular.
/// En la versión con servidor, esta clase se convierte en la caché local
/// que se sincroniza con la API.
class Almacen extends ChangeNotifier {
  Almacen._();
  static final Almacen i = Almacen._();

  final List<Evento> eventos = [];
  final List<Estudiante> estudiantes = [];
  final List<Pase> pases = [];
  final List<Escaneo> escaneos = [];

  final Map<String, Evento> _eventoPorId = {};
  final Map<String, Estudiante> _estudiantePorId = {};
  final Map<String, Pase> _pasePorId = {};

  File? _archivo;
  Future<void> _escritura = Future.value();

  // ---------- Persistencia ----------

  Future<void> cargar() async {
    final dir = await getApplicationDocumentsDirectory();
    _archivo = File('${dir.path}/omega_access.json');
    final archivo = _archivo!;
    if (await archivo.exists()) {
      try {
        final j =
            jsonDecode(await archivo.readAsString()) as Map<String, dynamic>;
        eventos.addAll((j['eventos'] as List)
            .map((e) => Evento.fromJson(e as Map<String, dynamic>)));
        estudiantes.addAll((j['estudiantes'] as List)
            .map((e) => Estudiante.fromJson(e as Map<String, dynamic>)));
        pases.addAll((j['pases'] as List)
            .map((e) => Pase.fromJson(e as Map<String, dynamic>)));
        escaneos.addAll((j['escaneos'] as List)
            .map((e) => Escaneo.fromJson(e as Map<String, dynamic>)));
      } catch (_) {
        // Archivo dañado: se empieza vacío.
        eventos.clear();
        estudiantes.clear();
        pases.clear();
        escaneos.clear();
      }
    }
    _reindexar();
  }

  void _reindexar() {
    _eventoPorId
      ..clear()
      ..addEntries(eventos.map((e) => MapEntry(e.id, e)));
    _estudiantePorId
      ..clear()
      ..addEntries(estudiantes.map((e) => MapEntry(e.id, e)));
    _pasePorId
      ..clear()
      ..addEntries(pases.map((p) => MapEntry(p.id, p)));
  }

  void _cambio() {
    notifyListeners();
    final archivo = _archivo;
    if (archivo == null) return;
    final contenido = jsonEncode({
      'eventos': eventos.map((e) => e.toJson()).toList(),
      'estudiantes': estudiantes.map((e) => e.toJson()).toList(),
      'pases': pases.map((p) => p.toJson()).toList(),
      'escaneos': escaneos.map((e) => e.toJson()).toList(),
    });
    _escritura = _escritura.then((_) => archivo.writeAsString(contenido));
  }

  // ---------- Consultas ----------

  Evento? eventoPorId(String id) => _eventoPorId[id];
  Estudiante? estudiantePorId(String id) => _estudiantePorId[id];

  List<Pase> pasesDeEvento(String eventoId) =>
      pases.where((p) => p.eventoId == eventoId).toList();

  List<Pase> pasesDeEstudiante(String eventoId, String estudianteId) => pases
      .where((p) => p.eventoId == eventoId && p.estudianteId == estudianteId)
      .toList()
    ..sort((a, b) => a.numero.compareTo(b.numero));

  List<Curso> cursos() {
    final vistos = <String, Curso>{};
    for (final e in estudiantes) {
      vistos.putIfAbsent(e.claveCurso, () => Curso(e.grado, e.paralelo));
    }
    final lista = vistos.values.toList()..sort(compararCursos);
    return lista;
  }

  List<Estudiante> estudiantesDeCurso(String claveCurso) => estudiantes
      .where((e) => e.claveCurso == claveCurso)
      .toList()
    ..sort((a, b) => a.apellidos.compareTo(b.apellidos));

  int estudiantesSinPases(String eventoId, Set<String> clavesCurso) {
    final conPases = {
      for (final p in pases)
        if (p.eventoId == eventoId) p.estudianteId
    };
    return estudiantes
        .where((e) =>
            clavesCurso.contains(e.claveCurso) && !conPases.contains(e.id))
        .length;
  }

  // ---------- Cambios ----------

  Evento crearEvento({
    required String nombre,
    required String lugar,
    required DateTime fecha,
    int pasesPorPersona = 2,
  }) {
    final ev = Evento(
      id: nuevoId(8),
      nombre: nombre,
      lugar: lugar,
      fecha: fecha,
      pasesPorPersona: pasesPorPersona,
    );
    eventos.add(ev);
    _eventoPorId[ev.id] = ev;
    _cambio();
    return ev;
  }

  void eliminarEvento(String id) {
    eventos.removeWhere((e) => e.id == id);
    pases.removeWhere((p) => p.eventoId == id);
    escaneos.removeWhere((e) => e.eventoId == id);
    _reindexar();
    _cambio();
  }

  void agregarEstudiante({
    required String nombres,
    required String apellidos,
    required String grado,
    required String paralelo,
  }) {
    final e = Estudiante(
      id: nuevoId(),
      nombres: nombres,
      apellidos: apellidos,
      grado: grado,
      paralelo: paralelo,
    );
    estudiantes.add(e);
    _estudiantePorId[e.id] = e;
    _cambio();
  }

  /// Genera pases solo para quienes aún no tienen en este evento.
  int generarPases(Evento ev, Set<String> clavesCurso, int porPersona) {
    final conPases = {
      for (final p in pases)
        if (p.eventoId == ev.id) p.estudianteId
    };
    var creados = 0;
    for (final e in estudiantes) {
      if (!clavesCurso.contains(e.claveCurso) || conPases.contains(e.id)) {
        continue;
      }
      for (var k = 1; k <= porPersona; k++) {
        final p = Pase(
          id: nuevoId(),
          eventoId: ev.id,
          estudianteId: e.id,
          numero: k,
          total: porPersona,
        );
        pases.add(p);
        _pasePorId[p.id] = p;
        creados++;
      }
    }
    ev.pasesPorPersona = porPersona;
    _cambio();
    return creados;
  }

  void borrarTodo() {
    eventos.clear();
    estudiantes.clear();
    pases.clear();
    escaneos.clear();
    _reindexar();
    _cambio();
  }

  // ---------- Validación en la puerta ----------

  Escaneo validar(String texto, Evento evento) {
    final lectura = leerCodigo(texto);
    late Escaneo resultado;

    Escaneo crear(Veredicto v, String titulo, String? persona, String detalle) =>
        Escaneo(
          id: nuevoId(),
          eventoId: evento.id,
          fecha: DateTime.now(),
          veredicto: v,
          titulo: titulo,
          persona: persona,
          detalle: detalle,
        );

    if (lectura.error == ErrorLectura.formato) {
      resultado = crear(Veredicto.rechazado, 'Código no reconocido', null,
          'Este QR no pertenece a Omega Access Control.');
    } else if (lectura.error == ErrorLectura.firma) {
      resultado = crear(Veredicto.rechazado, 'Pase no válido', null,
          'El código fue alterado o no lo emitió el sistema.');
    } else if (lectura.eventoId != evento.id) {
      final otro = eventoPorId(lectura.eventoId!);
      resultado = crear(
        Veredicto.rechazado,
        'Pase de otro evento',
        null,
        otro != null
            ? 'Corresponde a: ${otro.nombre}.'
            : 'Corresponde a un evento que no está en este celular.',
      );
    } else {
      final pase = _pasePorId[lectura.paseId!];
      if (pase == null) {
        resultado = crear(
          Veredicto.advertencia,
          'Firma válida, pase sin registro',
          null,
          'El pase es auténtico pero no está en este celular. '
              'Verifica la identidad antes de dejar pasar.',
        );
      } else {
        final est = estudiantePorId(pase.estudianteId);
        final persona = est == null ? null : 'Invitado de ${est.nombreCompleto}';
        final curso = est == null ? '' : '${est.curso}, ';
        if (pase.usado) {
          resultado = crear(
            Veredicto.rechazado,
            'Pase ya utilizado',
            persona,
            'Ingresó a las ${hora(pase.usadoEn!)}. '
                '${curso}pase ${pase.numero} de ${pase.total}.',
          );
        } else {
          pase.usadoEn = DateTime.now();
          resultado = crear(
            Veredicto.valido,
            'Acceso registrado',
            persona,
            '${curso}pase ${pase.numero} de ${pase.total}.',
          );
        }
      }
    }

    escaneos.insert(0, resultado);
    _cambio();
    return resultado;
  }

  // ---------- Datos de prueba ----------

  void cargarDatosPrueba() {
    final azar = Random();
    const nombres = [
      'Mateo', 'Valentina', 'Santiago', 'Camila', 'Sebastián', 'Isabella',
      'Nicolás', 'Sofía', 'Emiliano', 'Martina', 'Joaquín', 'Luciana',
      'Benjamín', 'Daniela', 'Thiago', 'Antonella', 'Samuel', 'Emilia',
      'Gabriel', 'Renata', 'Dylan', 'Mía', 'Matías', 'Victoria', 'Alejandro',
      'Paula', 'David', 'Ariana', 'Kevin', 'Doménica',
    ];
    const apellidos = [
      'Guamán', 'Salinas', 'Pérez', 'Vásquez', 'Moreno', 'Cevallos',
      'Andrade', 'Paredes', 'Herrera', 'Castillo', 'Yánez', 'Chávez',
      'Ortiz', 'Vera', 'Quishpe', 'Zambrano', 'Mendoza', 'Rivera',
      'Salazar', 'Torres', 'Naranjo', 'Benítez', 'Llerena', 'Cando',
      'Tenelema', 'Ruiz', 'Proaño', 'Villacís', 'Aguirre', 'Mora',
    ];
    const grados = ['5.º', '6.º', '7.º'];
    const paralelos = ['A', 'B'];

    for (final g in grados) {
      for (final p in paralelos) {
        for (var k = 0; k < 30; k++) {
          final e = Estudiante(
            id: nuevoId(),
            nombres: nombres[azar.nextInt(nombres.length)],
            apellidos: '${apellidos[azar.nextInt(apellidos.length)]} '
                '${apellidos[azar.nextInt(apellidos.length)]}',
            grado: g,
            paralelo: p,
          );
          estudiantes.add(e);
          _estudiantePorId[e.id] = e;
        }
      }
    }

    final hoy = DateTime.now();
    final ev = Evento(
      id: nuevoId(8),
      nombre: 'Inauguración deportiva',
      lugar: 'Coliseo de la escuela',
      fecha: DateTime(hoy.year, hoy.month, hoy.day + 3, 9),
      pasesPorPersona: 2,
    );
    eventos.add(ev);
    _eventoPorId[ev.id] = ev;
    _cambio();
  }
}

int _numeroInicial(String s) {
  final m = RegExp(r'\d+').firstMatch(s);
  return m == null ? 9999 : int.parse(m.group(0)!);
}

int compararCursos(Curso a, Curso b) {
  final n = _numeroInicial(a.grado).compareTo(_numeroInicial(b.grado));
  if (n != 0) return n;
  final g = a.grado.compareTo(b.grado);
  if (g != 0) return g;
  return a.paralelo.compareTo(b.paralelo);
}
