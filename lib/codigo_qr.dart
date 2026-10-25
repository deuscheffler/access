import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

import 'modelos.dart';

// La clave llega con la nómina (assets/nomina.json) y es distinta para cada
// institución. Todos los celulares con la misma app comparten la clave, por
// eso cualquiera puede validar cualquier pase sin conexión.
String _clave = '';

void configurarClave(String clave) => _clave = clave;

final Random _azar = Random.secure();

String nuevoId([int largo = 10]) {
  const caracteres = 'abcdefghijkmnpqrstuvwxyz23456789';
  return List.generate(
    largo,
    (_) => caracteres[_azar.nextInt(caracteres.length)],
  ).join();
}

String _firmar(String datos) {
  final hmac = Hmac(sha256, utf8.encode(_clave));
  return base64Url.encode(hmac.convert(utf8.encode(datos)).bytes).substring(0, 16);
}

// ---------------- Pases ----------------
// Formato: OAC2.<evento>.<estudiante>.<número>.<firma>

String codificarPase(Pase p) {
  final datos = '${p.eventoId}.${p.estudianteId}.${p.numero}';
  return 'OAC2.$datos.${_firmar(datos)}';
}

/// Pase real con la firma modificada, para demostrar el rechazo.
String codificarPaseAlterado(Pase p) {
  final datos = '${p.eventoId}.${p.estudianteId}.${p.numero}';
  final firma = _firmar(datos);
  final ultima = firma.endsWith('A') ? 'B' : 'A';
  return 'OAC2.$datos.${firma.substring(0, firma.length - 1)}$ultima';
}

enum ErrorLectura { formato, firma }

class Lectura {
  final String? eventoId;
  final String? estudianteId;
  final int? numero;
  final ErrorLectura? error;

  const Lectura.ok(this.eventoId, this.estudianteId, this.numero) : error = null;
  const Lectura.error(this.error)
      : eventoId = null,
        estudianteId = null,
        numero = null;
}

Lectura leerCodigo(String texto) {
  final partes = texto.trim().split('.');
  if (partes.length != 5 || partes[0] != 'OAC2') {
    return const Lectura.error(ErrorLectura.formato);
  }
  final numero = int.tryParse(partes[3]);
  if (numero == null) return const Lectura.error(ErrorLectura.formato);
  final datos = '${partes[1]}.${partes[2]}.${partes[3]}';
  if (_firmar(datos) != partes[4]) {
    return const Lectura.error(ErrorLectura.firma);
  }
  return Lectura.ok(partes[1], partes[2], numero);
}

// ---------------- Accesos adicionales ----------------
// Formato: OAC3.<evento>.<acceso>.<número>.<datos en base64>.<firma>
// Los datos (nombre, detalle, total) van dentro del código para que
// cualquier celular muestre a quién pertenece.

String codificarPaseExtra(PaseExtra p) {
  final a = p.acceso;
  final datos = base64Url.encode(utf8.encode(jsonEncode({
    'n': a.nombre,
    'd': a.detalle,
    't': a.total,
  })));
  final cuerpo = '${a.eventoId}.${a.id}.${p.numero}.$datos';
  return 'OAC3.$cuerpo.${_firmar(cuerpo)}';
}

class LecturaExtra {
  final String eventoId;
  final String accesoId;
  final int numero;
  final String nombre;
  final String detalle;
  final int total;

  const LecturaExtra({
    required this.eventoId,
    required this.accesoId,
    required this.numero,
    required this.nombre,
    required this.detalle,
    required this.total,
  });
}

bool pareceExtra(String texto) => texto.startsWith('OAC3.');

/// Devuelve null si el formato o la firma no son válidos.
LecturaExtra? leerExtra(String texto) {
  final partes = texto.trim().split('.');
  if (partes.length != 6 || partes[0] != 'OAC3') return null;
  final cuerpo = partes.sublist(1, 5).join('.');
  if (_firmar(cuerpo) != partes[5]) return null;
  final numero = int.tryParse(partes[3]);
  if (numero == null) return null;
  try {
    final j = jsonDecode(utf8.decode(base64Url.decode(partes[4])))
        as Map<String, dynamic>;
    return LecturaExtra(
      eventoId: partes[1],
      accesoId: partes[2],
      numero: numero,
      nombre: j['n'] as String,
      detalle: (j['d'] ?? '') as String,
      total: j['t'] as int,
    );
  } catch (_) {
    return null;
  }
}

// ---------------- Configuración de eventos ----------------
// Un celular muestra este QR y los demás lo escanean para tener el mismo
// evento. Formato: OACE1.<json en base64>.<firma>

String codificarEvento(Evento e) {
  final datos = base64Url.encode(utf8.encode(jsonEncode(e.toJson())));
  return 'OACE1.$datos.${_firmar(datos)}';
}

bool pareceEvento(String texto) => texto.startsWith('OACE1.');

Evento? leerEvento(String texto) {
  final partes = texto.trim().split('.');
  if (partes.length != 3 || partes[0] != 'OACE1') return null;
  if (_firmar(partes[1]) != partes[2]) return null;
  try {
    final j = jsonDecode(utf8.decode(base64Url.decode(partes[1])));
    return Evento.fromJson(j as Map<String, dynamic>);
  } catch (_) {
    return null;
  }
}
