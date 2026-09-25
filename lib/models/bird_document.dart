/// Un justificatif attaché à un oiseau (certificat, facture, document CITES...).
class BirdDocument {
  String type;
  String fileName;

  BirdDocument({required this.type, required this.fileName});

  factory BirdDocument.fromJson(Map<String, dynamic> json) => BirdDocument(
    type: json['type'] as String,
    fileName: json['fileName'] as String,
  );

  Map<String, dynamic> toJson() => {'type': type, 'fileName': fileName};
}

/// Une entrée du journal de santé d'un oiseau : pesée, traitement, visite
/// vétérinaire, vaccination...
class HealthEntry {
  final String id;
  String date; // ISO 8601 (yyyy-MM-dd)
  String type; // 'Pesée' | 'Traitement' | 'Visite vétérinaire' | 'Vaccination' | 'Autre'
  double? weight; // grammes, uniquement pour une pesée
  String notes;

  HealthEntry({
    required this.id,
    required this.date,
    required this.type,
    this.weight,
    this.notes = '',
  });

  factory HealthEntry.fromJson(Map<String, dynamic> json) => HealthEntry(
    id: json['id'] as String,
    date: json['date'] as String,
    type: json['type'] as String,
    weight: (json['weight'] as num?)?.toDouble(),
    notes: json['notes'] as String? ?? '',
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'date': date,
    'type': type,
    'weight': weight,
    'notes': notes,
  };
}

/// La cession d'un oiseau à un nouveau propriétaire.
class Cession {
  String buyer;
  String date; // ISO 8601
  String price;
  String contact;
  String notes;

  Cession({
    required this.buyer,
    required this.date,
    this.price = '',
    this.contact = '',
    this.notes = '',
  });

  factory Cession.fromJson(Map<String, dynamic> json) => Cession(
    buyer: json['buyer'] as String,
    date: json['date'] as String? ?? '',
    price: json['price'] as String? ?? '',
    contact: json['contact'] as String? ?? '',
    notes: json['notes'] as String? ?? '',
  );

  Map<String, dynamic> toJson() => {
    'buyer': buyer,
    'date': date,
    'price': price,
    'contact': contact,
    'notes': notes,
  };
}
