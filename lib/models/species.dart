/// Une espèce de psittacidé, avec son statut réglementaire CITES / UE.
///
/// Les statuts sont ceux du règlement CITES en vigueur (texte consolidé du
/// 21/05/2023, inchangé pour les perroquets à la CoP20 de décembre 2025) et
/// du règlement européen (CE) n° 338/97. Voir la fiche de chaque espèce dans
/// l'appli pour le détail et un lien vers Species+ (base officielle
/// PNUE-WCMC) permettant de vérifier avant toute cession réelle.
class Species {
  final String sci; // nom scientifique, ex. "Pionus chalcopterus"
  final String fr; // nom français
  final String alt; // autres noms français, séparés par ';'
  final String cites; // 'I', 'II', 'NI' (non inscrite)
  final String ue; // 'A', 'B', 'NI'
  final String note; // précision éventuelle (ex. sous-espèce, cas particulier)

  const Species({
    required this.sci,
    required this.fr,
    required this.alt,
    required this.cites,
    required this.ue,
    required this.note,
  });

  factory Species.fromJson(Map<String, dynamic> json) => Species(
    sci: json['sci'] as String,
    fr: json['fr'] as String,
    alt: json['alt'] as String? ?? '',
    cites: json['cites'] as String? ?? 'II',
    ue: json['ue'] as String? ?? 'B',
    note: json['note'] as String? ?? '',
  );

  String get label => fr.isNotEmpty ? fr : sci;

  List<String> get altNames =>
      alt.split(';').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

  String get citesLabel {
    switch (cites) {
      case 'I':
        return 'Annexe I';
      case 'NI':
        return 'Non inscrite';
      default:
        return 'Annexe II';
    }
  }

  String get ueLabel {
    switch (ue) {
      case 'A':
        return 'Annexe A';
      case 'NI':
        return 'Non inscrite';
      default:
        return 'Annexe B';
    }
  }

  bool get isAnnexA => ue == 'A';
  bool get isNotListed => cites == 'NI';
}
