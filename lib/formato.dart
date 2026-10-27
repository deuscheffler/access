const _meses = [
  'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio', 'julio',
  'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre',
];

const _dias = [
  'lunes', 'martes', 'miércoles', 'jueves', 'viernes', 'sábado', 'domingo',
];

String _dos(int n) => n.toString().padLeft(2, '0');

String hora(DateTime d) => '${_dos(d.hour)}:${_dos(d.minute)}';

String fechaCorta(DateTime d) => '${d.day} de ${_meses[d.month - 1]}';

String fechaLarga(DateTime d) =>
    '${_dias[d.weekday - 1]} ${d.day} de ${_meses[d.month - 1]} de ${d.year}';

String fechaYHora(DateTime d) => '${fechaCorta(d)}, ${hora(d)}';

/// Minúsculas y sin tildes, para búsquedas.
String normalizar(String s) {
  const de = 'áéíóúüñÁÉÍÓÚÜÑ';
  const a = 'aeiouunAEIOUUN';
  final b = StringBuffer();
  for (final ch in s.split('')) {
    final i = de.indexOf(ch);
    b.write(i >= 0 ? a[i] : ch);
  }
  return b.toString().toLowerCase();
}

/// 0991234567 -> 593991234567 (formato internacional de WhatsApp).
String? numeroWhatsApp(String texto) {
  var d = texto.replaceAll(RegExp(r'[^0-9]'), '');
  if (d.isEmpty) return null;
  if (d.startsWith('593')) return d.length >= 11 ? d : null;
  if (d.startsWith('0')) d = d.substring(1);
  return d.length == 9 ? '593$d' : null;
}
