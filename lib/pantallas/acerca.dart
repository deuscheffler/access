import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../almacen.dart';
import '../empresa.dart';
import '../tema.dart';

Future<void> abrirWebEmpresa(BuildContext context) async {
  final ok = await launchUrl(
    Uri.parse(Empresa.url),
    mode: LaunchMode.externalApplication,
  );
  if (!ok && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('No se pudo abrir el navegador. Visita ${Empresa.web}'),
    ));
  }
}

class PaginaAcerca extends StatelessWidget {
  const PaginaAcerca({super.key});

  @override
  Widget build(BuildContext context) {
    final a = Almacen.i;
    final datos = <(IconData, String)>[
      if (Empresa.ruc.isNotEmpty) (Icons.badge_outlined, 'RUC ${Empresa.ruc}'),
      if (Empresa.direccion.isNotEmpty)
        (Icons.place_outlined, Empresa.direccion),
      if (Empresa.ciudad.isNotEmpty) (Icons.map_outlined, Empresa.ciudad),
      if (Empresa.telefono.isNotEmpty) (Icons.phone_outlined, Empresa.telefono),
      if (Empresa.correo.isNotEmpty) (Icons.mail_outline, Empresa.correo),
      (Icons.language, Empresa.web),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Acerca de')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
        children: [
          _Tarjeta(
            child: Column(
              children: [
                Image.asset('assets/img/omega_access.png', height: 92),
                const SizedBox(height: 8),
                const Text(
                  'Versión ${Empresa.version}',
                  style: TextStyle(color: Paleta.pizarra),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _Tarjeta(
            child: Row(
              children: [
                const EscudoEscuela(tamano: 56),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('En uso en',
                          style:
                              TextStyle(fontSize: 13, color: Paleta.pizarra)),
                      Text(
                        a.institucion.isEmpty ? Cliente.nombre : a.institucion,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: Paleta.tinta,
                        ),
                      ),
                      Text(
                        '${a.estudiantes.length} estudiantes, '
                        'periodo ${a.periodo}',
                        style: const TextStyle(
                            fontSize: 13, color: Paleta.pizarra),
                      ),
                      if (a.escuelaDireccion.isNotEmpty ||
                          a.escuelaTelefono.isNotEmpty)
                        Text(
                          [
                            if (a.escuelaDireccion.isNotEmpty)
                              a.escuelaDireccion,
                            if (a.escuelaTelefono.isNotEmpty)
                              'Tel. ${a.escuelaTelefono}',
                            if (a.escuelaCorreo.isNotEmpty) a.escuelaCorreo,
                          ].join(', '),
                          style: const TextStyle(
                              fontSize: 13, color: Paleta.pizarra),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _Tarjeta(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Diseñado y desarrollado por',
                  style: TextStyle(fontSize: 13, color: Paleta.pizarra),
                ),
                const SizedBox(height: 10),
                Center(
                  child: Image.asset('assets/img/omega_telecom.png',
                      height: 64),
                ),
                const SizedBox(height: 14),
                for (final d in datos)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Icon(d.$1, size: 20, color: Paleta.tinta),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(d.$2,
                              style: const TextStyle(fontSize: 15)),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: () => abrirWebEmpresa(context),
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('Visitar ${Empresa.web}'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _Tarjeta(
            relleno: EdgeInsets.zero,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.privacy_tip_outlined,
                      color: Paleta.tinta),
                  title: const Text('Política de privacidad'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const PaginaLegal(
                        titulo: 'Política de privacidad',
                        secciones: politicaPrivacidad,
                      ),
                    ),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading:
                      const Icon(Icons.gavel_outlined, color: Paleta.tinta),
                  title: const Text('Términos y condiciones'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const PaginaLegal(
                        titulo: 'Términos y condiciones',
                        secciones: terminosCondiciones,
                      ),
                    ),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.description_outlined,
                      color: Paleta.tinta),
                  title: const Text('Licencias de software'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => showLicensePage(
                    context: context,
                    applicationName: Empresa.producto,
                    applicationVersion: Empresa.version,
                    applicationLegalese: '© 2026 ${Empresa.nombre}',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            '© 2026 ${Empresa.nombre}. Todos los derechos reservados.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Paleta.pizarra),
          ),
        ],
      ),
    );
  }
}

class _Tarjeta extends StatelessWidget {
  final Widget child;
  final EdgeInsets relleno;
  const _Tarjeta({required this.child, this.relleno = const EdgeInsets.all(18)});

  @override
  Widget build(BuildContext context) => Container(
        padding: relleno,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        clipBehavior: Clip.antiAlias,
        child: child,
      );
}

class PaginaLegal extends StatelessWidget {
  final String titulo;
  final List<(String, String)> secciones;
  const PaginaLegal({super.key, required this.titulo, required this.secciones});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: Text(titulo)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
        children: [
          const Text(
            'Versión 1.0, vigente desde el 25 de octubre de 2026.',
            style: TextStyle(fontSize: 13, color: Paleta.pizarra),
          ),
          for (final s in secciones) ...[
            const SizedBox(height: 20),
            Text(
              s.$1,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: Paleta.tinta,
              ),
            ),
            const SizedBox(height: 6),
            Text(s.$2, style: const TextStyle(fontSize: 15, height: 1.45)),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------
// Textos legales. Borrador preparado para revisión de la institución
// y de un asesor legal antes de su publicación definitiva.
// ---------------------------------------------------------------

const _contacto = Empresa.correo == ''
    ? 'a través de ${Empresa.web}'
    : 'al correo ${Empresa.correo} o a través de ${Empresa.web}';

const List<(String, String)> politicaPrivacidad = [
  (
    '1. Quiénes tratan los datos',
    'La institución educativa que usa la app es la responsable del '
        'tratamiento de los datos de sus estudiantes. ${Empresa.nombre}, '
        'desarrolladora de ${Empresa.producto}, actúa como encargada del '
        'tratamiento y solo procesa los datos para prestar el servicio de '
        'control de acceso, conforme a la Ley Orgánica de Protección de Datos '
        'Personales del Ecuador.'
  ),
  (
    '2. Qué datos usa la app',
    'De cada estudiante: nombres y apellidos, grado, paralelo y jornada. '
        'De cada lectura en la puerta: fecha y hora, resultado, número de pase '
        'y el nombre asignado al celular o puerta. La app no almacena números '
        'de cédula, correos electrónicos, fotografías, ubicación ni datos de '
        'los invitados que ingresan con un pase.'
  ),
  (
    '3. Para qué se usan',
    'Exclusivamente para generar los pases de cada evento, validar el '
        'ingreso en la puerta y elaborar informes de asistencia para la '
        'institución. No se usan con fines publicitarios ni se venden o '
        'ceden a terceros.'
  ),
  (
    '4. Dónde se guardan',
    'Toda la información se guarda en la memoria del celular donde está '
        'instalada la app. La app no envía datos por internet ni a servidores '
        'de ${Empresa.nombre}. Los pases, PDF e informes solo salen del '
        'celular cuando el usuario decide compartirlos, por ejemplo por '
        'WhatsApp; desde ese momento quedan sujetos a las condiciones de la '
        'aplicación que se use para enviarlos.'
  ),
  (
    '5. Cuánto tiempo se conservan',
    'La nómina se mantiene mientras dure el periodo lectivo vigente. El '
        'registro de accesos puede borrarse en cualquier momento desde la app '
        'y la institución debe eliminarlo al finalizar el periodo, salvo que '
        'necesite conservar los informes por obligación legal o '
        'administrativa.'
  ),
  (
    '6. Datos de niñas, niños y adolescentes',
    'Por tratarse de datos de menores de edad, la institución debe contar '
        'con la autorización de sus representantes legales para este uso. La '
        'app se instala solo en los celulares del personal autorizado y no '
        'debe distribuirse públicamente.'
  ),
  (
    '7. Seguridad',
    'Los pases llevan una firma digital que impide modificarlos o '
        'fabricarlos sin la clave de la institución. Se recomienda proteger '
        'los celulares con bloqueo de pantalla y no compartir el archivo de '
        'instalación de la app.'
  ),
  (
    '8. Derechos de los titulares',
    'Los representantes de los estudiantes pueden ejercer sus derechos de '
        'acceso, rectificación, actualización, eliminación, oposición y '
        'portabilidad ante la institución educativa. Para consultas sobre la '
        'app pueden contactar a ${Empresa.nombre} $_contacto.'
  ),
  (
    '9. Cambios',
    'Esta política puede actualizarse. La versión vigente siempre estará '
        'disponible en esta sección de la app.'
  ),
];

const List<(String, String)> terminosCondiciones = [
  (
    '1. Aceptación',
    'Al instalar o usar ${Empresa.producto} aceptas estos términos. Si no '
        'estás de acuerdo, no uses la app.'
  ),
  (
    '2. Licencia de uso',
    '${Empresa.nombre} otorga a la institución una licencia no exclusiva e '
        'intransferible para usar la app en sus eventos. La app, su diseño, '
        'código y marcas pertenecen a ${Empresa.nombre}. No está permitido '
        'copiarla, modificarla, descompilarla ni distribuirla sin autorización '
        'escrita.'
  ),
  (
    '3. Usuarios autorizados',
    'La app debe ser usada solo por el personal que la institución designe. '
        'Cada usuario es responsable del celular en el que está instalada y '
        'de los datos que contiene.'
  ),
  (
    '4. Uso correcto de los pases',
    'Cada pase permite un ingreso al evento para el que fue emitido. '
        'Copiar, alterar, vender o falsificar pases está prohibido y la '
        'institución puede negar el ingreso a quien lo haga. Para evitar '
        'ingresos duplicados entre puertas, la institución debe asignar los '
        'cursos que atiende cada celular.'
  ),
  (
    '5. Funcionamiento sin conexión',
    'La app funciona sin internet. Cada celular registra los ingresos que '
        'valida; los informes de un celular reflejan solo las lecturas hechas '
        'en él. La institución es responsable de consolidar los informes de '
        'todas las puertas.'
  ),
  (
    '6. Limitación de responsabilidad',
    'La app se entrega para apoyar el control de acceso y no reemplaza la '
        'supervisión del personal. ${Empresa.nombre} no responde por pérdidas '
        'derivadas del mal uso de la app, del extravío o daño de los celulares, '
        'ni por decisiones de ingreso tomadas en la puerta.'
  ),
  (
    '7. Soporte y actualizaciones',
    '${Empresa.nombre} puede publicar nuevas versiones con mejoras o '
        'correcciones. Las condiciones de soporte se acuerdan con la '
        'institución por separado.'
  ),
  (
    '8. Ley aplicable',
    'Estos términos se rigen por las leyes de la República del Ecuador. '
        'Cualquier controversia se resolverá ante los jueces competentes del '
        'Ecuador.'
  ),
  (
    '9. Contacto',
    'Para consultas sobre estos términos puedes comunicarte con '
        '${Empresa.nombre} $_contacto.'
  ),
];
