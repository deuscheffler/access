# Omega Access Control: versión sin conexión

App para controlar el ingreso a eventos escolares con códigos QR. No necesita
servidor ni internet: la nómina viaja dentro de la app y todos los celulares
generan y validan exactamente los mismos pases.

Institución: Escuela de Educación Básica «República de Italia», periodo
2026-2027. 1647 estudiantes en 52 cursos, de Inicial 3 años a 7.º.

## Eventos precargados

Vienen listos en todos los celulares, con 2 pases por estudiante:

| Fecha | Evento | Cursos | Estudiantes | Pases |
|---|---|---|---|---|
| 28 oct | Inauguración de deportes nivel elemental – matutina | Inicial 3 años a 3.º, matutina | 451 | 902 |
| 28 oct | Inauguración de deportes nivel elemental – vespertina | Inicial 3 años a 3.º, vespertina | 357 | 714 |
| 29 oct | Inauguración de deportes nivel básico – matutina | 4.º a 7.º, matutina | 458 | 916 |
| 29 oct | Inauguración de deportes nivel básico – vespertina | 4.º a 7.º, vespertina | 381 | 762 |

Como sus identificadores son fijos, no hace falta pasarlos de un celular a
otro: basta con instalar la app. Se pueden crear más eventos cuando se
necesite.

## Funciones principales

- **Enviar por grupo:** en el detalle del evento, elige uno o varios cursos
  (por ejemplo, 5.º matutina con sus tres paralelos), escribe el WhatsApp de la
  docente y envía **una imagen por pase**, con el nombre del estudiante, para
  que ella reenvíe a cada familia solo las suyas. WhatsApp acepta hasta 100
  imágenes por envío; si el grupo tiene más, la app los separa por paralelo.
  También se pueden descargar todas en un ZIP, o sacar un PDF solo para
  imprimir (no debe enviarse a las familias porque contiene todo el grupo).
- **Enviar a docentes:** usa la lista oficial de docentes (`assets/docentes.json`).
  Con «Enviar a los pendientes», la app prepara las imágenes de cada paralelo y
  abre WhatsApp en el chat de su docente con todo adjunto; tú solo tocas
  Enviar y vuelves a la app, que continúa con el siguiente. Marca cada
  paralelo enviado. Si cambia un docente, toca su fila para editarlo.
- **Autorizar sin QR:** si alguien no trae su pase, busca al estudiante por
  nombre o curso, verifica su identidad y autoriza el ingreso. El pase queda
  usado. Desde ahí también se habilita de nuevo un pase usado.
- **Reingreso:** si un pase sale en rojo como «ya utilizado» porque la persona
  salió y vuelve, la pantalla roja tiene el botón «permitir reingreso».
- **Agregar acceso:** para un estudiante que no está en la nómina, una
  autoridad o un invitado. También desde los pases de un estudiante se puede
  agregar un pase más. El nombre viaja dentro del QR, así que todas las
  puertas lo reconocen.
- **Informe:** por evento, en PDF (resumen por curso y detalle de ingresos) o
  en CSV para Excel. Cada lectura guarda hora, resultado, estudiante, curso,
  número de pase y nombre de la puerta.
- **Nombre de la puerta:** en el escáner, toca la barra superior para nombrar
  el celular (por ejemplo, «Puerta principal») y asignar sus cursos.

## Datos de la empresa

Edita `lib/empresa.dart` para completar RUC, dirección, teléfono y correo de
Omega Telecom. Los campos vacíos no se muestran en la app.

La política de privacidad y los términos y condiciones están en
`lib/pantallas/acerca.dart`. Son un borrador: conviene que los revise la
escuela y un asesor legal antes de la versión definitiva.

## Cómo funciona entre varios celulares

1. **Un celular crea el evento** (nombre, lugar, fecha) y elige los cursos que
   participan y cuántos pases recibe cada estudiante.
2. **Los demás celulares lo agregan** escaneando el código que muestra
   «Pasar este evento a otro celular». Así los 6 o más celulares quedan con el
   mismo evento sin internet. Si se cambian los cursos, se repite este paso.
3. **Los pases se comparten por curso:** en el detalle del evento, el botón PDF
   de cada curso crea un archivo con todos sus pases (6 por hoja, con líneas de
   corte) para enviarlo al presidente por WhatsApp o imprimirlo. También se
   puede compartir los pases de un solo estudiante como imágenes.
4. **En la puerta,** cada celular escanea y muestra el veredicto en pantalla
   completa: verde «Adelante», rojo «Alto», ámbar «Verificar».

### Importante: puertas por curso

Como los celulares no se comunican entre sí, cada uno solo sabe qué pases
pasaron por él. Si alguien copia un pase y lo presenta en dos puertas
distintas, ambas lo aceptarían. Para evitarlo, en el escáner toca
«Esta puerta recibe…» y asigna a cada celular los cursos que le corresponden
(por ejemplo, puerta 1: 1.º a 3.º matutina). Un pase de otro curso aparece en
ámbar con el aviso «Corresponde a otra puerta».

## Cómo compilar el APK

1. En GitHub crea un repositorio **privado** (contiene nombres de estudiantes
   menores de edad; no debe ser público).
2. Sube todo el contenido de esta carpeta, incluida la carpeta oculta `.github`.
3. En la pestaña **Actions**, espera a que termine «Compilar APK» (6 a 10 min).
4. Descarga `omega-access-demo` en **Artifacts** e instala el APK.

Si el proceso termina en rojo, copia el error del paso que falló y compártelo.

## Actualizar la lista de docentes

```
python tool/convertir_docentes.py DATOS_PARA_APLICACION_QR.xlsx
```

## Actualizar la nómina

Si cambian las listas (matrículas nuevas, retiros), pon todos los Excel en una
carpeta y ejecuta:

```
pip install openpyxl
python tool/convertir_nominas.py carpeta_con_los_excel
```

Esto regenera `assets/nomina.json`. Luego sube ese archivo al repositorio para
compilar un APK nuevo e instálalo en todos los celulares. La clave de firma se
conserva, así que los pases ya entregados siguen siendo válidos.

Nombre esperado de los archivos: `1RO_A_MAT.xlsx`, `7MO_C_VESP.xlsx`,
`INICIAL_3_AÑOS_A_MAT.xlsx`, etc.

## Privacidad

- La app solo lleva nombre, grado, paralelo y jornada. La cédula se usa una
  sola vez para crear un identificador y no se guarda; el correo no se usa.
- El APK contiene la nómina: instálalo solo en los celulares del personal y no
  lo publiques.
- La clave de firma está dentro de la app. Es suficiente para un evento
  escolar; con servidor, la firma se haría con una clave que nunca sale de él.

## Estructura

```
assets/nomina.json     nómina y clave de firma (generado)
lib/
  almacen.dart         nómina, eventos, pases usados y validación
  codigo_qr.dart       firma de pases y código para pasar eventos
  pantallas/           eventos, cursos, escáner, pases, PDF, nómina, registro
tool/
  convertir_nominas.py Excel -> assets/nomina.json
  configurar_android.sh ajustes usados al compilar
.github/workflows/     compilación automática del APK
```
