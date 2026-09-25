/// Relevé des conditions d'une volière : température, humidité, éclairage.
class EnvReading {
  final String id;
  String date; // ISO 8601 date et heure, ex. 2026-09-25T08:30:00
  String location; // nom de la volière
  double? temperature; // °C
  double? humidity; // %
  double? lightHours; // durée d'éclairage sur la journée, en heures
  String notes;

  EnvReading({
    required this.id,
    required this.date,
    required this.location,
    this.temperature,
    this.humidity,
    this.lightHours,
    this.notes = '',
  });

  factory EnvReading.fromJson(Map<String, dynamic> json) => EnvReading(
    id: json['id'] as String,
    date: json['date'] as String,
    location: json['location'] as String? ?? '',
    temperature: (json['temperature'] as num?)?.toDouble(),
    humidity: (json['humidity'] as num?)?.toDouble(),
    lightHours: (json['lightHours'] as num?)?.toDouble(),
    notes: json['notes'] as String? ?? '',
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'date': date,
    'location': location,
    'temperature': temperature,
    'humidity': humidity,
    'lightHours': lightHours,
    'notes': notes,
  };
}

/// Relevé de l'incubateur pendant une incubation.
class IncubatorReading {
  final String id;
  String date; // ISO 8601 date et heure
  double? temperature; // °C
  double? humidity; // %
  int? turns; // nombre de retournements depuis le relevé précédent
  String notes;

  IncubatorReading({
    required this.id,
    required this.date,
    this.temperature,
    this.humidity,
    this.turns,
    this.notes = '',
  });

  factory IncubatorReading.fromJson(Map<String, dynamic> json) => IncubatorReading(
    id: json['id'] as String,
    date: json['date'] as String,
    temperature: (json['temperature'] as num?)?.toDouble(),
    humidity: (json['humidity'] as num?)?.toDouble(),
    turns: json['turns'] as int?,
    notes: json['notes'] as String? ?? '',
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'date': date,
    'temperature': temperature,
    'humidity': humidity,
    'turns': turns,
    'notes': notes,
  };
}

/// Une incubation d'œufs en couveuse, avec ses consignes et ses relevés.
///
/// Les plages cibles (température, humidité) sont saisies par l'éleveur :
/// l'appli ne propose volontairement aucune valeur par défaut, car elles
/// dépendent de l'espèce et du matériel.
class Incubation {
  final String id;
  String label; // ex. « Couveuse 1 »
  String? coupleId;
  String sci; // espèce ('' si non précisée)
  int eggs;
  String startDate; // ISO 8601 (date de mise en incubation)
  int incubationDays; // durée prévue
  double? targetTempMin;
  double? targetTempMax;
  double? targetHumMin;
  double? targetHumMax;
  String status; // 'En cours' | 'Terminée'
  int hatched;
  String notes;
  List<IncubatorReading> readings;

  Incubation({
    required this.id,
    required this.label,
    this.coupleId,
    this.sci = '',
    this.eggs = 0,
    required this.startDate,
    required this.incubationDays,
    this.targetTempMin,
    this.targetTempMax,
    this.targetHumMin,
    this.targetHumMax,
    this.status = 'En cours',
    this.hatched = 0,
    this.notes = '',
    List<IncubatorReading>? readings,
  }) : readings = readings ?? [];

  bool get isActive => status == 'En cours';

  DateTime get start => DateTime.parse(startDate);

  DateTime get expectedHatch => start.add(Duration(days: incubationDays));

  /// Jour d'incubation en cours (jour 1 = jour de la mise en incubation).
  int get dayNumber {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final s = DateTime(start.year, start.month, start.day);
    return today.difference(s).inDays + 1;
  }

  List<IncubatorReading> get readingsSortedAsc =>
      List.of(readings)..sort((a, b) => a.date.compareTo(b.date));

  /// Vrai si la valeur sort de la plage cible (quand une plage est définie).
  bool tempOutOfRange(double? t) =>
      t != null &&
      ((targetTempMin != null && t < targetTempMin!) ||
          (targetTempMax != null && t > targetTempMax!));

  bool humOutOfRange(double? h) =>
      h != null &&
      ((targetHumMin != null && h < targetHumMin!) ||
          (targetHumMax != null && h > targetHumMax!));

  factory Incubation.fromJson(Map<String, dynamic> json) => Incubation(
    id: json['id'] as String,
    label: json['label'] as String? ?? 'Couveuse',
    coupleId: json['coupleId'] as String?,
    sci: json['sci'] as String? ?? '',
    eggs: json['eggs'] as int? ?? 0,
    startDate: json['startDate'] as String,
    incubationDays: json['incubationDays'] as int? ?? 0,
    targetTempMin: (json['targetTempMin'] as num?)?.toDouble(),
    targetTempMax: (json['targetTempMax'] as num?)?.toDouble(),
    targetHumMin: (json['targetHumMin'] as num?)?.toDouble(),
    targetHumMax: (json['targetHumMax'] as num?)?.toDouble(),
    status: json['status'] as String? ?? 'En cours',
    hatched: json['hatched'] as int? ?? 0,
    notes: json['notes'] as String? ?? '',
    readings: (json['readings'] as List<dynamic>? ?? [])
        .map((e) => IncubatorReading.fromJson(e as Map<String, dynamic>))
        .toList(),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'label': label,
    'coupleId': coupleId,
    'sci': sci,
    'eggs': eggs,
    'startDate': startDate,
    'incubationDays': incubationDays,
    'targetTempMin': targetTempMin,
    'targetTempMax': targetTempMax,
    'targetHumMin': targetHumMin,
    'targetHumMax': targetHumMax,
    'status': status,
    'hatched': hatched,
    'notes': notes,
    'readings': readings.map((e) => e.toJson()).toList(),
  };
}
