import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../almacen.dart';
import '../codigo_qr.dart';
import '../formato.dart';
import '../tema.dart';
import 'eventos.dart';

/// Muestra el código de configuración del evento. Los demás celulares lo
/// escanean y quedan con el mismo evento, los mismos cursos y los mismos
/// pases, sin internet.
class PaginaCompartirEvento extends StatelessWidget {
  final String eventoId;
  const PaginaCompartirEvento({super.key, required this.eventoId});

  @override
  Widget build(BuildContext context) {
    final a = Almacen.i;
    final ev = a.eventoPorId(eventoId);
    if (ev == null) return const Scaffold(body: SizedBox.shrink());

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text('Pasar a otro celular')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
          children: [
            Text(
              ev.nombre,
              style: const TextStyle(
                fontFamily: 'BarlowCondensed',
                fontWeight: FontWeight.w800,
                fontSize: 30,
                height: 1.05,
                color: Paleta.tinta,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${fechaLarga(ev.fecha)}. ${ev.cursos.length} cursos, '
              '${ev.pasesPorPersona} pases por estudiante.',
              style: const TextStyle(fontSize: 15, color: Paleta.pizarra),
            ),
            const SizedBox(height: 24),
            Center(
              child: QrImageView(
                data: codificarEvento(ev),
                version: QrVersions.auto,
                size: 300,
                backgroundColor: Colors.white,
                eyeStyle: const QrEyeStyle(
                  eyeShape: QrEyeShape.square,
                  color: Paleta.tinta,
                ),
                dataModuleStyle: const QrDataModuleStyle(
                  dataModuleShape: QrDataModuleShape.square,
                  color: Paleta.tinta,
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'En el otro celular abre Omega Access, toca el ícono de '
              'escanear en la pantalla de eventos y apunta a este código.',
              style: TextStyle(fontSize: 16, height: 1.4, color: Paleta.tinta),
            ),
            const SizedBox(height: 12),
            const Text(
              'Si cambias los cursos o los pases por estudiante, vuelve a '
              'mostrar este código en los demás celulares para actualizarlos.',
              style: TextStyle(fontSize: 14, height: 1.4, color: Paleta.pizarra),
            ),
          ],
        ),
      ),
    );
  }
}

/// Escanea el código de configuración que muestra otro celular.
class PaginaAgregarEvento extends StatefulWidget {
  const PaginaAgregarEvento({super.key});

  @override
  State<PaginaAgregarEvento> createState() => _PaginaAgregarEventoState();
}

class _PaginaAgregarEventoState extends State<PaginaAgregarEvento> {
  final MobileScannerController _camara = MobileScannerController(
    formats: const [BarcodeFormat.qrCode],
  );
  bool _listo = false;
  String? _aviso;

  @override
  void dispose() {
    _camara.dispose();
    super.dispose();
  }

  void _alDetectar(BarcodeCapture captura) {
    if (_listo || captura.barcodes.isEmpty) return;
    final valor = captura.barcodes.first.rawValue ?? '';
    if (!pareceEvento(valor)) {
      setState(() => _aviso = 'Ese código es un pase u otro QR. Apunta al '
          'código que muestra «Pasar este evento a otro celular».');
      return;
    }
    final ev = leerEvento(valor);
    if (ev == null) {
      setState(() => _aviso = 'El código no es válido para esta institución.');
      return;
    }
    _listo = true;
    final nuevo = Almacen.i.importarEvento(ev);
    final nav = Navigator.of(context);
    final mensajero = ScaffoldMessenger.of(context);
    nav.pop();
    nav.push(MaterialPageRoute<void>(
      builder: (_) => DetalleEvento(eventoId: ev.id),
    ));
    mensajero.showSnackBar(SnackBar(
      content: Text(nuevo
          ? 'Evento agregado: ${ev.nombre}.'
          : 'Evento actualizado: ${ev.nombre}.'),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Agregar evento'),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: MobileScanner(controller: _camara, onDetect: _alDetectar),
          ),
          Center(
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 3),
                borderRadius: BorderRadius.circular(28),
              ),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _aviso == null
                    ? Paleta.tinta.withOpacity(0.92)
                    : Paleta.atencion,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                _aviso ??
                    'Apunta al código que muestra el otro celular en '
                        '«Pasar este evento a otro celular».',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  height: 1.35,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
