import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';

import '../logic/inbreeding.dart';
import '../models/agenda_event.dart';
import '../models/app_notification.dart';
import '../models/bird.dart';
import '../models/bird_document.dart';
import '../models/breeding.dart';
import '../models/couple.dart';
import '../models/settings.dart';
import '../models/species.dart';
import '../models/parrot_fact.dart';

/// Le résultat d'un contrôle de compatibilité entre deux oiseaux avant de
/// former un couple.
class CompatInfo {
  final List<String> blocking;
  final List<String> warnings;
  /// Consanguinité attendue des jeunes du couple (0 à 1).
  final double offspringInbreeding;
  const CompatInfo({
    this.blocking = const [],
    this.warnings = const [],
    this.offspringInbreeding = 0,
  });
  bool get hasBlocking => blocking.isNotEmpty;
  bool get hasWarnings => warnings.isNotEmpty;
}

/// Un événement d'agenda, qu'il soit automatique (fin de quarantaine) ou
/// saisi par l'éleveur.
class AgendaItem {
  final String date;
  final String icon;
  final String title;
  final String subtitle;
  final bool auto;
  final String? deleteId; // id de l'AgendaEvent si supprimable
  final String? birdRing; // pour naviguer vers la fiche si auto
  final String? incubationId; // pour naviguer vers l'incubation si auto

  AgendaItem({
    required this.date,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.auto,
    this.deleteId,
    this.birdRing,
    this.incubationId,
  });
}

/// État central de l'application : toutes les données de l'élevage, chargées
/// et sauvegardées automatiquement dans un fichier local sur l'appareil.
/// Chaque écran écoute cet objet (voir `AnimatedBuilder` / `ListenableBuilder`
/// dans les widgets) et se redessine dès qu'une donnée change.
class AppState extends ChangeNotifier {
  List<Species> species = [];
  List<Bird> birds = [];
  List<Couple> couples = [];
  List<AgendaEvent> events = [];
  List<AppNotification> notifications = [];
  Settings settings = Settings();
  List<EnvReading> envReadings = [];
  List<Incubation> incubations = [];
  List<ParrotFact> facts = [];
  int _seq = 1000;

  bool _loaded = false;
  bool get loaded => _loaded;

  /// Informations « Le saviez-vous ? » concernant une espèce.
  List<ParrotFact> factsFor(String sci) => facts.where((f) => f.sci == sci).toList();

  Species? speciesBySci(String sci) {
    for (final s in species) {
      if (s.sci == sci) return s;
    }
    return null;
  }

  Bird? findBird(String? ring) {
    if (ring == null) return null;
    for (final b in birds) {
      if (b.ring == ring) return b;
    }
    return null;
  }

  Couple? findCouple(String id) {
    for (final c in couples) {
      if (c.id == id) return c;
    }
    return null;
  }

  String nextId() => (_seq++).toString();

  // ---------------------------------------------------------------------
  // Chargement / sauvegarde
  // ---------------------------------------------------------------------

  Future<File> _dataFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/psittacidocs_data.json');
  }

  Future<void> load() async {
    final raw = await rootBundle.loadString('assets/data/species.json');
    final list = jsonDecode(raw) as List<dynamic>;
    species = list
        .map((e) => Species.fromJson(e as Map<String, dynamic>))
        .toList();

    try {
      final factsRaw = await rootBundle.loadString('assets/data/parrot_facts.json');
      facts = (jsonDecode(factsRaw) as List<dynamic>)
          .map((e) => ParrotFact.fromJson(e as Map<String, dynamic>))
          .where((f) => f.isValid)
          .toList();
    } catch (_) {
      facts = [];
    }

    final file = await _dataFile();
    if (await file.exists()) {
      try {
        final data = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
        birds = (data['birds'] as List<dynamic>? ?? [])
            .map((e) => Bird.fromJson(e as Map<String, dynamic>))
            .toList();
        couples = (data['couples'] as List<dynamic>? ?? [])
            .map((e) => Couple.fromJson(e as Map<String, dynamic>))
            .toList();
        events = (data['events'] as List<dynamic>? ?? [])
            .map((e) => AgendaEvent.fromJson(e as Map<String, dynamic>))
            .toList();
        notifications = (data['notifications'] as List<dynamic>? ?? [])
            .map((e) => AppNotification.fromJson(e as Map<String, dynamic>))
            .toList();
        settings = data['settings'] == null
            ? Settings()
            : Settings.fromJson(data['settings'] as Map<String, dynamic>);
        envReadings = (data['envReadings'] as List<dynamic>? ?? [])
            .map((e) => EnvReading.fromJson(e as Map<String, dynamic>))
            .toList();
        incubations = (data['incubations'] as List<dynamic>? ?? [])
            .map((e) => Incubation.fromJson(e as Map<String, dynamic>))
            .toList();
        _seq = data['seq'] as int? ?? 1000;
      } catch (_) {
        _seedDemoData();
      }
    } else {
      _seedDemoData();
    }
    _loaded = true;
    notifyListeners();
  }

  Future<void> _save() async {
    final file = await _dataFile();
    final data = {
      'birds': birds.map((e) => e.toJson()).toList(),
      'couples': couples.map((e) => e.toJson()).toList(),
      'events': events.map((e) => e.toJson()).toList(),
      'notifications': notifications.map((e) => e.toJson()).toList(),
      'settings': settings.toJson(),
      'envReadings': envReadings.map((e) => e.toJson()).toList(),
      'incubations': incubations.map((e) => e.toJson()).toList(),
      'seq': _seq,
    };
    await file.writeAsString(jsonEncode(data));
  }

  /// Sauvegarde puis notifie l'interface. À appeler après chaque
  /// modification de donnée.
  Future<void> commit() async {
    notifyListeners();
    await _save();
  }

  void _seedDemoData() {
    birds = [
      Bird(
        ring: 'B-24-0132',
        sci: 'Pionus chalcopterus',
        mutation: 'Ancestral',
        sex: 'F',
        born: '2024-03-12',
        origin: 'Né à l’élevage',
        status: 'Reproductrice',
        fatherRing: 'B-21-0045',
        motherRing: 'B-20-0017',
        documents: [
          BirdDocument(type: 'Certificat de cession', fileName: 'certificat_B-24-0132.pdf'),
          BirdDocument(type: 'Facture', fileName: 'facture_achat.pdf'),
          BirdDocument(type: 'Certificat de baguage', fileName: 'baguage_B-24-0132.pdf'),
        ],
        health: [
          HealthEntry(id: 'h1', date: '2024-03-20', type: 'Pesée', weight: 58),
          HealthEntry(id: 'h2', date: '2024-05-15', type: 'Pesée', weight: 180),
          HealthEntry(id: 'h3', date: '2024-09-10', type: 'Pesée', weight: 238),
          HealthEntry(id: 'h4', date: '2025-02-02', type: 'Visite vétérinaire', notes: 'Contrôle annuel, RAS.'),
          HealthEntry(id: 'h5', date: '2025-06-18', type: 'Pesée', weight: 245),
        ],
      ),
      Bird(
        ring: 'B-21-0045',
        sci: 'Pionus chalcopterus',
        mutation: 'Ancestral',
        sex: 'M',
        born: '2021-05-04',
        origin: 'Acheté',
        status: 'Reproducteur',
      ),
      Bird(
        ring: 'B-20-0017',
        sci: 'Pionus chalcopterus',
        mutation: 'Ancestral',
        sex: 'F',
        born: '2020-02-11',
        origin: 'Acheté',
        status: 'Reproductrice',
      ),
      Bird(
        ring: 'B-23-0078',
        sci: 'Pionus maximiliani',
        mutation: 'Ancestral',
        sex: 'F',
        born: '2023-06-02',
        origin: 'Né à l’élevage',
        status: 'Reproductrice',
      ),
      Bird(
        ring: 'B-25-0211',
        sci: 'Psittacus erithacus',
        mutation: 'Ancestral',
        sex: 'M',
        origin: 'Acheté',
        status: 'En quarantaine',
        quarantineUntil: DateTime.now()
            .add(const Duration(days: 8))
            .toIso8601String()
            .substring(0, 10),
      ),
      Bird(
        ring: 'B-22-0019',
        sci: 'Eclectus roratus',
        mutation: 'Ancestral',
        sex: 'F',
        born: '2022-08-09',
        origin: 'Acheté',
        status: 'Reproductrice',
      ),
    ];
    couples = [
      Couple(
        id: 'C-04',
        maleRing: 'B-21-0045',
        femaleRing: 'B-20-0017',
        sci: 'Pionus chalcopterus',
        stage: 3,
        eggs: 3,
        incubationDate: '2026-09-05',
      ),
      Couple(
        id: 'C-02',
        maleLabel: 'B-19-0032',
        femaleRing: 'B-23-0078',
        sci: 'Pionus maximiliani',
        stage: 5,
        eggs: 2,
        chicks: 2,
        history: ['2 œufs · 2 poussins sevrés le 02/09/2026'],
      ),
      Couple(
        id: 'C-07',
        maleLabel: 'B-24-0301',
        femaleRing: 'B-22-0019',
        sci: 'Eclectus roratus',
        stage: 0,
      ),
    ];
    notifications = [
      AppNotification(
        id: 1,
        kind: 'eclosion',
        icon: 'egg',
        title: 'Éclosion prévue',
        subtitle: 'Couple C-04, pione noire',
        when: 'Dans 2 jours',
        urgent: true,
      ),
      AppNotification(
        id: 2,
        kind: 'sevrage',
        icon: 'leaf',
        title: 'Sevrage à prévoir',
        subtitle: '2 poussins, pione de Maximilien',
        when: 'Dans 5 jours',
      ),
      AppNotification(
        id: 3,
        kind: 'quarantaine',
        icon: 'shield',
        title: 'Fin de quarantaine',
        subtitle: 'B-25-0211, perroquet jaco',
        when: 'Dans 8 jours',
      ),
      AppNotification(
        id: 4,
        kind: 'sevrage',
        icon: 'egg',
        title: 'Ponte enregistrée',
        subtitle: 'Couple C-02, pione de Maximilien',
        when: 'Il y a 3 jours',
        read: true,
      ),
    ];
    _seq = 100;
  }

  // ---------------------------------------------------------------------
  // Oiseaux
  // ---------------------------------------------------------------------

  bool ringExists(String ring, {Bird? excluding}) => birds.any(
    (b) => b != excluding && b.ring.toLowerCase() == ring.toLowerCase(),
  );

  Future<void> addBird(Bird bird) async {
    birds.insert(0, bird);
    pushNotification(
      kind: 'action',
      icon: 'leaf',
      title: 'Nouvel oiseau ajouté',
      subtitle: '${bird.ring} · ${speciesBySci(bird.sci)?.label ?? bird.sci}',
      when: 'À l’instant',
      navTarget: 'fiche',
      navId: bird.ring,
      skipCommit: true,
    );
    await commit();
  }

  /// Renomme un oiseau (numéro de bague) et met à jour toutes les
  /// références (parents des autres oiseaux, couples).
  Future<void> renameBirdRing(Bird bird, String newRing) async {
    if (newRing == bird.ring) return;
    for (final b in birds) {
      if (b.fatherRing == bird.ring) b.fatherRing = newRing;
      if (b.motherRing == bird.ring) b.motherRing = newRing;
    }
    for (final c in couples) {
      if (c.maleRing == bird.ring) c.maleRing = newRing;
      if (c.femaleRing == bird.ring) c.femaleRing = newRing;
    }
    bird.ring = newRing;
  }

  Future<void> updateBird(Bird bird) async => commit();

  Future<void> deleteBird(Bird bird) async {
    birds.removeWhere((b) => b.ring == bird.ring);
    await commit();
  }

  List<Bird> childrenOf(String ring) =>
      birds.where((b) => b.fatherRing == ring || b.motherRing == ring).toList();

  // ---------------------------------------------------------------------
  // Couples
  // ---------------------------------------------------------------------

  Set<String> get pairedRings =>
      couples.expand((c) => [c.maleRing, c.femaleRing]).whereType<String>().toSet();

  // ---------------------------------------------------------------------
  // Consanguinité
  // ---------------------------------------------------------------------

  /// Calculateur construit sur la généalogie actuelle. Les parents sont
  /// identifiés par leur bague, même s'ils ne sont pas enregistrés dans
  /// l'appli : deux oiseaux ayant la même bague de père sont bien reconnus
  /// comme demi-frères.
  InbreedingCalculator _inbreedingCalculator() => InbreedingCalculator(
    sireOf: (ring) => findBird(ring)?.fatherRing,
    damOf: (ring) => findBird(ring)?.motherRing,
  );

  /// Consanguinité d'un oiseau (0 à 1), calculée sur ses ancêtres connus.
  double inbreedingOf(Bird bird) =>
      _inbreedingCalculator().kinship(bird.fatherRing, bird.motherRing);

  /// Consanguinité attendue des jeunes d'un couple (0 à 1).
  double offspringInbreeding(String? maleRing, String? femaleRing) =>
      _inbreedingCalculator().kinship(maleRing, femaleRing);

  CompatInfo compatInfo(String? maleRing, String? femaleRing) {
    if (maleRing == null || femaleRing == null) return const CompatInfo();
    final m = findBird(maleRing);
    final f = findBird(femaleRing);
    if (m == null || f == null) return const CompatInfo();
    final blocking = <String>[];
    final warnings = <String>[];

    if (m.isCeded) {
      blocking.add('$maleRing a déjà été cédé et ne fait plus partie de l’élevage.');
    }
    if (f.isCeded) {
      blocking.add('$femaleRing a déjà été cédé et ne fait plus partie de l’élevage.');
    }
    if (couples.any((c) => c.maleRing == maleRing || c.femaleRing == maleRing)) {
      blocking.add('$maleRing fait déjà partie d’un autre couple.');
    }
    if (couples.any((c) => c.maleRing == femaleRing || c.femaleRing == femaleRing)) {
      blocking.add('$femaleRing fait déjà partie d’un autre couple.');
    }

    final directRelation = m.fatherRing == femaleRing ||
        m.motherRing == femaleRing ||
        f.fatherRing == maleRing ||
        f.motherRing == maleRing;
    if (directRelation) {
      blocking.add('L’un des oiseaux est un parent direct de l’autre.');
    }

    final coi = offspringInbreeding(maleRing, femaleRing);
    if (!directRelation && coi >= kInbreedingWarningThreshold) {
      warnings.add(
        'Consanguinité des futurs jeunes : ${formatPercent(coi)}. ${inbreedingLevel(coi)}.',
      );
    }

    if (m.sci != f.sci) {
      final ml = speciesBySci(m.sci)?.label ?? m.sci;
      final fl = speciesBySci(f.sci)?.label ?? f.sci;
      warnings.add('Espèces différentes : $ml et $fl.');
    }

    return CompatInfo(blocking: blocking, warnings: warnings, offspringInbreeding: coi);
  }

  Future<Couple> formCouple(String maleRing, String femaleRing) async {
    final f = findBird(femaleRing);
    var n = couples.length + 1;
    var id = 'C-${n.toString().padLeft(2, '0')}';
    while (couples.any((c) => c.id == id)) {
      n++;
      id = 'C-${n.toString().padLeft(2, '0')}';
    }
    final couple = Couple(id: id, maleRing: maleRing, femaleRing: femaleRing, sci: f?.sci ?? '');
    couples.insert(0, couple);
    final mLabel = findBird(maleRing)?.ring ?? maleRing;
    final fLabel = findBird(femaleRing)?.ring ?? femaleRing;
    pushNotification(
      kind: 'action',
      icon: 'egg',
      title: 'Couple formé',
      subtitle: '$id · $mLabel × $fLabel',
      when: 'À l’instant',
      navTarget: 'couple',
      navId: id,
      skipCommit: true,
    );
    await commit();
    return couple;
  }

  Future<void> advanceCouple(Couple couple) async {
    if (couple.stage < 5) {
      couple.stage++;
      if (couple.stage == 3 && couple.incubationDate == null) {
        couple.incubationDate = DateTime.now().toIso8601String().substring(0, 10);
      }
    } else {
      couple.history.insert(
        0,
        '${couple.eggs} œuf${couple.eggs > 1 ? 's' : ''} · '
        '${couple.chicks} poussin${couple.chicks > 1 ? 's' : ''} sevrés',
      );
      couple.stage = 0;
      couple.eggs = 0;
      couple.chicks = 0;
      couple.incubationDate = null;
    }
    await commit();
  }

  // ---------------------------------------------------------------------
  // Documents
  // ---------------------------------------------------------------------

  List<MapEntry<Bird, BirdDocument>> get allDocuments => [
    for (final b in birds)
      for (final d in b.documents) MapEntry(b, d),
  ];

  Future<void> addDocument(Bird bird, BirdDocument doc) async {
    bird.documents.add(doc);
    await commit();
  }

  // ---------------------------------------------------------------------
  // Cessions
  // ---------------------------------------------------------------------

  List<Bird> get cededBirds => birds.where((b) => b.isCeded).toList();

  Future<void> registerCession(Bird bird, Cession cession) async {
    bird.cession = cession;
    bird.status = 'Cédé';
    pushNotification(
      kind: 'action',
      icon: 'out',
      title: 'Cession enregistrée',
      subtitle: '${bird.ring} → ${cession.buyer}',
      when: 'À l’instant',
      navTarget: 'cessions',
      skipCommit: true,
    );
    await commit();
  }

  // ---------------------------------------------------------------------
  // Agenda
  // ---------------------------------------------------------------------

  String relativeLabel(String iso) {
    final d = DateTime.parse(iso);
    final today = DateTime.now();
    final t = DateTime(today.year, today.month, today.day);
    final diff = DateTime(d.year, d.month, d.day).difference(t).inDays;
    if (diff == 0) return "Aujourd'hui";
    if (diff == 1) return 'Demain';
    if (diff == -1) return 'Hier';
    if (diff > 1) return 'Dans $diff jours';
    return 'Il y a ${-diff} jours';
  }

  List<AgendaItem> agendaItems() {
    final items = <AgendaItem>[];
    for (final b in birds) {
      if (b.isQuarantined && b.quarantineUntil != null) {
        items.add(AgendaItem(
          date: b.quarantineUntil!,
          icon: 'shield',
          title: 'Fin de quarantaine',
          subtitle: '${b.ring} · ${speciesBySci(b.sci)?.label ?? b.sci}',
          auto: true,
          birdRing: b.ring,
        ));
      }
    }
    for (final inc in incubations.where((i) => i.isActive && i.incubationDays > 0)) {
      items.add(AgendaItem(
        date: inc.expectedHatch.toIso8601String().substring(0, 10),
        icon: 'egg',
        title: 'Éclosion prévue',
        subtitle: '${inc.label}${inc.eggs > 0 ? ' · ${inc.eggs} œuf${inc.eggs > 1 ? 's' : ''}' : ''}',
        auto: true,
        incubationId: inc.id,
      ));
    }
    for (final e in events) {
      items.add(AgendaItem(
        date: e.date,
        icon: kEventTypeIcons[e.type] ?? 'doc',
        title: e.type,
        subtitle: e.notes.isEmpty ? e.title : '${e.title} · ${e.notes}',
        auto: false,
        deleteId: e.id,
      ));
    }
    items.sort((a, b) => a.date.compareTo(b.date));
    return items;
  }

  Future<void> addEvent(AgendaEvent event) async {
    events.add(event);
    await commit();
  }

  Future<void> deleteEvent(String id) async {
    events.removeWhere((e) => e.id == id);
    await commit();
  }

  // ---------------------------------------------------------------------
  // Santé
  // ---------------------------------------------------------------------

  Future<void> addHealthEntry(Bird bird, HealthEntry entry) async {
    bird.health.add(entry);
    await commit();
  }

  // ---------------------------------------------------------------------
  // Notifications
  // ---------------------------------------------------------------------

  List<AppNotification> get visibleNotifications =>
      notifications.where((n) => n.kind == 'action' || settings.reminderFor(n.kind)).toList();

  int get unreadCount => visibleNotifications.where((n) => !n.read).length;

  void pushNotification({
    required String kind,
    required String icon,
    required String title,
    required String subtitle,
    required String when,
    bool urgent = false,
    String? navTarget,
    String? navId,
    bool skipCommit = false,
  }) {
    notifications.insert(
      0,
      AppNotification(
        id: _seq++,
        kind: kind,
        icon: icon,
        title: title,
        subtitle: subtitle,
        when: when,
        urgent: urgent,
        navTarget: navTarget,
        navId: navId,
      ),
    );
    if (!skipCommit) commit();
  }

  Future<void> markNotificationRead(AppNotification n) async {
    n.read = true;
    await commit();
  }

  Future<void> markAllNotificationsRead() async {
    for (final n in visibleNotifications) {
      n.read = true;
    }
    await commit();
  }

  // ---------------------------------------------------------------------
  // Paramètres d'élevage (volières) et incubation
  // ---------------------------------------------------------------------

  Future<void> addEnvReading(EnvReading reading) async {
    envReadings.add(reading);
    await commit();
  }

  Future<void> deleteEnvReading(String id) async {
    envReadings.removeWhere((r) => r.id == id);
    await commit();
  }

  Incubation? findIncubation(String id) {
    for (final i in incubations) {
      if (i.id == id) return i;
    }
    return null;
  }

  Future<void> addIncubation(Incubation incubation) async {
    incubations.insert(0, incubation);
    await commit();
  }

  Future<void> deleteIncubation(String id) async {
    incubations.removeWhere((i) => i.id == id);
    await commit();
  }

  Future<void> addIncubatorReading(Incubation incubation, IncubatorReading reading) async {
    incubation.readings.add(reading);
    await commit();
  }

  Future<void> finishIncubation(Incubation incubation, int hatched) async {
    incubation.status = 'Terminée';
    incubation.hatched = hatched;
    await commit();
  }

  // ---------------------------------------------------------------------
  // Paramètres
  // ---------------------------------------------------------------------

  Future<void> saveSettings() async => commit();

  Future<void> addVoliere(String name) async {
    if (name.trim().isEmpty || settings.volieres.contains(name.trim())) return;
    settings.volieres.add(name.trim());
    await commit();
  }

  Future<void> removeVoliere(int index) async {
    settings.volieres.removeAt(index);
    await commit();
  }
}
