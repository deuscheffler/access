import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';

import 'codigo_qr.dart';
import 'formato.dart';
import 'modelos.dart';

/// Datos de la app.
/// - Nómina: viene dentro de la app (assets/nomina.json), solo lectura.
/// - Eventos, pases usados y registro: se guardan en este celular.
class Almacen extends ChangeNotifier {
  Almacen._();
  static final Almacen i = Almacen._();

  String institucion = '';
  String periodo = '';

  final List<Estudiante> estudiantes = [];
  final Map<String, Estudiante> _estudiantePorId = {};
  List<Curso> _cursos = [];

  final List<Evento> eventos = [];

  /// Pases usados en ESTE celular: evento -> (estudiante.número -> hora).
  final Map<String, Map<String, DateTime>> usos = {};

  /// Cursos que atiende la puerta de este celular, por evento.
  /// Vacío = todos los cursos del evento.
  final Map<String, Set<String>> puertas = {};

  final List<Escaneo> escaneos = [];

  /// Accesos adicionales creados en este celular.
  final List<AccesoExtra> extras = [];

  /// Nombre de este celular o puerta, aparece en los informes.
  String nombreCelular = '';

  /// Último número de WhatsApp usado para cada grupo de cursos.
  final Map<String, String> contactos = {};

  bool _precargaHecha = false;

  /// Docente de cada paralelo (assets/docentes.json).
  final Map<String, Docente> _docentes = {};

  /// Datos de contacto de la institución.
  String escuelaDireccion = '';
  String escuelaTelefono = '';
  String escuelaCorreo = '';

  /// Envíos a docentes ya hechos: "evento|curso" -> fecha.
  final Map<String, DateTime> enviados = {};

  File? _archivo;
  Future<void> _escritura = Future.value();

  // ---------- Carga y guardado ----------

  Future<void> cargar() async {
    final nomina =
        jsonDecode(await rootBundle.loadString('assets/nomina.json'))
            as Map<String, dynamic>;
    institucion = (nomina['institucion'] ?? '') as String;
    periodo = (nomina['periodo'] ?? '') as String;
    configurarClave(nomina['clave'] as String);
    for (final e in (nomina['estudiantes'] as List)) {
      final est = Estudiante.fromJson(e as Map<String, dynamic>);
      estudiantes.add(est);
      _estudiantePorId[est.id] = est;
    }
    estudiantes.sort((a, b) => a.nombre.compareTo(b.nombre));
    final vistos = <String, Curso>{};
    for (final e in estudiantes) {
      vistos.putIfAbsent(
          e.claveCurso, () => Curso(e.grado, e.paralelo, e.jornada));
    }
    _cursos = vistos.values.toList()..sort(compararCursos);

    try {
      final d = jsonDecode(await rootBundle.loadString('assets/docentes.json'))
          as Map<String, dynamic>;
      final esc = (d['escuela'] ?? const <String, dynamic>{})
          as Map<String, dynamic>;
      escuelaDireccion = (esc['direccion'] ?? '') as String;
      escuelaTelefono = (esc['telefono'] ?? '') as String;
      escuelaCorreo = (esc['correo'] ?? '') as String;
      (d['docentes'] as Map<String, dynamic>).forEach((k, v) {
        final m = v as Map<String, dynamic>;
        _docentes[k] = Docente(m['nombre'] as String, m['celular'] as String);
      });
    } catch (_) {
      // Sin lista de docentes: el envío se hace escribiendo el número.
    }

    final dir = await getApplicationDocumentsDirectory();
    _archivo = File('${dir.path}/omega_access_v2.json');
    final archivo = _archivo!;
    if (await archivo.exists()) {
      try {
        final j =
            jsonDecode(await archivo.readAsString()) as Map<String, dynamic>;
        eventos.addAll((j['eventos'] as List)
            .map((e) => Evento.fromJson(e as Map<String, dynamic>)));
        (j['usos'] as Map<String, dynamic>).forEach((ev, mapa) {
          usos[ev] = (mapa as Map<String, dynamic>)
              .map((k, v) => MapEntry(k, DateTime.parse(v as String)));
        });
        (j['puertas'] as Map<String, dynamic>).forEach((ev, lista) {
          puertas[ev] = (lista as List).map((e) => e as String).toSet();
        });
        escaneos.addAll((j['escaneos'] as List)
            .map((e) => Escaneo.fromJson(e as Map<String, dynamic>)));
        extras.addAll(((j['extras'] ?? const []) as List)
            .map((e) => AccesoExtra.fromJson(e as Map<String, dynamic>)));
        nombreCelular = (j['celular'] ?? '') as String;
        ((j['contactos'] ?? const <String, dynamic>{}) as Map<String, dynamic>)
            .forEach((k, v) => contactos[k] = v as String);
        _precargaHecha = (j['precarga1'] ?? false) as bool;
        ((j['enviados'] ?? const <String, dynamic>{}) as Map<String, dynamic>)
            .forEach((k, v) => enviados[k] = DateTime.parse(v as String));
      } catch (_) {
        eventos.clear();
        usos.clear();
        puertas.clear();
        escaneos.clear();
        extras.clear();
        contactos.clear();
        _precargaHecha = false;
      }
    }
    if (!_precargaHecha) _precargarEventos();
  }

  /// Eventos iniciales de la escuela. Sus identificadores son fijos, así que
  /// todos los celulares tienen exactamente los mismos eventos y pases sin
  /// necesidad de pasarlos de un celular a otro.
  void _precargarEventos() {
    Set<String> cursosDe(String jornada, bool elemental) => {
          for (final c in _cursos)
            if (c.jornada == jornada &&
                (elemental ? c.grado <= 3 : (c.grado >= 4 && c.grado <= 7)))
              c.clave
        };
    final iniciales = [
      Evento(
        id: 'elemM26',
        nombre: 'Inauguración de deportes nivel elemental – matutina',
        lugar: '',
        fecha: DateTime(2026, 10, 28),
        pasesPorPersona: 2,
        cursos: cursosDe('M', true),
      ),
      Evento(
        id: 'elemV26',
        nombre: 'Inauguración de deportes nivel elemental – vespertina',
        lugar: '',
        fecha: DateTime(2026, 10, 28),
        pasesPorPersona: 2,
        cursos: cursosDe('V', true),
      ),
      Evento(
        id: 'basiM26',
        nombre: 'Inauguración de deportes nivel básico – matutina',
        lugar: '',
        fecha: DateTime(2026, 10, 29),
        pasesPorPersona: 2,
        cursos: cursosDe('M', false),
      ),
      Evento(
        id: 'basiV26',
        nombre: 'Inauguración de deportes nivel básico – vespertina',
        lugar: '',
        fecha: DateTime(2026, 10, 29),
        pasesPorPersona: 2,
        cursos: cursosDe('V', false),
      ),
    ];
    for (final ev in iniciales) {
      if (eventoPorId(ev.id) == null) eventos.add(ev);
    }
    _precargaHecha = true;
    _cambio();
  }

  void _cambio() {
    notifyListeners();
    final archivo = _archivo;
    if (archivo == null) return;
    if (escaneos.length > 20000) escaneos.removeRange(20000, escaneos.length);
    final contenido = jsonEncode({
      'eventos': eventos.map((e) => e.toJson()).toList(),
      'usos': usos.map((ev, m) =>
          MapEntry(ev, m.map((k, v) => MapEntry(k, v.toIso8601String())))),
      'puertas': puertas.map((ev, s) => MapEntry(ev, s.toList())),
      'escaneos': escaneos.map((e) => e.toJson()).toList(),
      'extras': extras.map((e) => e.toJson()).toList(),
      'celular': nombreCelular,
      'contactos': contactos,
      'precarga1': _precargaHecha,
      'enviados': enviados.map((k, v) => MapEntry(k, v.toIso8601String())),
    });
    _escritura = _escritura.then((_) => archivo.writeAsString(contenido));
  }

  // ---------- Consultas ----------

  List<Curso> get cursos => _cursos;

  Estudiante? estudiantePorId(String id) => _estudiantePorId[id];

  Evento? eventoPorId(String id) {
    for (final e in eventos) {
      if (e.id == id) return e;
    }
    return null;
  }

  Curso? cursoPorClave(String clave) {
    for (final c in _cursos) {
      if (c.clave == clave) return c;
    }
    return null;
  }

  List<Estudiante> estudiantesDeCurso(String claveCurso) =>
      estudiantes.where((e) => e.claveCurso == claveCurso).toList();

  List<Estudiante> participantes(Evento ev) =>
      estudiantes.where((e) => ev.cursos.contains(e.claveCurso)).toList();

  int contarParticipantes(Iterable<String> clavesCurso) {
    final set = clavesCurso.toSet();
    return estudiantes.where((e) => set.contains(e.claveCurso)).length;
  }

  List<Curso> cursosDeEvento(Evento ev) =>
      _cursos.where((c) => ev.cursos.contains(c.clave)).toList();

  List<Pase> pasesDe(Evento ev, Estudiante e) => List.generate(
        ev.pasesPorPersona,
        (k) => Pase(
          eventoId: ev.id,
          estudianteId: e.id,
          numero: k + 1,
          total: ev.pasesPorPersona,
        ),
      );

  int totalPases(Evento ev) =>
      participantes(ev).length * ev.pasesPorPersona +
      extrasDe(ev).fold(0, (s, x) => s + x.total);

  List<AccesoExtra> extrasDe(Evento ev) =>
      extras.where((x) => x.eventoId == ev.id).toList()
        ..sort((a, b) => b.creado.compareTo(a.creado));

  List<PaseExtra> pasesExtraDe(AccesoExtra a) =>
      [for (var k = 1; k <= a.total; k++) PaseExtra(a, k)];

  DateTime? usoDeExtra(PaseExtra p) => usos[p.acceso.eventoId]?[p.clave];

  int usadosEn(Evento ev) => usos[ev.id]?.length ?? 0;

  DateTime? usoDe(Pase p) => usos[p.eventoId]?[p.clave];

  int usadosDeCurso(Evento ev, String claveCurso) {
    final m = usos[ev.id];
    if (m == null) return 0;
    var n = 0;
    for (final clave in m.keys) {
      final est = _estudiantePorId[clave.split('.').first];
      if (est != null && est.claveCurso == claveCurso) n++;
    }
    return n;
  }

  Set<String> puertaDe(String eventoId) => puertas[eventoId] ?? <String>{};

  // ---------- Cambios ----------

  Evento crearEvento({
    required String nombre,
    required String lugar,
    required DateTime fecha,
  }) {
    final ev = Evento(
      id: nuevoId(6),
      nombre: nombre,
      lugar: lugar,
      fecha: fecha,
      pasesPorPersona: 2,
      cursos: <String>{},
    );
    eventos.add(ev);
    _cambio();
    return ev;
  }

  void guardarCursos(Evento ev, Set<String> cursos, int porPersona) {
    ev.cursos = {...cursos};
    ev.pasesPorPersona = porPersona;
    _cambio();
  }

  /// Agrega o actualiza un evento recibido desde otro celular.
  /// Devuelve true si es nuevo en este celular.
  bool importarEvento(Evento recibido) {
    final existente = eventoPorId(recibido.id);
    if (existente == null) {
      eventos.add(recibido);
      _cambio();
      return true;
    }
    existente
      ..nombre = recibido.nombre
      ..lugar = recibido.lugar
      ..fecha = recibido.fecha
      ..pasesPorPersona = recibido.pasesPorPersona
      ..cursos = recibido.cursos;
    _cambio();
    return false;
  }

  void eliminarEvento(String id) {
    eventos.removeWhere((e) => e.id == id);
    usos.remove(id);
    puertas.remove(id);
    escaneos.removeWhere((e) => e.eventoId == id);
    extras.removeWhere((x) => x.eventoId == id);
    _cambio();
  }

  void definirPuerta(String eventoId, Set<String> cursos) {
    if (cursos.isEmpty) {
      puertas.remove(eventoId);
    } else {
      puertas[eventoId] = {...cursos};
    }
    _cambio();
  }

  AccesoExtra crearExtra(Evento ev,
      {required String nombre, required String detalle, required int total}) {
    final a = AccesoExtra(
      id: nuevoId(6),
      eventoId: ev.id,
      nombre: nombre,
      detalle: detalle,
      total: total,
      creado: DateTime.now(),
    );
    extras.add(a);
    _cambio();
    return a;
  }

  void eliminarExtra(String id) {
    extras.removeWhere((x) => x.id == id);
    _cambio();
  }

  void definirNombreCelular(String nombre) {
    nombreCelular = nombre.trim();
    _cambio();
  }

  void guardarContacto(String grupo, String telefono) {
    contactos[grupo] = telefono;
    _cambio();
  }

  /// Docente de un paralelo: el contacto editado en este celular o, si no
  /// hay, el de la lista oficial.
  Docente? docenteDe(String claveCurso) {
    final propio = contactos[claveCurso];
    if (propio != null && propio.isNotEmpty) {
      final partes = propio.split('|');
      return Docente(partes.length > 1 ? partes[1] : '', partes.first);
    }
    return _docentes[claveCurso];
  }

  DateTime? enviadoA(Evento ev, String claveCurso) =>
      enviados['${ev.id}|$claveCurso'];

  void marcarEnviado(Evento ev, String claveCurso, {bool enviado = true}) {
    if (enviado) {
      enviados['${ev.id}|$claveCurso'] = DateTime.now();
    } else {
      enviados.remove('${ev.id}|$claveCurso');
    }
    _cambio();
  }

  // ---------- Autorización manual y reingresos ----------

  Escaneo _registrar(
    Evento ev,
    Veredicto v,
    String titulo,
    String? persona,
    String detalle, {
    String? estudianteId,
    String? curso,
    int? numero,
    String? clave,
  }) {
    final e = Escaneo(
      id: nuevoId(),
      eventoId: ev.id,
      fecha: DateTime.now(),
      veredicto: v,
      titulo: titulo,
      persona: persona,
      detalle: detalle,
      estudianteId: estudianteId,
      curso: curso,
      numero: numero,
      puerta: nombreCelular,
      clavePase: clave,
    );
    escaneos.insert(0, e);
    _cambio();
    return e;
  }

  DateTime? usoPorClave(Evento ev, String clave) => usos[ev.id]?[clave];

  /// Registra el ingreso de alguien que no presentó su QR, después de que el
  /// personal verificó de qué estudiante viene.
  Escaneo autorizarSinQr(
    Evento ev, {
    required String clave,
    required String persona,
    required String curso,
    required int numero,
    required int total,
    String? estudianteId,
  }) {
    usos.putIfAbsent(ev.id, () => {})[clave] = DateTime.now();
    return _registrar(ev, Veredicto.valido, 'Ingreso autorizado sin QR',
        persona, '$curso, pase $numero de $total. Verificado por el personal.',
        estudianteId: estudianteId, curso: curso, numero: numero, clave: clave);
  }

  /// Deja un pase usado disponible otra vez, para que su dueño pueda salir
  /// y volver a entrar con el mismo código.
  Escaneo habilitarDeNuevo(
    Evento ev, {
    required String clave,
    required String persona,
    required String curso,
    required int numero,
    required int total,
    String? estudianteId,
  }) {
    usos[ev.id]?.remove(clave);
    return _registrar(ev, Veredicto.habilitado, 'Pase habilitado de nuevo',
        persona, '$curso, pase $numero de $total. Puede volver a ingresar '
        'con el mismo código.',
        estudianteId: estudianteId, curso: curso, numero: numero, clave: clave);
  }

  /// Desde la pantalla roja de «Pase ya utilizado»: deja pasar otra vez.
  Escaneo autorizarReingreso(Evento ev, Escaneo rechazo) {
    final clave = rechazo.clavePase!;
    usos.putIfAbsent(ev.id, () => {})[clave] = DateTime.now();
    return _registrar(ev, Veredicto.valido, 'Reingreso autorizado',
        rechazo.persona, rechazo.detalle.replaceFirst(
            RegExp(r'^Ingresó a las \d\d:\d\d\. '), ''),
        estudianteId: rechazo.estudianteId,
        curso: rechazo.curso,
        numero: rechazo.numero,
        clave: clave);
  }

  void borrarDatosDelCelular() {
    enviados.clear();
    eventos.clear();
    usos.clear();
    puertas.clear();
    escaneos.clear();
    extras.clear();
    contactos.clear();
    _precargarEventos();
  }

  // ---------- Validación en la puerta ----------

  Escaneo validar(String texto, Evento evento) {
    Escaneo crear(
      Veredicto v,
      String titulo,
      String? persona,
      String detalle, {
      Estudiante? est,
      String? curso,
      int? n,
      String? clave,
    }) =>
        Escaneo(
          id: nuevoId(),
          eventoId: evento.id,
          fecha: DateTime.now(),
          veredicto: v,
          titulo: titulo,
          persona: persona,
          detalle: detalle,
          estudianteId: est?.id,
          curso: curso ?? est?.curso,
          numero: n,
          puerta: nombreCelular,
          clavePase: clave,
        );

    final r = pareceExtra(texto)
        ? _evaluarExtra(texto, evento, crear)
        : _evaluar(texto, evento, crear);
    escaneos.insert(0, r);
    _cambio();
    return r;
  }

  Escaneo _evaluarExtra(String texto, Evento evento, _Crear crear) {
    final l = leerExtra(texto);
    if (l == null) {
      return crear(Veredicto.rechazado, 'Pase no válido', null,
          'El código fue alterado o no lo emitió el sistema.');
    }
    if (l.eventoId != evento.id) {
      final otro = eventoPorId(l.eventoId);
      return crear(
        Veredicto.rechazado,
        'Pase de otro evento',
        l.nombre,
        otro != null
            ? 'Corresponde a: ${otro.nombre}.'
            : 'Corresponde a un evento que no está en este celular.',
      );
    }
    if (l.numero < 1 || l.numero > l.total) {
      return crear(Veredicto.rechazado, 'Pase no válido', l.nombre,
          'Número de pase fuera de rango.');
    }
    final detalle = [
      if (l.detalle.isNotEmpty) l.detalle,
      'acceso adicional ${l.numero} de ${l.total}.',
    ].join(', ');
    final clave = 'x${l.accesoId}.${l.numero}';
    final mapa = usos.putIfAbsent(evento.id, () => {});
    final previo = mapa[clave];
    if (previo != null) {
      return crear(Veredicto.rechazado, 'Pase ya utilizado', l.nombre,
          'Ingresó a las ${hora(previo)}. $detalle',
          curso: l.detalle, n: l.numero, clave: clave);
    }
    mapa[clave] = DateTime.now();
    return crear(Veredicto.valido, 'Acceso registrado', l.nombre, detalle,
        curso: l.detalle.isEmpty ? 'Acceso adicional' : l.detalle,
        n: l.numero,
        clave: clave);
  }

  Escaneo _evaluar(String texto, Evento evento, _Crear crear) {
    if (pareceEvento(texto)) {
      return crear(Veredicto.advertencia, 'Es un código de evento', null,
          'Este QR sirve para agregar el evento en otro celular, no para ingresar.');
    }
    final l = leerCodigo(texto);
    if (l.error == ErrorLectura.formato) {
      return crear(Veredicto.rechazado, 'Código no reconocido', null,
          'Este QR no pertenece a Omega Access Control.');
    }
    if (l.error == ErrorLectura.firma) {
      return crear(Veredicto.rechazado, 'Pase no válido', null,
          'El código fue alterado o no lo emitió el sistema.');
    }
    if (l.eventoId != evento.id) {
      final otro = eventoPorId(l.eventoId!);
      return crear(
        Veredicto.rechazado,
        'Pase de otro evento',
        null,
        otro != null
            ? 'Corresponde a: ${otro.nombre}.'
            : 'Corresponde a un evento que no está en este celular.',
      );
    }
    final est = estudiantePorId(l.estudianteId!);
    if (est == null) {
      return crear(
        Veredicto.advertencia,
        'Estudiante no encontrado',
        null,
        'El pase es auténtico, pero el estudiante no está en la nómina de '
            'este celular. Verifica la identidad.',
      );
    }
    final persona = 'Invitado de ${est.nombre}';
    final n = l.numero!;
    if (n < 1 || n > evento.pasesPorPersona) {
      return crear(Veredicto.rechazado, 'Pase no válido', persona,
          'El evento permite ${evento.pasesPorPersona} pases por estudiante.',
          est: est, n: n);
    }
    final descripcion = '${est.curso}, pase $n de ${evento.pasesPorPersona}.';
    if (!evento.cursos.contains(est.claveCurso)) {
      return crear(Veredicto.advertencia, 'Curso no participante', persona,
          '${est.curso} no está entre los cursos de este evento.',
          est: est, n: n);
    }
    final puerta = puertaDe(evento.id);
    if (puerta.isNotEmpty && !puerta.contains(est.claveCurso)) {
      return crear(Veredicto.advertencia, 'Corresponde a otra puerta', persona,
          '$descripcion Indica la puerta asignada a su curso.',
          est: est, n: n);
    }
    final clave = '${est.id}.$n';
    final mapa = usos.putIfAbsent(evento.id, () => {});
    final previo = mapa[clave];
    if (previo != null) {
      return crear(Veredicto.rechazado, 'Pase ya utilizado', persona,
          'Ingresó a las ${hora(previo)}. $descripcion',
          est: est, n: n, clave: clave);
    }
    mapa[clave] = DateTime.now();
    return crear(Veredicto.valido, 'Acceso registrado', persona, descripcion,
        est: est, n: n, clave: clave);
  }
}

typedef _Crear = Escaneo Function(
  Veredicto v,
  String titulo,
  String? persona,
  String detalle, {
  Estudiante? est,
  String? curso,
  int? n,
  String? clave,
});
