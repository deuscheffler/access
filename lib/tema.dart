import 'package:flutter/material.dart';

import 'modelos.dart';

/// Paleta tomada del logo de Omega Access: azul de marca y fondo celeste
/// muy claro. Los tres colores de veredicto son fijos para todos los
/// clientes porque el operador debe reconocerlos de un vistazo.
class Paleta {
  static const tinta = Color(0xFF0E3E80);
  static const tintaOscura = Color(0xFF0A2E61);
  static const niebla = Color(0xFFEFF5FB);
  static const celeste = Color(0xFFE3EEF9);
  static const pizarra = Color(0xFF4A5A6E);
  static const linea = Color(0xFFD3DEEA);
  static const paso = Color(0xFF109B4E);
  static const alto = Color(0xFFD12F2F);
  static const atencion = Color(0xFFE39B12);

  static Color deVeredicto(Veredicto v) => switch (v) {
        Veredicto.valido => paso,
        Veredicto.rechazado => alto,
        Veredicto.advertencia => atencion,
        Veredicto.habilitado => tinta,
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

/// Ícono de Omega Access (el mismo del menú de aplicaciones).
class LogoOmega extends StatelessWidget {
  final double tamano;
  final bool sobreOscuro; // se conserva por compatibilidad

  const LogoOmega({super.key, this.tamano = 32, this.sobreOscuro = false});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(tamano * 0.22),
      child: Image.asset(
        'assets/img/icono.png',
        width: tamano,
        height: tamano,
        fit: BoxFit.cover,
      ),
    );
  }
}

/// Escudo de la institución.
class EscudoEscuela extends StatelessWidget {
  final double tamano;
  const EscudoEscuela({super.key, this.tamano = 40});

  @override
  Widget build(BuildContext context) => Image.asset(
        'assets/img/escuela.png',
        width: tamano,
        height: tamano,
        fit: BoxFit.contain,
      );
}

/// Escudo de la institución como marca de agua de fondo.
class MarcaAguaEscuela extends StatelessWidget {
  final double tamano;
  final double opacidad;
  const MarcaAguaEscuela({super.key, this.tamano = 320, this.opacidad = 0.07});

  @override
  Widget build(BuildContext context) => IgnorePointer(
        child: Center(
          child: Opacity(
            opacity: opacidad,
            child: Image.asset(
              'assets/img/escuela.png',
              width: tamano,
              height: tamano,
              fit: BoxFit.contain,
            ),
          ),
        ),
      );
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
