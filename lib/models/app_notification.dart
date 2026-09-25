/// Une notification affichée sous la cloche de l'appli.
///
/// [kind] vaut 'action' pour une confirmation immédiate (oiseau ajouté,
/// couple formé...), ou l'une des clés de rappel réglées dans les Paramètres
/// ('eclosion', 'sevrage', 'quarantaine') pour un rappel qui peut être
/// désactivé par l'éleveur.
class AppNotification {
  final int id;
  final String kind;
  final String icon;
  final String title;
  final String subtitle;
  final String when; // libellé affiché, ex. "Dans 2 jours"
  bool read;
  final bool urgent;
  final String? navTarget; // 'fiche' | 'couple' | 'cessions'
  final String? navId;

  AppNotification({
    required this.id,
    required this.kind,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.when,
    this.read = false,
    this.urgent = false,
    this.navTarget,
    this.navId,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) =>
      AppNotification(
        id: json['id'] as int,
        kind: json['kind'] as String,
        icon: json['icon'] as String,
        title: json['title'] as String,
        subtitle: json['subtitle'] as String,
        when: json['when'] as String,
        read: json['read'] as bool? ?? false,
        urgent: json['urgent'] as bool? ?? false,
        navTarget: json['navTarget'] as String?,
        navId: json['navId'] as String?,
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'kind': kind,
    'icon': icon,
    'title': title,
    'subtitle': subtitle,
    'when': when,
    'read': read,
    'urgent': urgent,
    'navTarget': navTarget,
    'navId': navId,
  };
}
