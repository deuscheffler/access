// Modelos de la versión sin conexión.
//
// Los estudiantes vienen de la nómina que viaja dentro de la app, así que
// todos los celulares tienen exactamente los mismos datos. Los pases no se
// guardan: se calculan a partir de (evento, estudiante, número), por eso
// cualquier celular genera y valida los mismos códigos.

String nombreJornada(String j) => j == 'M' ? 'matutina' : 'vespertina';

/// Código de grado de la nómina: -2 Inicial 3 años, -1 Inicial 4 años,
/// 1 a 10 Educación Básica.
String nombreGrado(int g) => switch (g) {
      -2 => 'Inicial 3 años',
      -1 => 'Inicial 4 años',
      _ => '$g.º',
    };

class Estudiante {
  final String id;
  final String nombre;
  final int grado;
  final String paralelo;
  final String jornada; // 'M' o 'V'

  const Estudiante({
    required this.id,
    required this.nombre,
    required this.grado,
    required this.paralelo,
    required this.jornada,
  });

  String get claveCurso => '$grado$paralelo$jornada';
  String get curso => '${nombreGrado(grado)} $paralelo ${nombreJornada(jornada)}';

  factory Estudiante.fromJson(Map<String, dynamic> j) => Estudiante(
        id: j['id'] as String,
        nombre: j['n'] as String,
        grado: j['g'] as int,
        paralelo: j['p'] as String,
        jornada: j['j'] as String,
      );
}

class Curso {
  final int grado;
  final String paralelo;
  final String jornada;
  const Curso(this.grado, this.paralelo, this.jornada);

  String get clave => '$grado$paralelo$jornada';
  String get nombre => '${nombreGrado(grado)} $paralelo ${nombreJornada(jornada)}';
  String get nombreCorto => '${nombreGrado(grado)} $paralelo';
}

int compararCursos(Curso a, Curso b) {
  final j = a.jornada.compareTo(b.jornada); // M antes que V
  if (j != 0) return j;
  final g = a.grado.compareTo(b.grado);
  if (g != 0) return g;
  return a.paralelo.compareTo(b.paralelo);
}

class Evento {
  final String id;
  String nombre;
  String lugar;
  DateTime fecha;
  int pasesPorPersona;
  Set<String> cursos;

  Evento({
    required this.id,
    required this.nombre,
    required this.lugar,
    required this.fecha,
    required this.pasesPorPersona,
    required this.cursos,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'nombre': nombre,
        'lugar': lugar,
        'fecha': fecha.toIso8601String(),
        'n': pasesPorPersona,
        'c': cursos.toList()..sort(),
      };

  factory Evento.fromJson(Map<String, dynamic> j) => Evento(
        id: j['id'] as String,
        nombre: j['nombre'] as String,
        lugar: (j['lugar'] ?? '') as String,
        fecha: DateTime.parse(j['fecha'] as String),
        pasesPorPersona: (j['n'] ?? 2) as int,
        cursos: ((j['c'] ?? const []) as List).map((e) => e as String).toSet(),
      );
}

class Pase {
  final String eventoId;
  final String estudianteId;
  final int numero;
  final int total;

  const Pase({
    required this.eventoId,
    required this.estudianteId,
    required this.numero,
    required this.total,
  });

  /// Identifica el pase dentro de su evento.
  String get clave => '$estudianteId.$numero';
}

enum Veredicto { valido, rechazado, advertencia }

/// Acceso adicional: estudiante que no está en la nómina, invitado especial
/// o un pase extra para un estudiante. Sus datos viajan dentro del QR, así
/// que cualquier celular puede validarlo aunque solo exista en el celular que
/// lo creó.
class AccesoExtra {
  final String id;
  final String eventoId;
  final String nombre;
  final String detalle;
  final int total;
  final DateTime creado;

  const AccesoExtra({
    required this.id,
    required this.eventoId,
    required this.nombre,
    required this.detalle,
    required this.total,
    required this.creado,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'eventoId': eventoId,
        'nombre': nombre,
        'detalle': detalle,
        'total': total,
        'creado': creado.toIso8601String(),
      };

  factory AccesoExtra.fromJson(Map<String, dynamic> j) => AccesoExtra(
        id: j['id'] as String,
        eventoId: j['eventoId'] as String,
        nombre: j['nombre'] as String,
        detalle: (j['detalle'] ?? '') as String,
        total: j['total'] as int,
        creado: DateTime.parse(j['creado'] as String),
      );
}

/// Pase de un acceso adicional (número k de total).
class PaseExtra {
  final AccesoExtra acceso;
  final int numero;
  const PaseExtra(this.acceso, this.numero);

  String get clave => 'x${acceso.id}.$numero';
}

class Escaneo {
  final String id;
  final String eventoId;
  final DateTime fecha;
  final Veredicto veredicto;
  final String titulo;
  final String? persona;
  final String detalle;
  // Datos para informes
  final String? estudianteId;
  final String? curso;
  final int? numero;
  final String puerta;

  Escaneo({
    required this.id,
    required this.eventoId,
    required this.fecha,
    required this.veredicto,
    required this.titulo,
    required this.persona,
    required this.detalle,
    this.estudianteId,
    this.curso,
    this.numero,
    this.puerta = '',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'eventoId': eventoId,
        'fecha': fecha.toIso8601String(),
        'veredicto': veredicto.name,
        'titulo': titulo,
        'persona': persona,
        'detalle': detalle,
        'est': estudianteId,
        'curso': curso,
        'num': numero,
        'puerta': puerta,
      };

  factory Escaneo.fromJson(Map<String, dynamic> j) => Escaneo(
        id: j['id'] as String,
        eventoId: j['eventoId'] as String,
        fecha: DateTime.parse(j['fecha'] as String),
        veredicto: Veredicto.values.byName(j['veredicto'] as String),
        titulo: j['titulo'] as String,
        persona: j['persona'] as String?,
        detalle: j['detalle'] as String,
        estudianteId: j['est'] as String?,
        curso: j['curso'] as String?,
        numero: j['num'] as int?,
        puerta: (j['puerta'] ?? '') as String,
      );
}
