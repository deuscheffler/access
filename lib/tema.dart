import 'package:flutter/material.dart';

import 'modelos.dart';

/// Paleta: tinta andina como base institucional; los tres colores de
/// veredicto son fijos para todos los clientes porque el operador debe
/// reconocerlos de un vistazo, incluso a pleno sol.
class Paleta {
  static const tinta = Color(0xFF14284B);
  static const tintaSuave = Color(0xFF243B63);
  static const niebla = Color(0xFFEEF2F5);
  static const pizarra = Color(0xFF4A5868);
  static const linea = Color(0xFFD5DCE3);
  static const paso = Color(0xFF109B4E);
  static const alto = Color(0xFFD12F2F);
  static const atencion = Color(0xFFE39B12);

  static Color deVeredicto(Veredicto v) => switch (v) {
        Veredicto.valido => paso,
        Veredicto.rechazado => alto,
        Veredicto.advertencia => atencion,
      };
}

ThemeData temaOmega() {
  final esquema = ColorScheme.fromSeed(
    seedColor: Paleta.tinta,
    primary: Paleta.tinta,
    surface: Colors.white,
  );
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: esquema,
    fontFamily: 'Barlow',
    scaffoldBackgroundColor: Paleta.niebla,
  );
  return base.copyWith(
    appBarTheme: const AppBarTheme(
      backgroundColor: Paleta.tinta,
      foregroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: TextStyle(
        fontFamily: 'Barlow',
        fontWeight: FontWeight.w600,
        fontSize: 20,
        color: Colors.white,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: Paleta.tinta,
        foregroundColor: Colors.white,
        minimumSize: const Size(64, 52),
        textStyle: const TextStyle(
          fontFamily: 'Barlow',
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: Paleta.tinta,
        minimumSize: const Size(64, 52),
        side: const BorderSide(color: Paleta.linea, width: 1.5),
        textStyle: const TextStyle(
          fontFamily: 'Barlow',
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Paleta.linea),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Paleta.linea),
      ),
    ),
    dividerColor: Paleta.linea,
  );
}

/// Logo: la omega funciona como un arco de acceso y la línea verde es el
/// umbral. Cada cliente podrá reemplazarlo por su propio logo.
class LogoOmega extends StatelessWidget {
  final double tamano;
  final bool sobreOscuro;

  const LogoOmega({super.key, this.tamano = 32, this.sobreOscuro = false});

  @override
  Widget build(BuildContext context) {
    final fondo = sobreOscuro ? Colors.white : Paleta.tinta;
    final trazo = sobreOscuro ? Paleta.tinta : Colors.white;
    return Container(
      width: tamano,
      height: tamano,
      decoration: BoxDecoration(
        color: fondo,
        borderRadius: BorderRadius.circular(tamano * 0.22),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            top: tamano * 0.12,
            child: Text(
              'Ω',
              style: TextStyle(
                fontFamily: 'Barlow',
                fontWeight: FontWeight.w700,
                fontSize: tamano * 0.6,
                height: 1.0,
                color: trazo,
              ),
            ),
          ),
          Positioned(
            bottom: tamano * 0.14,
            child: Container(
              width: tamano * 0.4,
              height: tamano * 0.06,
              decoration: BoxDecoration(
                color: Paleta.paso,
                borderRadius: BorderRadius.circular(tamano * 0.03),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Estado vacío: dice qué hacer, no cómo sentirse.
class EstadoVacio extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final String texto;
  final Widget? accion;

  const EstadoVacio({
    super.key,
    required this.icono,
    required this.titulo,
    required this.texto,
    this.accion,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icono, size: 40, color: Paleta.pizarra),
            const SizedBox(height: 16),
            Text(
              titulo,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Paleta.tinta,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              texto,
              style: const TextStyle(fontSize: 16, color: Paleta.pizarra),
            ),
            if (accion != null) ...[
              const SizedBox(height: 20),
              accion!,
            ],
          ],
        ),
      ),
    );
  }
}
