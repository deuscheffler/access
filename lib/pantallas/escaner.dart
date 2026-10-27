import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import 'autorizar.dart';

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

  void _reingreso() {
    final evento = Almacen.i.eventoPorId(widget.eventoId);
    final previo = _resultado;
    if (evento == null || previo == null || previo.clavePase == null) return;
    final r = Almacen.i.autorizarReingreso(evento, previo);
    HapticFeedback.mediumImpact();
    setState(() => _resultado = r);
    _temporizador?.cancel();
    _temporizador =
        Timer(const Duration(milliseconds: 1800), _cerrarResultado);
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
    final codigo = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => _HojaSimulacion(evento: evento),
    );
    if (codigo != null && mounted) _procesar(codigo);
  }

  Future<void> _elegirPuerta() async {
    final evento = Almacen.i.eventoPorId(widget.eventoId);
    if (evento == null) return;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) => _HojaPuerta(evento: evento),
    );
    if (mounted) setState(() {});
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
            tooltip: 'Autorizar sin QR',
            icon: const Icon(Icons.person_search_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => PaginaAutorizar(eventoId: widget.eventoId),
              ),
            ),
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
          // Cursos que atiende esta puerta
          Positioned(
            left: 16,
            right: 16,
            top: 12,
            child: ListenableBuilder(
              listenable: a,
              builder: (context, _) {
                final puerta = a.puertaDe(widget.eventoId);
                return Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: _elegirPuerta,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          const Icon(Icons.door_front_door_outlined,
                              color: Paleta.tinta),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              '${a.nombreCelular.isEmpty ? 'Esta puerta' : a.nombreCelular}: '
                              '${puerta.isEmpty ? 'todos los cursos' : '${puerta.length} curso${puerta.length == 1 ? '' : 's'}'}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                                color: Paleta.tinta,
                              ),
                            ),
                          ),
                          const Text('Cambiar',
                              style: TextStyle(
                                  color: Paleta.pizarra,
                                  fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                  ),
                );
              },
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
                final ev = a.eventoPorId(widget.eventoId);
                final usados = ev == null ? 0 : a.usadosEn(ev);
                final total = ev == null ? 0 : a.totalPases(ev);
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
                          'de $total ingresaron por este celular\n'
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
                alReingreso: _resultado!.titulo == 'Pase ya utilizado' &&
                        _resultado!.clavePase != null
                    ? _reingreso
                    : null,
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
  final VoidCallback? alReingreso;

  const _PantallaVeredicto({
    required this.escaneo,
    required this.alTocar,
    this.alReingreso,
  });

  @override
  Widget build(BuildContext context) {
    final color = Paleta.deVeredicto(escaneo.veredicto);
    final palabra = switch (escaneo.veredicto) {
      Veredicto.valido => 'Adelante',
      Veredicto.rechazado => 'Alto',
      Veredicto.advertencia => 'Verificar',
      Veredicto.habilitado => 'Habilitado',
    };
    final icono = switch (escaneo.veredicto) {
      Veredicto.valido => Icons.check_rounded,
      Veredicto.rechazado => Icons.close_rounded,
      Veredicto.advertencia => Icons.priority_high_rounded,
      Veredicto.habilitado => Icons.replay_rounded,
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
              _UnaLinea(
                palabra,
                const TextStyle(
                  fontFamily: 'BarlowCondensed',
                  fontWeight: FontWeight.w800,
                  fontSize: 96,
                  height: 0.95,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              _UnaLinea(
                escaneo.titulo,
                const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 26,
                  color: Colors.white,
                ),
              ),
              if (escaneo.persona != null) ...[
                const SizedBox(height: 16),
                _UnaLinea(
                  escaneo.persona!,
                  const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 22,
                    color: Colors.white,
                  ),
                ),
              ],
              const SizedBox(height: 6),
              Text(
                escaneo.detalle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 19, color: Colors.white),
              ),
              const Spacer(),
              if (alReingreso != null) ...[
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Paleta.alto,
                      minimumSize: const Size(64, 56),
                    ),
                    onPressed: alReingreso,
                    icon: const Icon(Icons.login),
                    label: const FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        'Salió y vuelve: permitir reingreso',
                        maxLines: 1,
                        softWrap: false,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              const _UnaLinea(
                'Toca la pantalla para seguir escaneando',
                TextStyle(fontSize: 15, color: Colors.white70),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Texto que siempre ocupa una sola línea: si no cabe en el ancho del
/// celular, se reduce de tamaño en lugar de pasar a una segunda línea.
class _UnaLinea extends StatelessWidget {
  final String texto;
  final TextStyle estilo;
  const _UnaLinea(this.texto, this.estilo);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Text(texto, maxLines: 1, softWrap: false, style: estilo),
      ),
    );
  }
}

/// Permite probar el flujo con un solo celular, sin otra pantalla que
/// muestre el QR.
class _HojaSimulacion extends StatelessWidget {
  final Evento evento;
  const _HojaSimulacion({required this.evento});

  @override
  Widget build(BuildContext context) {
    final a = Almacen.i;
    final muestra = <(Estudiante, Pase)>[];
    for (final e in a.participantes(evento).take(25)) {
      for (final p in a.pasesDe(evento, e)) {
        muestra.add((e, p));
      }
    }
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
                    .pop(codificarPaseAlterado(muestra.first.$2)),
              ),
            ListTile(
              leading: const Icon(Icons.help_outline, color: Paleta.pizarra),
              title: const Text('Probar un QR ajeno'),
              subtitle: const Text('Un código que no es de Omega'),
              onTap: () =>
                  Navigator.of(context).pop('https://ejemplo.com/entrada/123'),
            ),
            const Divider(),
            for (final (e, p) in muestra)
              ListTile(
                leading: Icon(
                  a.usoDe(p) != null ? Icons.check_circle : Icons.qr_code_2,
                  color: a.usoDe(p) != null ? Paleta.paso : Paleta.tinta,
                ),
                title: Text(e.nombre),
                subtitle: Text(
                  '${e.curso}, pase ${p.numero} de ${p.total}'
                  '${a.usoDe(p) != null ? ', ya usado' : ''}',
                ),
                onTap: () => Navigator.of(context).pop(codificarPase(p)),
              ),
          ],
        ),
      ),
    );
  }
}

/// Define qué cursos atiende la puerta de este celular. Si cada puerta
/// recibe cursos distintos, un pase copiado no puede entrar dos veces por
/// puertas diferentes, aunque los celulares no estén conectados entre sí.
class _HojaPuerta extends StatefulWidget {
  final Evento evento;
  const _HojaPuerta({required this.evento});

  @override
  State<_HojaPuerta> createState() => _HojaPuertaState();
}

class _HojaPuertaState extends State<_HojaPuerta> {
  late Set<String> _sel;
  late final TextEditingController _nombre;

  @override
  void initState() {
    super.initState();
    _sel = {...Almacen.i.puertaDe(widget.evento.id)};
    _nombre = TextEditingController(text: Almacen.i.nombreCelular);
  }

  @override
  void dispose() {
    _nombre.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final a = Almacen.i;
    final cursos = a.cursosDeEvento(widget.evento);
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: TextField(
                controller: _nombre,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Nombre de esta puerta o celular',
                  hintText: 'Ej.: Puerta principal',
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, 4),
              child: Text(
                'Cursos de esta puerta',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Paleta.tinta,
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Text(
                'Si no marcas ninguno, esta puerta recibe todos los cursos.',
                style: TextStyle(color: Paleta.pizarra),
              ),
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final c in cursos)
                    CheckboxListTile(
                      value: _sel.contains(c.clave),
                      controlAffinity: ListTileControlAffinity.leading,
                      title: Text(c.nombre),
                      onChanged: (v) => setState(() {
                        if (v == true) {
                          _sel.add(c.clave);
                        } else {
                          _sel.remove(c.clave);
                        }
                      }),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: FilledButton(
                onPressed: () {
                  a.definirNombreCelular(_nombre.text);
                  a.definirPuerta(widget.evento.id, _sel);
                  Navigator.of(context).pop();
                },
                child: Text(_sel.isEmpty
                    ? 'Recibir todos los cursos'
                    : 'Recibir ${_sel.length} curso${_sel.length == 1 ? '' : 's'}'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
