import 'bird_document.dart';

/// La fiche individuelle d'un oiseau de l'élevage.
class Bird {
  String ring; // numéro de bague, identifiant unique de l'oiseau
  String sci; // nom scientifique de l'espèce
  String mutation;
  String sex; // 'M' | 'F' | '' (inconnu)
  String born; // ISO 8601, ou '' si inconnue
  bool bornEstimated;
  String origin; // 'Né à l’élevage' | 'Acheté' | 'Échange' | 'Don'
  String status;
  String? fatherRing;
  String? motherRing;
  String ringType; // 'Fermée' | 'Ouverte' | 'Aucune'
  String ringDiameter;
  String location; // volière
  String? photoPath;
  String notes;
  String? quarantineUntil; // ISO 8601
  List<BirdDocument> documents;
  List<HealthEntry> health;
  Cession? cession;

  Bird({
    required this.ring,
    required this.sci,
    this.mutation = 'Ancestral',
    this.sex = '',
    this.born = '',
    this.bornEstimated = false,
    this.origin = 'Né à l’élevage',
    this.status = 'Jeune',
    this.fatherRing,
    this.motherRing,
    this.ringType = 'Fermée',
    this.ringDiameter = '',
    this.location = '',
    this.photoPath,
    this.notes = '',
    this.quarantineUntil,
    List<BirdDocument>? documents,
    List<HealthEntry>? health,
    this.cession,
  }) : documents = documents ?? [],
       health = health ?? [];

  bool get isQuarantined => status == 'En quarantaine';
  bool get isCeded => cession != null;
  bool get hasParents => fatherRing != null || motherRing != null;

  /// Dernière pesée enregistrée, ou null.
  HealthEntry? get lastWeighing {
    final weighings = health
        .where((h) => h.type == 'Pesée' && h.weight != null)
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    return weighings.isEmpty ? null : weighings.last;
  }

  List<HealthEntry> get weighingsSortedAsc {
    final w = health.where((h) => h.type == 'Pesée' && h.weight != null).toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    return w;
  }

  factory Bird.fromJson(Map<String, dynamic> json) => Bird(
    ring: json['ring'] as String,
    sci: json['sci'] as String,
    mutation: json['mutation'] as String? ?? 'Ancestral',
    sex: json['sex'] as String? ?? '',
    born: json['born'] as String? ?? '',
    bornEstimated: json['bornEstimated'] as bool? ?? false,
    origin: json['origin'] as String? ?? 'Né à l’élevage',
    status: json['status'] as String? ?? 'Jeune',
    fatherRing: json['fatherRing'] as String?,
    motherRing: json['motherRing'] as String?,
    ringType: json['ringType'] as String? ?? 'Fermée',
    ringDiameter: json['ringDiameter'] as String? ?? '',
    location: json['location'] as String? ?? '',
    photoPath: json['photoPath'] as String?,
    notes: json['notes'] as String? ?? '',
    quarantineUntil: json['quarantineUntil'] as String?,
    documents: (json['documents'] as List<dynamic>? ?? [])
        .map((e) => BirdDocument.fromJson(e as Map<String, dynamic>))
        .toList(),
    health: (json['health'] as List<dynamic>? ?? [])
        .map((e) => HealthEntry.fromJson(e as Map<String, dynamic>))
        .toList(),
    cession: json['cession'] == null
        ? null
        : Cession.fromJson(json['cession'] as Map<String, dynamic>),
  );

  Map<String, dynamic> toJson() => {
    'ring': ring,
    'sci': sci,
    'mutation': mutation,
    'sex': sex,
    'born': born,
    'bornEstimated': bornEstimated,
    'origin': origin,
    'status': status,
    'fatherRing': fatherRing,
    'motherRing': motherRing,
    'ringType': ringType,
    'ringDiameter': ringDiameter,
    'location': location,
    'photoPath': photoPath,
    'notes': notes,
    'quarantineUntil': quarantineUntil,
    'documents': documents.map((e) => e.toJson()).toList(),
    'health': health.map((e) => e.toJson()).toList(),
    'cession': cession?.toJson(),
  };
}
