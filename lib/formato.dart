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
