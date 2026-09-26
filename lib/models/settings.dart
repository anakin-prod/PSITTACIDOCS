/// Les paramètres de l'élevage : nom, volières, rappels activés.
class Settings {
  String elevageName;
  List<String> volieres;
  bool remindEclosion;
  bool remindSevrage;
  bool remindQuarantaine;
  bool remindVeto;
  bool remindNourrissage;

  Settings({
    this.elevageName = '',
    List<String>? volieres,
    this.remindEclosion = true,
    this.remindSevrage = true,
    this.remindQuarantaine = true,
    this.remindVeto = true,
    this.remindNourrissage = false,
  }) : volieres =
           volieres ??
           ['Volière 1', 'Volière 2', 'Volière 3', 'Nurserie', 'Quarantaine'];

  bool reminderFor(String kind) {
    switch (kind) {
      case 'eclosion':
        return remindEclosion;
      case 'sevrage':
        return remindSevrage;
      case 'quarantaine':
        return remindQuarantaine;
      case 'veto':
        return remindVeto;
      case 'nourrissage':
        return remindNourrissage;
      default:
        return true;
    }
  }

  factory Settings.fromJson(Map<String, dynamic> json) => Settings(
    elevageName: json['elevageName'] as String? ?? '',
    volieres: (json['volieres'] as List<dynamic>?)
        ?.map((e) => e as String)
        .toList(),
    remindEclosion: json['remindEclosion'] as bool? ?? true,
    remindSevrage: json['remindSevrage'] as bool? ?? true,
    remindQuarantaine: json['remindQuarantaine'] as bool? ?? true,
    remindVeto: json['remindVeto'] as bool? ?? true,
    remindNourrissage: json['remindNourrissage'] as bool? ?? false,
  );

  Map<String, dynamic> toJson() => {
    'elevageName': elevageName,
    'volieres': volieres,
    'remindEclosion': remindEclosion,
    'remindSevrage': remindSevrage,
    'remindQuarantaine': remindQuarantaine,
    'remindVeto': remindVeto,
    'remindNourrissage': remindNourrissage,
  };
}
