// Modelos de datos de la demo. En la versión con servidor, estas mismas
// entidades viven en PostgreSQL y el celular guarda una copia local.

class Evento {
  final String id;
  String nombre;
  String lugar;
  DateTime fecha;
  int pasesPorPersona;

  Evento({
    required this.id,
    required this.nombre,
    required this.lugar,
    required this.fecha,
    required this.pasesPorPersona,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'nombre': nombre,
        'lugar': lugar,
        'fecha': fecha.toIso8601String(),
        'pasesPorPersona': pasesPorPersona,
      };

  factory Evento.fromJson(Map<String, dynamic> j) => Evento(
        id: j['id'] as String,
        nombre: j['nombre'] as String,
        lugar: (j['lugar'] ?? '') as String,
        fecha: DateTime.parse(j['fecha'] as String),
        pasesPorPersona: (j['pasesPorPersona'] ?? 2) as int,
      );
}

class Estudiante {
  final String id;
  String nombres;
  String apellidos;
  String grado;
  String paralelo;

  Estudiante({
    required this.id,
    required this.nombres,
    required this.apellidos,
    required this.grado,
    required this.paralelo,
  });

  String get nombreCompleto => '$nombres $apellidos';
  String get curso => '$grado $paralelo';
  String get claveCurso => '$grado|$paralelo';

  Map<String, dynamic> toJson() => {
        'id': id,
        'nombres': nombres,
        'apellidos': apellidos,
        'grado': grado,
        'paralelo': paralelo,
      };

  factory Estudiante.fromJson(Map<String, dynamic> j) => Estudiante(
        id: j['id'] as String,
        nombres: j['nombres'] as String,
        apellidos: j['apellidos'] as String,
        grado: j['grado'] as String,
        paralelo: j['paralelo'] as String,
      );
}

class Curso {
  final String grado;
  final String paralelo;
  const Curso(this.grado, this.paralelo);

  String get clave => '$grado|$paralelo';
  String get nombre => '$grado $paralelo';
}

class Pase {
  final String id;
  final String eventoId;
  final String estudianteId;
  final int numero;
  final int total;
  DateTime? usadoEn;

  Pase({
    required this.id,
    required this.eventoId,
    required this.estudianteId,
    required this.numero,
    required this.total,
    this.usadoEn,
  });

  bool get usado => usadoEn != null;

  Map<String, dynamic> toJson() => {
        'id': id,
        'eventoId': eventoId,
        'estudianteId': estudianteId,
        'numero': numero,
        'total': total,
        'usadoEn': usadoEn?.toIso8601String(),
      };

  factory Pase.fromJson(Map<String, dynamic> j) => Pase(
        id: j['id'] as String,
        eventoId: j['eventoId'] as String,
        estudianteId: j['estudianteId'] as String,
        numero: j['numero'] as int,
        total: j['total'] as int,
        usadoEn: j['usadoEn'] == null
            ? null
            : DateTime.parse(j['usadoEn'] as String),
      );
}

enum Veredicto { valido, rechazado, advertencia }

class Escaneo {
  final String id;
  final String eventoId;
  final DateTime fecha;
  final Veredicto veredicto;
  final String titulo;
  final String? persona;
  final String detalle;

  Escaneo({
    required this.id,
    required this.eventoId,
    required this.fecha,
    required this.veredicto,
    required this.titulo,
    required this.persona,
    required this.detalle,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'eventoId': eventoId,
        'fecha': fecha.toIso8601String(),
        'veredicto': veredicto.name,
        'titulo': titulo,
        'persona': persona,
        'detalle': detalle,
      };

  factory Escaneo.fromJson(Map<String, dynamic> j) => Escaneo(
        id: j['id'] as String,
        eventoId: j['eventoId'] as String,
        fecha: DateTime.parse(j['fecha'] as String),
        veredicto: Veredicto.values.byName(j['veredicto'] as String),
        titulo: j['titulo'] as String,
        persona: j['persona'] as String?,
        detalle: j['detalle'] as String,
      );
}
