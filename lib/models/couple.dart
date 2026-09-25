/// Les étapes de la reproduction, dans l'ordre.
const List<String> kCoupleStages = [
  'Formation',
  'Accouplement',
  'Ponte',
  'Incubation',
  'Éclosion',
  'Sevrage',
];

/// Un couple reproducteur et le suivi de sa reproduction.
class Couple {
  final String id; // ex. "C-04"
  String? maleRing;
  String? maleLabel; // libellé de repli si l'oiseau n'est pas dans l'élevage
  String? femaleRing;
  String? femaleLabel;
  String sci; // espèce (pour affichage)
  int stage; // 0..5, voir kCoupleStages
  int eggs;
  String? incubationDate; // ISO 8601
  int chicks;
  List<String> history; // résumés des pontes précédentes

  Couple({
    required this.id,
    this.maleRing,
    this.maleLabel,
    this.femaleRing,
    this.femaleLabel,
    required this.sci,
    this.stage = 0,
    this.eggs = 0,
    this.incubationDate,
    this.chicks = 0,
    List<String>? history,
  }) : history = history ?? [];

  String get stageName => kCoupleStages[stage.clamp(0, 5)];

  factory Couple.fromJson(Map<String, dynamic> json) => Couple(
    id: json['id'] as String,
    maleRing: json['maleRing'] as String?,
    maleLabel: json['maleLabel'] as String?,
    femaleRing: json['femaleRing'] as String?,
    femaleLabel: json['femaleLabel'] as String?,
    sci: json['sci'] as String? ?? '',
    stage: json['stage'] as int? ?? 0,
    eggs: json['eggs'] as int? ?? 0,
    incubationDate: json['incubationDate'] as String?,
    chicks: json['chicks'] as int? ?? 0,
    history: (json['history'] as List<dynamic>? ?? [])
        .map((e) => e as String)
        .toList(),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'maleRing': maleRing,
    'maleLabel': maleLabel,
    'femaleRing': femaleRing,
    'femaleLabel': femaleLabel,
    'sci': sci,
    'stage': stage,
    'eggs': eggs,
    'incubationDate': incubationDate,
    'chicks': chicks,
    'history': history,
  };
}
