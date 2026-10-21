import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../almacen.dart';
import '../codigo_qr.dart';
import '../modelos.dart';
import '../tema.dart';

class PaginaEscaner extends StatefulWidget {
  final String eventoId;
  const PaginaEscaner({super.key, required this.eventoId});

  @override
  State<PaginaEscaner> createState() => _PaginaEscanerState();
}

class _PaginaEscanerState extends State<PaginaEscaner> {
  final MobileScannerController _camara = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    formats: const [BarcodeFormat.qrCode],
  );

  Escaneo? _resultado;
  String? _ultimoCodigo;
  DateTime _ultimaVez = DateTime(2000);
  Timer? _temporizador;
  bool _linterna = false;

  @override
  void dispose() {
    _temporizador?.cancel();
    _camara.dispose();
    super.dispose();
  }

  void _alDetectar(BarcodeCapture captura) {
    if (_resultado != null || captura.barcodes.isEmpty) return;
    final valor = captura.barcodes.first.rawValue;
    if (valor == null || valor.isEmpty) return;
    final ahora = DateTime.now();
    // Evita leer el mismo QR varias veces seguidas mientras sigue frente
    // a la cámara.
    if (valor == _ultimoCodigo &&
        ahora.difference(_ultimaVez) < const Duration(seconds: 3)) {
      return;
    }
    _ultimoCodigo = valor;
    _ultimaVez = ahora;
    _procesar(valor);
  }

  void _procesar(String valor) {
    final evento = Almacen.i.eventoPorId(widget.eventoId);
    if (evento == null) return;
    final r = Almacen.i.validar(valor, evento);
    if (r.veredicto == Veredicto.valido) {
      HapticFeedback.mediumImpact();
    } else {
      HapticFeedback.heavyImpact();
    }
    setState(() => _resultado = r);
    _temporizador?.cancel();
    _temporizador = Timer(
      r.veredicto == Veredicto.valido
          ? const Duration(milliseconds: 1800)
          : const Duration(seconds: 4),
      _cerrarResultado,
    );
  }

  void _cerrarResultado() {
    _temporizador?.cancel();
    if (!mounted) return;
    _ultimaVez = DateTime.now();
    setState(() => _resultado = null);
  }

  Future<void> _simular() async {
    final evento = Almacen.i.eventoPorId(widget.eventoId);
    if (evento == null) return;
    final pases = Almacen.i.pasesDeEvento(evento.id);
    final codigo = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => _HojaSimulacion(pases: pases),
    );
    if (codigo != null && mounted) _procesar(codigo);
  }

  @override
  Widget build(BuildContext context) {
    final a = Almacen.i;
    final evento = a.eventoPorId(widget.eventoId);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(evento?.nombre ?? 'Escáner'),
        actions: [
          IconButton(
            tooltip: 'Linterna',
            icon: Icon(_linterna ? Icons.flash_on : Icons.flash_off),
            onPressed: () {
              _camara.toggleTorch();
              setState(() => _linterna = !_linterna);
            },
          ),
          IconButton(
            tooltip: 'Simular lectura',
            icon: const Icon(Icons.touch_app_outlined),
            onPressed: _simular,
          ),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: MobileScanner(
              controller: _camara,
              onDetect: _alDetectar,
            ),
          ),
          // Marco de lectura
          Center(
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 3),
                borderRadius: BorderRadius.circular(28),
              ),
            ),
          ),
          // Contador inferior
          Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: ListenableBuilder(
              listenable: a,
              builder: (context, _) {
                final pases = a.pasesDeEvento(widget.eventoId);
                final usados = pases.where((p) => p.usado).length;
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  decoration: BoxDecoration(
                    color: Paleta.tinta.withOpacity(0.92),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Text(
                        '$usados',
                        style: const TextStyle(
                          fontFamily: 'BarlowCondensed',
                          fontWeight: FontWeight.w800,
                          fontSize: 34,
                          height: 1.0,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'de ${pases.length} ingresaron\n'
                          'Apunta la cámara al código QR',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          if (_resultado != null)
            Positioned.fill(
              child: _PantallaVeredicto(
                escaneo: _resultado!,
                alTocar: _cerrarResultado,
              ),
            ),
        ],
      ),
    );
  }
}

/// El momento más importante de la app: el operador debe entender el
/// resultado en medio segundo, a un metro de distancia y a pleno sol.
class _PantallaVeredicto extends StatelessWidget {
  final Escaneo escaneo;
  final VoidCallback alTocar;

  const _PantallaVeredicto({required this.escaneo, required this.alTocar});

  @override
  Widget build(BuildContext context) {
    final color = Paleta.deVeredicto(escaneo.veredicto);
    final palabra = switch (escaneo.veredicto) {
      Veredicto.valido => 'Adelante',
      Veredicto.rechazado => 'Alto',
      Veredicto.advertencia => 'Verificar',
    };
    final icono = switch (escaneo.veredicto) {
      Veredicto.valido => Icons.check_rounded,
      Veredicto.rechazado => Icons.close_rounded,
      Veredicto.advertencia => Icons.priority_high_rounded,
    };

    return GestureDetector(
      onTap: alTocar,
      child: Container(
        color: color,
        padding: const EdgeInsets.fromLTRB(28, 40, 28, 40),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icono, color: Colors.white, size: 96),
              const Spacer(),
              Text(
                palabra,
                style: const TextStyle(
                  fontFamily: 'BarlowCondensed',
                  fontWeight: FontWeight.w800,
                  fontSize: 96,
                  height: 0.95,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                escaneo.titulo,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 26,
                  color: Colors.white,
                ),
              ),
              if (escaneo.persona != null) ...[
                const SizedBox(height: 16),
                Text(
                  escaneo.persona!,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 22,
                    color: Colors.white,
                  ),
                ),
              ],
              const SizedBox(height: 6),
              Text(
                escaneo.detalle,
                style: const TextStyle(fontSize: 19, color: Colors.white),
              ),
              const Spacer(),
              const Text(
                'Toca la pantalla para seguir escaneando',
                style: TextStyle(fontSize: 15, color: Colors.white70),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Permite probar el flujo con un solo celular, sin otra pantalla que
/// muestre el QR.
class _HojaSimulacion extends StatelessWidget {
  final List<Pase> pases;
  const _HojaSimulacion({required this.pases});

  @override
  Widget build(BuildContext context) {
    final a = Almacen.i;
    final muestra = pases.take(60).toList();
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        child: ListView(
          shrinkWrap: true,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Text(
                'Simular lectura',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Paleta.tinta,
                ),
              ),
            ),
            if (muestra.isNotEmpty)
              ListTile(
                leading: const Icon(Icons.gpp_bad_outlined, color: Paleta.alto),
                title: const Text('Probar un QR alterado'),
                subtitle: const Text('Un pase real con la firma modificada'),
                onTap: () => Navigator.of(context)
                    .pop(codificarPaseAlterado(muestra.first)),
              ),
            ListTile(
              leading:
                  const Icon(Icons.help_outline, color: Paleta.pizarra),
              title: const Text('Probar un QR ajeno'),
              subtitle: const Text('Un código que no es de Omega'),
              onTap: () =>
                  Navigator.of(context).pop('https://ejemplo.com/entrada/123'),
            ),
            const Divider(),
            for (final p in muestra)
              ListTile(
                leading: Icon(
                  p.usado ? Icons.check_circle : Icons.qr_code_2,
                  color: p.usado ? Paleta.paso : Paleta.tinta,
                ),
                title: Text(
                    a.estudiantePorId(p.estudianteId)?.nombreCompleto ?? 'Pase'),
                subtitle: Text(
                  '${a.estudiantePorId(p.estudianteId)?.curso ?? ''}, '
                  'pase ${p.numero} de ${p.total}'
                  '${p.usado ? ', ya usado' : ''}',
                ),
                onTap: () => Navigator.of(context).pop(codificarPase(p)),
              ),
          ],
        ),
      ),
    );
  }
}
