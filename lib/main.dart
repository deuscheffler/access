import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'almacen.dart';
import 'empresa.dart';
import 'pantallas/acerca.dart';
import 'pantallas/estudiantes.dart';
import 'pantallas/eventos.dart';
import 'pantallas/registro.dart';
import 'tema.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const OmegaAccessApp());
}

class OmegaAccessApp extends StatelessWidget {
  const OmegaAccessApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: Empresa.producto,
      debugShowCheckedModeBanner: false,
      theme: temaOmega(),
      locale: const Locale('es'),
      supportedLocales: const [Locale('es'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const Bienvenida(),
    );
  }
}

/// Pantalla de inicio: muestra el logo completo mientras se carga la nómina.
class Bienvenida extends StatefulWidget {
  const Bienvenida({super.key});

  @override
  State<Bienvenida> createState() => _BienvenidaState();
}

class _BienvenidaState extends State<Bienvenida> {
  String? _error;

  @override
  void initState() {
    super.initState();
    _iniciar();
  }

  Future<void> _iniciar() async {
    try {
      await Future.wait([
        Almacen.i.cargar(),
        Future<void>.delayed(const Duration(milliseconds: 1800)),
      ]);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 350),
        pageBuilder: (_, __, ___) => const Inicio(),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
      ));
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 36),
                  child: Image.asset('assets/img/omega_access.png'),
                ),
              ),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.all(24),
                child: Text('No se pudo iniciar: $_error',
                    style: const TextStyle(color: Paleta.alto)),
              ),
            Padding(
              padding: const EdgeInsets.only(bottom: 28),
              child: Column(
                children: [
                  const Text(
                    'Desarrollado por',
                    style: TextStyle(fontSize: 12, color: Paleta.pizarra),
                  ),
                  const SizedBox(height: 6),
                  Image.asset('assets/img/omega_telecom.png', height: 34),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class Inicio extends StatefulWidget {
  const Inicio({super.key});

  @override
  State<Inicio> createState() => _InicioState();
}

class _InicioState extends State<Inicio> {
  int _indice = 0;

  @override
  Widget build(BuildContext context) {
    const paginas = [
      PaginaEventos(),
      PaginaEstudiantes(),
      PaginaRegistro(),
      PaginaAcerca(),
    ];
    return Scaffold(
      body: paginas[_indice],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _indice,
        onDestinationSelected: (i) => setState(() => _indice = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.event_outlined),
            selectedIcon: Icon(Icons.event),
            label: 'Eventos',
          ),
          NavigationDestination(
            icon: Icon(Icons.groups_outlined),
            selectedIcon: Icon(Icons.groups),
            label: 'Nómina',
          ),
          NavigationDestination(
            icon: Icon(Icons.fact_check_outlined),
            selectedIcon: Icon(Icons.fact_check),
            label: 'Accesos',
          ),
          NavigationDestination(
            icon: Icon(Icons.info_outline),
            selectedIcon: Icon(Icons.info),
            label: 'Acerca de',
          ),
        ],
      ),
    );
  }
}
