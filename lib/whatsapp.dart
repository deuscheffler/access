import 'dart:io';

import 'package:flutter/services.dart';

/// Abre WhatsApp directamente en el chat de un número con las imágenes ya
/// adjuntas. La persona solo toca «Enviar» en WhatsApp: ninguna app puede
/// enviar mensajes por su cuenta sin la API de pago de WhatsApp Business.
///
/// Usa código nativo de Android (MainActivity.kt, que agrega
/// tool/configurar_android.sh). Si algo falla, devuelve false y la app
/// recurre al menú normal de compartir.
class WhatsAppDirecto {
  static const _canal = MethodChannel('omega/whatsapp');
  static const _paquetes = ['com.whatsapp', 'com.whatsapp.w4b'];

  static Future<String?> _paquete() async {
    for (final p in _paquetes) {
      try {
        final ok = await _canal.invokeMethod<bool>('instalado', {'paquete': p});
        if (ok == true) return p;
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  static Future<bool> disponible() async => (await _paquete()) != null;

  /// [numero] en formato internacional sin «+», por ejemplo 593991234567.
  static Future<bool> enviar({
    required String numero,
    required List<File> archivos,
    required String texto,
  }) async {
    final paquete = await _paquete();
    if (paquete == null || archivos.isEmpty) return false;
    try {
      await _canal.invokeMethod<bool>('enviar', {
        'numero': numero,
        'archivos': [for (final f in archivos) f.path],
        'texto': texto,
        'paquete': paquete,
      });
      return true;
    } catch (_) {
      return false;
    }
  }
}
