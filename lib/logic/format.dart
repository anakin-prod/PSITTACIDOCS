/// Petites fonctions de format partagées (nombres et dates à la française).

/// Lit un nombre saisi par l'utilisateur, avec virgule ou point.
double? parseNumber(String text) {
  final t = text.trim().replaceAll(',', '.');
  if (t.isEmpty) return null;
  return double.tryParse(t);
}

/// Affiche un nombre : « 22 », « 22,5 ».
String formatNumber(double value, {int decimals = 1}) {
  if (value == value.roundToDouble()) return value.toStringAsFixed(0);
  return value.toStringAsFixed(decimals).replaceAll('.', ',');
}

String _two(int n) => n.toString().padLeft(2, '0');

/// « 25/09/2026 »
String formatDate(DateTime d) => '${_two(d.day)}/${_two(d.month)}/${d.year}';

/// « 25/09/2026 08:30 »
String formatDateTime(DateTime d) => '${formatDate(d)} ${_two(d.hour)}:${_two(d.minute)}';

/// Date ISO « 2026-09-25T08:30:00 » sans fuseau, pour l'enregistrement.
String isoDateTime(DateTime d) =>
    '${d.year}-${_two(d.month)}-${_two(d.day)}T${_two(d.hour)}:${_two(d.minute)}:00';

const List<String> _monthsShort = ['JANV', 'FÉVR', 'MARS', 'AVR', 'MAI', 'JUIN', 'JUIL', 'AOÛT', 'SEPT', 'OCT', 'NOV', 'DÉC'];

/// « SEPT »
String frenchShortMonth(int month) => _monthsShort[month - 1];

/// « à l'instant », « il y a 5 min », « il y a 3 h », sinon la date complète.
String relativeAgo(DateTime d) {
  final diff = DateTime.now().difference(d);
  if (diff.inSeconds < 45) return 'à l’instant';
  if (diff.inMinutes < 60) return 'il y a ${diff.inMinutes < 1 ? 1 : diff.inMinutes} min';
  if (diff.inHours < 24) return 'il y a ${diff.inHours} h';
  return 'le ${formatDateTime(d)}';
}
