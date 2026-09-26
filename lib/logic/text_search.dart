/// Recherche de texte tolérante : sans majuscules ni accents,
/// « eclectus » trouve « Éclectus » et « oeuf » trouve « œuf ».
String normalizeText(String input) {
  var s = input.toLowerCase().replaceAll('œ', 'oe').replaceAll('æ', 'ae');
  const from = 'àâäáãåçéèêëíìîïñóòôöõúùûüýÿ’';
  const to = 'aaaaaaceeeeiiiinooooouuuuyy\'';
  final buffer = StringBuffer();
  for (final ch in s.split('')) {
    final i = from.indexOf(ch);
    buffer.write(i >= 0 ? to[i] : ch);
  }
  return buffer.toString();
}

/// Vrai si l'un des textes contient la recherche (déjà normalisée).
bool matchesAny(String normalizedQuery, Iterable<String?> texts) {
  for (final t in texts) {
    if (t != null && t.isNotEmpty && normalizeText(t).contains(normalizedQuery)) return true;
  }
  return false;
}
