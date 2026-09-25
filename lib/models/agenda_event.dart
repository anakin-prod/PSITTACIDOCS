/// Les types d'événement que l'éleveur peut ajouter à l'agenda.
const Map<String, String> kEventTypeIcons = {
  'Visite vétérinaire': 'steth',
  'Pesée': 'scale',
  'Nourrissage': 'bowl',
  'Nettoyage': 'leaf',
  'Autre': 'doc',
};

/// Un événement personnalisé ajouté par l'éleveur à l'agenda.
class AgendaEvent {
  final String id;
  String title;
  String type;
  String date; // ISO 8601
  String notes;

  AgendaEvent({
    required this.id,
    required this.title,
    required this.type,
    required this.date,
    this.notes = '',
  });

  factory AgendaEvent.fromJson(Map<String, dynamic> json) => AgendaEvent(
    id: json['id'] as String,
    title: json['title'] as String,
    type: json['type'] as String,
    date: json['date'] as String,
    notes: json['notes'] as String? ?? '',
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'type': type,
    'date': date,
    'notes': notes,
  };
}
