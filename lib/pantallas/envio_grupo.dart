import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../almacen.dart';
import '../modelos.dart';
import '../tema.dart';
import 'pdf_pases.dart';

/// Elige uno o varios cursos (por ejemplo, todo 5.º matutina), arma un solo
/// PDF y lo envía a la docente o al presidente del grupo, que se encarga de
/// reenviarlo a cada familia.
class PaginaEnvioGrupo extends StatefulWidget {
  final String eventoId;
  const PaginaEnvioGrupo({super.key, required this.eventoId});

  @override
  State<PaginaEnvioGrupo> createState() => _PaginaEnvioGrupoState();
}

class _PaginaEnvioGrupoState extends State<PaginaEnvioGrupo> {
  final Set<String> _sel = {};
  final _telefono = TextEditingController();
  final _nombre = TextEditingController();
  bool _trabajando = false;

  @override
  void dispose() {
    _telefono.dispose();
    _nombre.dispose();
    super.dispose();
  }

  String get _claveGrupo => (_sel.toList()..sort()).join(',');

  void _cambiarSeleccion(VoidCallback cambio) {
    setState(cambio);
    final guardado = Almacen.i.contactos[_claveGrupo];
    if (guardado != null && guardado.isNotEmpty) {
      final partes = guardado.split('|');
      _telefono.text = partes.first;
      _nombre.text = partes.length > 1 ? partes[1] : '';
    }
  }

  /// Convierte 0991234567 en 593991234567, el formato que usa WhatsApp.
  String? _numeroWhatsApp() {
    var d = _telefono.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (d.isEmpty) return null;
    if (d.startsWith('593')) return d.length >= 11 ? d : null;
    if (d.startsWith('0')) d = d.substring(1);
    return d.length == 9 ? '593$d' : null;
  }

  String _nombreGrupo(List<Curso> cursos) {
    if (cursos.length == 1) return cursos.first.nombre;
    final grados = cursos.map((c) => c.grado).toSet();
    final jornadas = cursos.map((c) => c.jornada).toSet();
    if (grados.length == 1 && jornadas.length == 1) {
      return '${nombreGrado(grados.first)} ${nombreJornada(jornadas.first)} '
          '(paralelos ${cursos.map((c) => c.paralelo).join(', ')})';
    }
    return '${cursos.length} cursos';
  }

  void _recordarContacto() {
    final t = _telefono.text.trim();
    if (t.isEmpty || _sel.isEmpty) return;
    Almacen.i.guardarContacto(_claveGrupo, '$t|${_nombre.text.trim()}');
  }

  Future<void> _abrirChat(Evento ev, List<Curso> cursos) async {
    final numero = _numeroWhatsApp();
    if (numero == null) {
      _aviso('Escribe un número de celular válido, por ejemplo 0991234567.');
      return;
    }
    _recordarContacto();
    final saludo =
        _nombre.text.trim().isEmpty ? 'Hola' : 'Hola, ${_nombre.text.trim()}';
    final texto = '$saludo. Le envío a continuación el PDF con los pases de '
        '${_nombreGrupo(cursos)} para «${ev.nombre}».';
    final ok = await launchUrl(
      Uri.parse('https://wa.me/$numero?text=${Uri.encodeComponent(texto)}'),
      mode: LaunchMode.externalApplication,
    );
    if (!ok) _aviso('No se pudo abrir WhatsApp.');
  }

  Future<void> _enviarPdf(Evento ev, List<Curso> cursos) async {
    setState(() => _trabajando = true);
    try {
      _recordarContacto();
      final grupo = _nombreGrupo(cursos);
      final archivo = await crearPdfDeCursos(ev, cursos, titulo: grupo);
      await Share.shareXFiles(
        [XFile(archivo.path, mimeType: 'application/pdf')],
        text: mensajePases(ev, grupo),
      );
    } catch (e) {
      _aviso('No se pudo crear el PDF: $e');
    } finally {
      if (mounted) setState(() => _trabajando = false);
    }
  }

  void _aviso(String texto) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texto)));
  }

  @override
  Widget build(BuildContext context) {
    final a = Almacen.i;
    final ev = a.eventoPorId(widget.eventoId);
    if (ev == null) return const Scaffold(body: SizedBox.shrink());

    final cursosEvento = a.cursosDeEvento(ev);
    final arbol = <String, Map<int, List<Curso>>>{};
    for (final c in cursosEvento) {
      arbol
          .putIfAbsent(c.jornada, () => {})
          .putIfAbsent(c.grado, () => [])
          .add(c);
    }
    final elegidos =
        cursosEvento.where((c) => _sel.contains(c.clave)).toList();
    final estudiantes = a.contarParticipantes(_sel);
    final pases = estudiantes * ev.pasesPorPersona;

    return Scaffold(
      appBar: AppBar(title: const Text('Enviar pases por grupo')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          Text(
            ev.nombre,
            style: const TextStyle(
              fontFamily: 'BarlowCondensed',
              fontWeight: FontWeight.w700,
              fontSize: 22,
              color: Paleta.tinta,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Elige los cursos del grupo. Se arma un solo PDF, con cada curso '
            'en hojas separadas, para enviarlo a la docente o al presidente.',
            style: TextStyle(color: Paleta.pizarra, height: 1.35),
          ),
          for (final j in arbol.entries) ...[
            const SizedBox(height: 18),
            Text(
              'Jornada ${nombreJornada(j.key)}',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: Paleta.tinta,
              ),
            ),
            const SizedBox(height: 8),
            for (final g in j.value.entries)
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            nombreGrado(g.key),
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                              color: Paleta.tinta,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () => _cambiarSeleccion(() {
                            final claves = g.value.map((c) => c.clave);
                            if (claves.every(_sel.contains)) {
                              _sel.removeAll(claves);
                            } else {
                              _sel.addAll(claves);
                            }
                          }),
                          child: const Text('Todo el grado'),
                        ),
                      ],
                    ),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final c in g.value)
                          FilterChip(
                            label: Text('Paralelo ${c.paralelo}'),
                            selected: _sel.contains(c.clave),
                            selectedColor: Paleta.celeste,
                            checkmarkColor: Paleta.tinta,
                            onSelected: (v) => _cambiarSeleccion(() {
                              if (v) {
                                _sel.add(c.clave);
                              } else {
                                _sel.remove(c.clave);
                              }
                            }),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
          ],
          const SizedBox(height: 18),
          const Text(
            'Destinatario',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: Paleta.tinta,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _nombre,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Nombre de la docente o presidente (opcional)',
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _telefono,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Celular con WhatsApp',
              hintText: '0991234567',
              prefixIcon: Icon(Icons.phone_outlined),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'WhatsApp no permite que otra app adjunte un archivo directamente a '
            'un número. Por eso son dos pasos: abre el chat con la docente y '
            'luego envía el PDF eligiendo ese chat en WhatsApp.',
            style: TextStyle(fontSize: 13, height: 1.35, color: Paleta.pizarra),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (elegidos.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    '${_nombreGrupo(elegidos)}: $estudiantes estudiantes, '
                    '$pases pases',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, color: Paleta.tinta),
                  ),
                ),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: elegidos.isEmpty
                          ? null
                          : () => _abrirChat(ev, elegidos),
                      icon: const Icon(Icons.chat_outlined),
                      label: const Text('1. Abrir chat'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.icon(
                      style:
                          FilledButton.styleFrom(backgroundColor: Paleta.paso),
                      onPressed: elegidos.isEmpty || _trabajando
                          ? null
                          : () => _enviarPdf(ev, elegidos),
                      icon: _trabajando
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.picture_as_pdf_outlined),
                      label: Text(_trabajando ? 'Creando' : '2. Enviar PDF'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
