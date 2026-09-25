/// Calcul du coefficient de consanguinité (Wright) à partir de la généalogie.
///
/// Méthode : coefficients de parenté (« kinship »), calculés récursivement
/// sur les ancêtres connus.
///   - parenté(a, a) = ½ × (1 + consanguinité de a)
///   - parenté(a, b) = ½ × (parenté(père de a, b) + parenté(mère de a, b)),
///     où a n'est pas un ancêtre de b (on descend toujours depuis l'individu
///     de la génération la plus récente).
/// La consanguinité d'un oiseau est la parenté entre son père et sa mère ;
/// celle des futurs jeunes d'un couple est la parenté entre les deux oiseaux.
///
/// Les ancêtres inconnus sont considérés comme non apparentés : le résultat
/// est donc une valeur minimale, d'autant plus fiable que la généalogie
/// saisie est complète. Repères : cousins germains 6,25 %, demi-frère et
/// demi-sœur 12,5 %, frère et sœur ou parent et jeune 25 %.
class InbreedingCalculator {
  /// Renvoie la bague du père (ou null si inconnu).
  final String? Function(String ring) sireOf;

  /// Renvoie la bague de la mère (ou null si inconnue).
  final String? Function(String ring) damOf;

  final Map<String, int> _generation = {};
  final Map<String, double> _kinship = {};

  /// Garde-fou contre une généalogie erronée (oiseau déclaré comme son propre
  /// ancêtre) : au-delà, la branche est ignorée.
  static const int _maxDepth = 40;

  InbreedingCalculator({required this.sireOf, required this.damOf});

  /// Nombre de générations connues au-dessus de l'oiseau (0 = fondateur).
  int generationOf(String ring) => _gen(ring, <String>{});

  int _gen(String ring, Set<String> visiting) {
    final cached = _generation[ring];
    if (cached != null) return cached;
    if (visiting.contains(ring) || visiting.length > _maxDepth) return 0;
    visiting.add(ring);
    var g = 0;
    final s = sireOf(ring);
    final d = damOf(ring);
    if (s != null) g = _gen(s, visiting) + 1;
    if (d != null) {
      final gd = _gen(d, visiting) + 1;
      if (gd > g) g = gd;
    }
    visiting.remove(ring);
    _generation[ring] = g;
    return g;
  }

  /// Coefficient de parenté entre deux oiseaux (0 à 1).
  double kinship(String? a, String? b) => _kin(a, b, 0);

  double _kin(String? a, String? b, int depth) {
    if (a == null || b == null) return 0;
    if (depth > _maxDepth * 2) return 0;
    final key = a.compareTo(b) <= 0 ? '$a|$b' : '$b|$a';
    final cached = _kinship[key];
    if (cached != null) return cached;

    double result;
    if (a == b) {
      result = 0.5 * (1 + _kin(sireOf(a), damOf(a), depth + 1));
    } else {
      // On descend depuis l'oiseau le plus récent, qui ne peut pas être un
      // ancêtre de l'autre.
      var x = a;
      var y = b;
      if (generationOf(x) < generationOf(y)) {
        x = b;
        y = a;
      }
      final sx = sireOf(x);
      final dx = damOf(x);
      if (sx == null && dx == null) {
        result = 0;
      } else {
        result = 0.5 * (_kin(sx, y, depth + 1) + _kin(dx, y, depth + 1));
      }
    }
    _kinship[key] = result;
    return result;
  }

  /// Consanguinité d'un oiseau (parenté entre son père et sa mère).
  double inbreedingOf(String ring) => kinship(sireOf(ring), damOf(ring));
}

/// Formate un coefficient (0 à 1) en pourcentage français : 25 %, 12,5 %, 6,25 %.
String formatPercent(double value) {
  var s = (value * 100).toStringAsFixed(2);
  if (s.contains('.')) {
    s = s.replaceAll(RegExp(r'0+$'), '');
    s = s.replaceAll(RegExp(r'\.$'), '');
  }
  return '${s.replaceAll('.', ',')} %';
}

/// Seuil à partir duquel l'appli alerte (équivalent de cousins germains).
const double kInbreedingWarningThreshold = 0.0625;

/// Niveau de consanguinité, avec un repère de parenté parlant.
String inbreedingLevel(double value) {
  if (value <= 0) return 'Aucune consanguinité détectée';
  if (value < 0.0625) return 'Faible';
  if (value < 0.125) return 'Modérée (comparable à des cousins germains)';
  if (value < 0.25) return 'Élevée (comparable à un demi-frère et une demi-sœur)';
  return 'Très élevée (comparable à un frère et une sœur, ou à un parent et son jeune)';
}
