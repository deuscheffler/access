import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

import 'modelos.dart';

// DEMO: la clave vive dentro de la app y se firma con HMAC-SHA256.
// En producción el servidor firma con Ed25519 (clave privada) y la app solo
// guarda la clave pública, de modo que nadie pueda fabricar pases.
const String _claveDemo = 'omega-access-demo-local-2026';
const String _prefijo = 'OAC1';

final Random _azar = Random.secure();

String nuevoId([int largo = 10]) {
  const caracteres = 'abcdefghijkmnpqrstuvwxyz23456789';
  return List.generate(
    largo,
    (_) => caracteres[_azar.nextInt(caracteres.length)],
  ).join();
}

String _firmar(String eventoId, String paseId) {
  final hmac = Hmac(sha256, utf8.encode(_claveDemo));
  final digest = hmac.convert(utf8.encode('$eventoId.$paseId'));
  return base64Url.encode(digest.bytes).substring(0, 16);
}

/// Texto que va dentro del QR: OAC1.<evento>.<pase>.<firma>
String codificarPase(Pase pase) =>
    '$_prefijo.${pase.eventoId}.${pase.id}.${_firmar(pase.eventoId, pase.id)}';

/// Versión alterada de un pase real, para demostrar el rechazo.
String codificarPaseAlterado(Pase pase) {
  final firma = _firmar(pase.eventoId, pase.id);
  final ultima = firma.substring(firma.length - 1) == 'A' ? 'B' : 'A';
  return '$_prefijo.${pase.eventoId}.${pase.id}.'
      '${firma.substring(0, firma.length - 1)}$ultima';
}

enum ErrorLectura { formato, firma }

class Lectura {
  final String? eventoId;
  final String? paseId;
  final ErrorLectura? error;

  const Lectura.ok(this.eventoId, this.paseId) : error = null;
  const Lectura.error(this.error)
      : eventoId = null,
        paseId = null;
}

Lectura leerCodigo(String texto) {
  final partes = texto.trim().split('.');
  if (partes.length != 4 || partes[0] != _prefijo) {
    return const Lectura.error(ErrorLectura.formato);
  }
  final eventoId = partes[1];
  final paseId = partes[2];
  if (_firmar(eventoId, paseId) != partes[3]) {
    return const Lectura.error(ErrorLectura.firma);
  }
  return Lectura.ok(eventoId, paseId);
}
