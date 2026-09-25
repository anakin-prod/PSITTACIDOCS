/// Moteur du calculateur génétique, en mode libre : l'éleveur indique pour
/// chaque mutation son mode de transmission et le génotype des parents.
///
/// Rappel : chez les oiseaux, le mâle porte deux chromosomes sexuels Z (ZZ)
/// et la femelle un Z et un W (ZW). Pour une mutation liée au sexe, la
/// femelle n'a qu'une copie : elle est soit visuelle, soit normale, jamais
/// porteuse. Ses fils reçoivent son chromosome Z, ses filles son W.
///
/// Limites (affichées dans l'appli) :
///   - les mutations sont considérées comme indépendantes : la liaison entre
///     mutations liées au sexe (crossing-over) n'est pas prise en compte ;
///   - les séries d'allèles d'un même gène ne sont pas gérées : une série
///     doit être saisie comme une seule mutation.
enum InheritanceMode { autosomalRecessive, sexLinkedRecessive, dominant, incompleteDominant }

String inheritanceLabel(InheritanceMode mode) => switch (mode) {
  InheritanceMode.autosomalRecessive => 'Récessive autosomale',
  InheritanceMode.sexLinkedRecessive => 'Récessive liée au sexe',
  InheritanceMode.dominant => 'Dominante',
  InheritanceMode.incompleteDominant => 'Codominante (dominance incomplète)',
};

/// Un génotype sélectionnable pour un parent : nombre de copies mutées.
class GenotypeOption {
  final int copies;
  final String label;
  const GenotypeOption(this.copies, this.label);
}

/// Génotypes possibles d'un parent, selon le mode et le sexe.
List<GenotypeOption> genotypeOptions(InheritanceMode mode, {required bool female}) => switch (mode) {
  InheritanceMode.autosomalRecessive => const [
    GenotypeOption(0, 'Normal'),
    GenotypeOption(1, 'Porteur'),
    GenotypeOption(2, 'Visuel'),
  ],
  InheritanceMode.sexLinkedRecessive => female
      ? const [GenotypeOption(0, 'Normale'), GenotypeOption(1, 'Visuelle')]
      : const [
          GenotypeOption(0, 'Normal'),
          GenotypeOption(1, 'Porteur'),
          GenotypeOption(2, 'Visuel'),
        ],
  InheritanceMode.dominant => const [
    GenotypeOption(0, 'Absente'),
    GenotypeOption(1, '1 facteur'),
    GenotypeOption(2, '2 facteurs'),
  ],
  InheritanceMode.incompleteDominant => const [
    GenotypeOption(0, 'Absente'),
    GenotypeOption(1, 'Simple facteur'),
    GenotypeOption(2, 'Double facteur'),
  ],
};

/// Une mutation saisie dans le calculateur.
class GeneInput {
  String name;
  InheritanceMode mode;
  int father; // copies mutées chez le père (0 à 2)
  int mother; // copies mutées chez la mère (0 à 2, ou 0 à 1 si liée au sexe)

  GeneInput({
    this.name = '',
    this.mode = InheritanceMode.autosomalRecessive,
    this.father = 0,
    this.mother = 0,
  });
}

/// Un résultat : une combinaison de mutations et sa probabilité (0 à 1)
/// parmi les jeunes du même sexe.
class GeneticOutcome {
  final String label;
  final double probability;
  const GeneticOutcome(this.label, this.probability);
}

class GeneticResult {
  final List<GeneticOutcome> sons;
  final List<GeneticOutcome> daughters;
  const GeneticResult(this.sons, this.daughters);
}

class _Split {
  final Map<int, double> sons;
  final Map<int, double> daughters;
  const _Split(this.sons, this.daughters);
}

void _add(Map<int, double> m, int k, double p) {
  if (p <= 0) return;
  m[k] = (m[k] ?? 0) + p;
}

/// Répartition du nombre de copies mutées chez les jeunes, par sexe.
_Split _offspring(GeneInput g) {
  final sons = <int, double>{};
  final daughters = <int, double>{};
  final p = g.father.clamp(0, 2) / 2; // probabilité que le père transmette la mutation
  if (g.mode == InheritanceMode.sexLinkedRecessive) {
    final cm = g.mother.clamp(0, 1); // la mère n'a qu'un chromosome Z
    // Fils : Z du père + Z de la mère.
    _add(sons, cm, 1 - p);
    _add(sons, cm + 1, p);
    // Filles : Z du père + W de la mère.
    _add(daughters, 0, 1 - p);
    _add(daughters, 1, p);
  } else {
    final q = g.mother.clamp(0, 2) / 2;
    for (final m in [sons, daughters]) {
      _add(m, 0, (1 - p) * (1 - q));
      _add(m, 1, p * (1 - q) + q * (1 - p));
      _add(m, 2, p * q);
    }
  }
  return _Split(sons, daughters);
}

/// Effet visible et statut de porteur d'une mutation pour un jeune.
({String? visual, String? carrier}) _effect(GeneInput g, int copies, {required bool female}) {
  final name = g.name.trim().isEmpty ? 'Mutation' : g.name.trim();
  if (copies <= 0) return (visual: null, carrier: null);
  // Récessive : 2 copies = visuel, 1 copie = porteur. Liée au sexe : la
  // femelle n'a qu'une copie, donc 1 copie = visuelle chez elle.
  final bool visualRecessive = copies >= 2 || (female && g.mode == InheritanceMode.sexLinkedRecessive);
  if (g.mode == InheritanceMode.autosomalRecessive || g.mode == InheritanceMode.sexLinkedRecessive) {
    return visualRecessive ? (visual: name, carrier: null) : (visual: null, carrier: name);
  }
  if (g.mode == InheritanceMode.dominant) {
    return (visual: copies >= 2 ? '$name (2 facteurs)' : name, carrier: null);
  }
  return (visual: copies >= 2 ? '$name double facteur' : '$name simple facteur', carrier: null);
}

List<GeneticOutcome> _combine(List<GeneInput> genes, List<Map<int, double>> perGene, {required bool female}) {
  var partial = <({List<String> visuals, List<String> carriers, double p})>[
    (visuals: const <String>[], carriers: const <String>[], p: 1.0),
  ];
  for (var i = 0; i < genes.length; i++) {
    final next = <({List<String> visuals, List<String> carriers, double p})>[];
    for (final acc in partial) {
      perGene[i].forEach((copies, prob) {
        final e = _effect(genes[i], copies, female: female);
        next.add((
          visuals: [...acc.visuals, if (e.visual != null) e.visual!],
          carriers: [...acc.carriers, if (e.carrier != null) e.carrier!],
          p: acc.p * prob,
        ));
      });
    }
    partial = next;
  }
  final totals = <String, double>{};
  for (final r in partial) {
    var label = r.visuals.isEmpty ? 'Phénotype ancestral' : r.visuals.join(' + ');
    if (r.carriers.isNotEmpty) {
      label += ' · ${female ? 'porteuse' : 'porteur'} de ${r.carriers.join(', ')}';
    }
    totals[label] = (totals[label] ?? 0) + r.p;
  }
  final out = totals.entries
      .where((e) => e.value > 1e-9)
      .map((e) => GeneticOutcome(e.key, e.value))
      .toList()
    ..sort((a, b) => b.probability.compareTo(a.probability));
  return out;
}

/// Calcule les combinaisons théoriques chez les jeunes mâles et femelles.
GeneticResult computeOffspring(List<GeneInput> genes) {
  if (genes.isEmpty) return const GeneticResult([], []);
  final splits = genes.map(_offspring).toList();
  return GeneticResult(
    _combine(genes, [for (final s in splits) s.sons], female: false),
    _combine(genes, [for (final s in splits) s.daughters], female: true),
  );
}
