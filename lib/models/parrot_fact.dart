/// Une information « Le saviez-vous ? » sur les perroquets, toujours sourcée.
///
/// Chargées depuis assets/data/parrot_facts.json :
///   {"id": "f001", "theme": "Anatomie", "text": "…", "source": "…",
///    "sci": "Nom scientifique (facultatif, si l'information concerne une espèce)"}
/// Une information sans texte ou sans source n'est pas affichée.
class ParrotFact {
  final String id;
  final String theme;
  final String text;
  final String source;
  final String? sci;

  const ParrotFact({
    required this.id,
    required this.theme,
    required this.text,
    required this.source,
    this.sci,
  });

  factory ParrotFact.fromJson(Map<String, dynamic> json) => ParrotFact(
    id: json['id'] as String? ?? '',
    theme: json['theme'] as String? ?? 'Divers',
    text: json['text'] as String? ?? '',
    source: json['source'] as String? ?? '',
    sci: json['sci'] as String?,
  );

  bool get isValid => text.trim().isNotEmpty && source.trim().isNotEmpty;
}
