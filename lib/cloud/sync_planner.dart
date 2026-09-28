/// Ce que la synchronisation doit faire, selon l'état de cet appareil et celui
/// de la sauvegarde en ligne.
enum SyncAction {
  /// Rien à faire : tout est déjà à jour.
  nothing,

  /// Envoyer les données de cet appareil vers le serveur.
  push,

  /// Récupérer les données du serveur sur cet appareil.
  pull,

  /// Les deux ont changé chacun de leur côté : l'utilisateur doit choisir.
  conflict,
}

/// Décide de l'action à mener. Fonction pure, sans accès au réseau ni au disque.
///
/// - [remoteVersion] : numéro de version de la sauvegarde en ligne, ou `null`
///   s'il n'y en a aucune.
/// - [lastSyncedVersion] : dernière version que CET appareil a envoyée ou
///   reçue, ou `null` s'il n'a jamais été synchronisé avec ce compte.
/// - [dirty] : cet appareil a des modifications pas encore envoyées.
/// - [everModified] : l'utilisateur a déjà modifié des données sur cet appareil
///   (sinon il ne contient que les données de démonstration).
SyncAction planSync({
  required int? remoteVersion,
  required int? lastSyncedVersion,
  required bool dirty,
  required bool everModified,
}) {
  if (remoteVersion == null) {
    // Rien en ligne : on n'envoie que de vraies données, jamais la démonstration.
    return everModified ? SyncAction.push : SyncAction.nothing;
  }
  if (lastSyncedVersion == remoteVersion) {
    return dirty ? SyncAction.push : SyncAction.nothing;
  }
  // La version en ligne n'est pas celle que cet appareil connaît.
  if (!dirty) return SyncAction.pull;
  return SyncAction.conflict;
}
