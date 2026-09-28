import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:path_provider/path_provider.dart';

/// Mémoire de la synchronisation, enregistrée sur l'appareil (fichier séparé des
/// données de l'élevage).
class SyncState {
  /// Identifiant aléatoire de cet appareil.
  String deviceId;

  /// Compte auquel se rapporte [lastVersion].
  String? uid;

  /// Dernière version de la sauvegarde en ligne envoyée ou reçue par cet appareil.
  int? lastVersion;

  /// Des modifications n'ont pas encore été envoyées.
  bool dirty;

  /// L'utilisateur a déjà modifié des données sur cet appareil.
  bool everModified;

  DateTime? lastSyncAt;

  SyncState({
    required this.deviceId,
    this.uid,
    this.lastVersion,
    this.dirty = false,
    this.everModified = false,
    this.lastSyncAt,
  });

  factory SyncState.fresh() => SyncState(deviceId: _newDeviceId());

  factory SyncState.fromJson(Map<String, dynamic> json) => SyncState(
    deviceId: json['deviceId'] as String? ?? _newDeviceId(),
    uid: json['uid'] as String?,
    lastVersion: (json['lastVersion'] as num?)?.toInt(),
    dirty: json['dirty'] as bool? ?? false,
    everModified: json['everModified'] as bool? ?? false,
    lastSyncAt: json['lastSyncAt'] == null ? null : DateTime.tryParse(json['lastSyncAt'] as String),
  );

  Map<String, dynamic> toJson() => {
    'deviceId': deviceId,
    'uid': uid,
    'lastVersion': lastVersion,
    'dirty': dirty,
    'everModified': everModified,
    'lastSyncAt': lastSyncAt?.toIso8601String(),
  };

  static Future<File> _file() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/psittacidocs_sync.json');
  }

  /// Renvoie l'état enregistré, ou `null` s'il n'en existe pas encore.
  static Future<SyncState?> tryLoad() async {
    try {
      final f = await _file();
      if (!await f.exists()) return null;
      return SyncState.fromJson(jsonDecode(await f.readAsString()) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> save() async {
    try {
      final f = await _file();
      await f.writeAsString(jsonEncode(toJson()));
    } catch (_) {
      // Sans conséquence grave : l'état sera recalculé à la prochaine synchro.
    }
  }
}

String _newDeviceId() {
  final r = Random.secure();
  return List.generate(16, (_) => r.nextInt(16).toRadixString(16)).join();
}
