# Omega Access Control: demo local

Demo para verificar los mínimos funcionales. Todo funciona dentro del celular,
sin servidor ni internet: los datos se guardan en un archivo del teléfono.

## Qué incluye

- Crear eventos con nombre, lugar y fecha.
- Registrar estudiantes por grado y paralelo, o cargar 180 de prueba.
- Generar pases eligiendo grados y paralelos y cuántos pases por estudiante.
- Ver cada pase con su QR firmado y compartirlo como imagen por WhatsApp.
- Escanear con la cámara y recibir el veredicto a pantalla completa:
  verde «Adelante», rojo «Alto», ámbar «Verificar».
- Rechazar pases ya usados, de otro evento, alterados o ajenos.
- Registro de todas las lecturas con hora y resultado.

## Cómo obtener el APK (unos 10 minutos)

No necesitas instalar Flutter ni Android Studio. GitHub compila el APK gratis.

1. Crea una cuenta en github.com si no tienes.
2. Crea un repositorio nuevo, por ejemplo `omega-access-demo`. Puede ser privado.
3. En el repositorio, elige «uploading an existing file» y arrastra **todo el
   contenido** de esta carpeta, incluida la carpeta oculta `.github`.
   Si tu explorador de archivos no muestra `.github`, activa «mostrar archivos
   ocultos», o sube la carpeta con GitHub Desktop.
4. Confirma la subida en la rama `main`.
5. Abre la pestaña **Actions**. Verás el proceso «Compilar APK» en marcha.
   Tarda entre 6 y 10 minutos.
6. Cuando aparezca la marca verde, entra al proceso y descarga el archivo
   `omega-access-demo` en la sección **Artifacts**. Es un .zip con el APK.
7. Pasa el APK al celular, ábrelo y permite «instalar apps de origen
   desconocido» cuando Android lo pida.

Si el proceso termina en rojo, abre el paso que falló, copia el error y
compártelo para corregirlo.

## Guion sugerido para la demostración

1. En Eventos, toca «Cargar datos de prueba».
2. Entra a «Inauguración deportiva» y toca «Generar pases».
3. Marca 5.º completo y 6.º A, deja 2 pases por estudiante y genera.
4. Abre un paralelo, elige un estudiante y muestra sus dos pases.
   Compártelos por WhatsApp para enseñar cómo los recibiría la familia.
5. Abre esos pases en otro celular o en la computadora y vuelve al evento.
6. Toca «Escanear» y lee el primer pase: pantalla verde.
7. Léelo otra vez: pantalla roja, «Pase ya utilizado», con la hora del ingreso.
8. Con el botón de la mano (simular lectura) prueba un QR alterado y uno ajeno.
9. Vuelve y muestra el contador del evento y la pestaña Registro.

Con un solo celular, el botón de simular lectura reemplaza al segundo
dispositivo.

## Límites de esta demo (se resuelven con el servidor)

- Cada celular tiene sus propios datos: aún no se sincronizan entre teléfonos.
- La clave de firma está dentro de la app. En producción el servidor firma con
  Ed25519 y la app solo guarda la clave pública.
- El nombre de la institución y el logo son fijos.
- No hay usuarios, operadores ni puertas.
- No hay importación desde Excel, PDF por paralelo ni enlace para presidentes.

## Estructura

```
lib/
  main.dart            arranque y navegación
  modelos.dart         evento, estudiante, pase, escaneo
  almacen.dart         datos locales, generación de pases y validación
  codigo_qr.dart       firma y lectura del código
  tema.dart            paleta, tipografía y logo
  pantallas/           eventos, estudiantes, pases, escáner, registro
branding/              ícono de la app
tool/                  ajustes de Android usados al compilar
.github/workflows/     compilación automática del APK
```

Tipografía: Barlow y Barlow Condensed (licencia SIL Open Font, ver
`assets/fonts/OFL.txt`).
