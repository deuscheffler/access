import 'package:flutter/material.dart';

import '../almacen.dart';
import '../formato.dart';
import '../modelos.dart';
import '../tema.dart';
import 'informe.dart';

class PaginaRegistro extends StatelessWidget {
  const PaginaRegistro({super.key});

  @override
  Widget build(BuildContext context) {
    final a = Almacen.i;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registro de accesos'),
        actions: [
          IconButton(
            tooltip: 'Informe de un evento',
            icon: const Icon(Icons.summarize_outlined),
            onPressed: () => _elegirEvento(context),
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: a,
        builder: (context, _) {
          if (a.escaneos.isEmpty) {
            return const EstadoVacio(
              icono: Icons.fact_check_outlined,
              titulo: 'Aún no hay lecturas',
              texto: 'Cada código escaneado aparecerá aquí con su resultado, '
                  'la hora y el evento.',
            );
          }
          final validos =
              a.escaneos.where((e) => e.veredicto == Veredicto.valido).length;
          final rechazos = a.escaneos.length - validos;
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            itemCount: a.escaneos.length + 1,
            itemBuilder: (context, i) {
              if (i == 0) {
                return Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 12),
                  child: Text(
                    '$validos accesos registrados, $rechazos rechazados o por verificar',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Paleta.pizarra,
                    ),
                  ),
                );
              }
              final e = a.escaneos[i - 1];
              final ev = a.eventoPorId(e.eventoId);
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                clipBehavior: Clip.antiAlias,
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(width: 6, color: Paleta.deVeredicto(e.veredicto)),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      e.titulo,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 16,
                                        color: Paleta.tinta,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    hora(e.fecha),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: Paleta.pizarra,
                                    ),
                                  ),
                                ],
                              ),
                              if (e.persona != null)
                                Text(e.persona!,
                                    style: const TextStyle(fontSize: 15)),
                              Text(
                                e.detalle,
                                style: const TextStyle(
                                    fontSize: 14, color: Paleta.pizarra),
                              ),
                              if (ev != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    e.puerta.isEmpty
                                        ? ev.nombre
                                        : '${ev.nombre}, ${e.puerta}',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Paleta.pizarra,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _elegirEvento(BuildContext context) async {
    final a = Almacen.i;
    if (a.eventos.isEmpty) return;
    final elegido = await showModalBottomSheet<Evento>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Text(
                'Informe de qué evento',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                  color: Paleta.tinta,
                ),
              ),
            ),
            for (final ev in a.eventos)
              ListTile(
                title: Text(ev.nombre),
                subtitle: Text(
                    '${a.escaneos.where((e) => e.eventoId == ev.id).length} lecturas'),
                onTap: () => Navigator.of(ctx).pop(ev),
              ),
          ],
        ),
      ),
    );
    if (elegido != null && context.mounted) {
      await mostrarOpcionesInforme(context, elegido);
    }
  }
}
