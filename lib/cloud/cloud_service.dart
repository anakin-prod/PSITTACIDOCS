import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../state/app_state.dart';
import 'sync_codec.dart';
import 'sync_planner.dart';
import 'sync_state.dart';

/// État de la synchronisation, tel qu'il est présenté à l'utilisateur.
enum SyncStatus {
  /// Firebase n'est pas configuré dans cette version de l'appli.
  unavailable,

  /// Aucun compte connecté.
  signedOut,

  /// Tout est synchronisé.
  idle,

  /// Des modifications attendent d'être envoyées.
  pending,

  /// Synchronisation en cours.
  syncing,

  /// Pas de connexion : les données restent enregistrées sur le téléphone.
  offline,

  /// Une erreur est survenue (voir [CloudService.errorMessage]).
  error,

  /// Cet appareil et le serveur ont chacun des modifications : l'utilisateur doit choisir.
  conflict,

  /// La sauvegarde en ligne est réservée aux abonnés Premium.
  premiumRequired,
}

/// Description d'un conflit, pour aider l'utilisateur à choisir.
class ConflictInfo {
  final int remoteBirds;
  final int remoteCouples;
  final DateTime? remoteUpdatedAt;
  final int localBirds;
  final int localCouples;

  const ConflictInfo({
    required this.remoteBirds,
    required this.remoteCouples,
    required this.remoteUpdatedAt,
    required this.localBirds,
    required this.localCouples,
  });
}

class _RemoteMeta {
  final int version;
  final int chunkCount;
  final int birds;
  final int couples;
  final DateTime? updatedAt;

  const _RemoteMeta({
    required this.version,
    required this.chunkCount,
    required this.birds,
    required this.couples,
    required this.updatedAt,
  });
}

/// Échec de synchronisation avec un message déjà prêt pour l'utilisateur.
class _SyncFailure implements Exception {
  final String message;
  const _SyncFailure(this.message);
}

/// Comptes en ligne (Firebase Authentication) et sauvegarde synchronisée
/// (Cloud Firestore).
///
/// Principe : les données restent toujours enregistrées sur le téléphone, et
/// l'appli fonctionne à l'identique sans compte ni connexion. Pour un abonné qui
/// s'est connecté, une copie complète de l'élevage est envoyée au serveur après
/// chaque modification, puis récupérée sur ses autres appareils. Si deux appareils
/// ont modifié les données chacun de leur côté, l'utilisateur choisit la version
/// à garder : rien n'est jamais écrasé sans qu'il le décide.
///
/// Organisation sur le serveur, réservée à son propriétaire par les règles de
/// sécurité Firestore :
///   users/{uid}/sync/meta      → numéro de version, nombre de morceaux, date
///   users/{uid}/sync/chunk_N   → l'instantané, compressé et découpé en morceaux
class CloudService extends ChangeNotifier {
  CloudService(this.app, {required this.canSyncCheck});

  final AppState app;

  /// Indique si l'utilisateur a droit à la sauvegarde en ligne (formule Premium).
  final bool Function() canSyncCheck;

  static const Duration _netTimeout = Duration(seconds: 25);

  /// Vrai si Firebase est configuré et démarré dans cette version de l'appli.
  bool available = false;

  User? user;
  ConflictInfo? conflict;
  String? errorMessage;

  SyncState _state = SyncState.fresh();
  bool _syncing = false;
  bool _offline = false;
  int _changeCounter = 0;
  Timer? _debounce;
  StreamSubscription<User?>? _authSub;
  _RemoteMeta? _conflictMeta;

  bool get signedIn => user != null;
  String? get email => user?.email;
  DateTime? get lastSyncAt => _state.lastSyncAt;
  bool get hasPendingChanges => _state.dirty;

  /// Vrai si le compte a été créé avec Google.
  bool get isGoogleAccount => user?.providerData.any((p) => p.providerId == 'google.com') ?? false;

  /// Vrai si le compte utilise un mot de passe.
  bool get isPasswordAccount => user?.providerData.any((p) => p.providerId == 'password') ?? false;

  SyncStatus get status {
    if (!available) return SyncStatus.unavailable;
    if (user == null) return SyncStatus.signedOut;
    if (_syncing) return SyncStatus.syncing;
    if (conflict != null) return SyncStatus.conflict;
    if (!canSyncCheck()) return SyncStatus.premiumRequired;
    if (errorMessage != null) return SyncStatus.error;
    if (_offline) return SyncStatus.offline;
    if (_state.dirty) return SyncStatus.pending;
    return SyncStatus.idle;
  }

  // -------------------------------------------------------------------------
  // Démarrage
  // -------------------------------------------------------------------------

  /// À appeler une fois les données de l'appli chargées.
  Future<void> init() async {
    final stored = await SyncState.tryLoad();
    if (stored != null) {
      _state = stored;
    } else {
      // Première fois : si des données existaient déjà avant l'arrivée des
      // comptes, elles devront être envoyées à la première connexion.
      _state = SyncState.fresh();
      _state.everModified = app.loadedFromDisk;
      _state.dirty = app.loadedFromDisk;
      await _state.save();
    }
    app.onLocalChange = _onLocalChange;

    try {
      await Firebase.initializeApp();
      available = true;
    } catch (e) {
      // Pas de fichier de configuration Firebase dans ce build : l'appli reste
      // pleinement utilisable, sans les comptes en ligne.
      available = false;
      debugPrint('Firebase indisponible : $e');
    }

    if (available) {
      user = FirebaseAuth.instance.currentUser;
      _authSub = FirebaseAuth.instance.authStateChanges().listen(_onAuthChanged);
      if (user != null) _scheduleSync(const Duration(seconds: 2));
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _authSub?.cancel();
    super.dispose();
  }

  void _onAuthChanged(User? u) {
    final changedUser = u?.uid != user?.uid;
    user = u;
    if (u == null) {
      conflict = null;
      _conflictMeta = null;
      errorMessage = null;
      _offline = false;
    } else if (changedUser) {
      _scheduleSync(const Duration(milliseconds: 300));
    }
    notifyListeners();
  }

  void _onLocalChange() {
    _changeCounter++;
    _state.dirty = true;
    _state.everModified = true;
    unawaited(_state.save());
    notifyListeners();
    if (available && user != null && conflict == null && canSyncCheck()) {
      _scheduleSync(const Duration(seconds: 6));
    }
  }

  /// Demande une synchronisation dans un instant (par exemple juste après un abonnement).
  void syncSoon() {
    if (available && user != null && canSyncCheck()) _scheduleSync(const Duration(seconds: 1));
  }

  void _scheduleSync(Duration delay) {
    _debounce?.cancel();
    _debounce = Timer(delay, () {
      unawaited(syncNow());
    });
  }

  // -------------------------------------------------------------------------
  // Synchronisation
  // -------------------------------------------------------------------------

  DocumentReference<Map<String, dynamic>> _metaRef(String uid) =>
      FirebaseFirestore.instance.collection('users').doc(uid).collection('sync').doc('meta');

  DocumentReference<Map<String, dynamic>> _chunkRef(String uid, int i) =>
      FirebaseFirestore.instance.collection('users').doc(uid).collection('sync').doc('chunk_$i');

  /// Lance une synchronisation (bouton « Synchroniser maintenant » ou automatique).
  Future<void> syncNow() async {
    if (!available || user == null) return;
    if (!canSyncCheck()) {
      notifyListeners();
      return;
    }
    await _guarded(() => _syncOnce(0));
  }

  /// Exécute une opération de synchronisation en gérant l'état et les erreurs.
  Future<void> _guarded(Future<void> Function() body) async {
    if (_syncing) return;
    _syncing = true;
    _offline = false;
    errorMessage = null;
    notifyListeners();
    final startedAt = _changeCounter;
    try {
      await body();
    } on TimeoutException {
      _offline = true;
    } on _SyncFailure catch (e) {
      errorMessage = e.message;
    } on FirebaseException catch (e) {
      if (e.code == 'unavailable' || e.code == 'deadline-exceeded' || e.code == 'network-request-failed') {
        _offline = true;
      } else if (e.code == 'permission-denied') {
        errorMessage = 'Accès refusé par le serveur. Les règles de sécurité Firestore ne sont peut-être pas publiées.';
      } else {
        errorMessage = 'Synchronisation impossible (${e.code}).';
      }
    } catch (e) {
      errorMessage = 'Synchronisation impossible : $e';
    } finally {
      _syncing = false;
      notifyListeners();
    }
    // Des modifications sont arrivées pendant la synchronisation : on repasse.
    if (_changeCounter != startedAt &&
        conflict == null &&
        !_offline &&
        errorMessage == null &&
        user != null &&
        canSyncCheck()) {
      _scheduleSync(const Duration(seconds: 2));
    }
  }

  Future<void> _syncOnce(int depth) async {
    final u = user;
    if (u == null) return;
    final uid = u.uid;

    // Un autre compte s'est connecté sur cet appareil : on repart de zéro.
    if (_state.uid != uid) {
      _state.uid = uid;
      _state.lastVersion = null;
      _state.dirty = _state.everModified;
      await _state.save();
    }

    final meta = await _fetchMeta(uid);
    final action = planSync(
      remoteVersion: meta?.version,
      lastSyncedVersion: _state.lastVersion,
      dirty: _state.dirty,
      everModified: _state.everModified,
    );

    switch (action) {
      case SyncAction.nothing:
        if (meta != null) {
          _state.lastVersion = meta.version;
          _state.lastSyncAt = DateTime.now();
          await _state.save();
        }
        return;
      case SyncAction.push:
        final pushed = await _push(uid, meta?.version ?? 0);
        if (!pushed) {
          if (depth >= 2) {
            throw const _SyncFailure('La sauvegarde en ligne change trop souvent. Réessaie dans un instant.');
          }
          await _syncOnce(depth + 1);
        }
        return;
      case SyncAction.pull:
        await _pull(uid, meta!);
        return;
      case SyncAction.conflict:
        _conflictMeta = meta;
        conflict = ConflictInfo(
          remoteBirds: meta!.birds,
          remoteCouples: meta.couples,
          remoteUpdatedAt: meta.updatedAt,
          localBirds: app.birds.length,
          localCouples: app.couples.length,
        );
        return;
    }
  }

  Future<_RemoteMeta?> _fetchMeta(String uid) async {
    final snap = await _metaRef(uid).get(const GetOptions(source: Source.server)).timeout(_netTimeout);
    final d = snap.data();
    if (!snap.exists || d == null) return null;
    final ts = d['updatedAt'];
    return _RemoteMeta(
      version: (d['version'] as num?)?.toInt() ?? 0,
      chunkCount: (d['chunkCount'] as num?)?.toInt() ?? 0,
      birds: (d['birds'] as num?)?.toInt() ?? 0,
      couples: (d['couples'] as num?)?.toInt() ?? 0,
      updatedAt: ts is Timestamp ? ts.toDate() : null,
    );
  }

  /// Envoie les données de cet appareil. Renvoie `false` si le serveur a changé
  /// entre-temps (un autre appareil a envoyé sa version) : rien n'est écrasé.
  Future<bool> _push(String uid, int expectedVersion) async {
    final startCounter = _changeCounter;
    final chunks = encodeSnapshot(app.exportSnapshot());
    final birdsCount = app.birds.length;
    final couplesCount = app.couples.length;
    final newVersion = expectedVersion + 1;
    final metaRef = _metaRef(uid);

    final ok = await FirebaseFirestore.instance.runTransaction<bool>((tx) async {
      final snap = await tx.get(metaRef);
      // Sans sauvegarde en ligne, data() vaut null : on part alors d'une version 0.
      final data = snap.data() ?? <String, dynamic>{};
      final current = (data['version'] as num?)?.toInt() ?? 0;
      if (current != expectedVersion) return false;
      final oldCount = (data['chunkCount'] as num?)?.toInt() ?? 0;
      for (var i = 0; i < chunks.length; i++) {
        tx.set(_chunkRef(uid, i), {'i': i, 'data': chunks[i]});
      }
      for (var i = chunks.length; i < oldCount; i++) {
        tx.delete(_chunkRef(uid, i));
      }
      tx.set(metaRef, {
        'version': newVersion,
        'chunkCount': chunks.length,
        'birds': birdsCount,
        'couples': couplesCount,
        'deviceId': _state.deviceId,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    }).timeout(_netTimeout);

    if (!ok) return false;
    _state.lastVersion = newVersion;
    _state.lastSyncAt = DateTime.now();
    // Si l'utilisateur a modifié quelque chose pendant l'envoi, ce n'est pas encore sauvegardé.
    _state.dirty = _changeCounter != startCounter;
    await _state.save();
    conflict = null;
    _conflictMeta = null;
    return true;
  }

  /// Récupère la sauvegarde en ligne et remplace les données de cet appareil.
  Future<void> _pull(String uid, _RemoteMeta meta, {bool force = false}) async {
    final startCounter = _changeCounter;
    final futures = <Future<DocumentSnapshot<Map<String, dynamic>>>>[
      for (var i = 0; i < meta.chunkCount; i++)
        _chunkRef(uid, i).get(const GetOptions(source: Source.server)),
    ];
    final snaps = await Future.wait(futures).timeout(_netTimeout);
    final parts = <String>[];
    for (final s in snaps) {
      final d = s.data();
      if (!s.exists || d == null) {
        throw const _SyncFailure('La sauvegarde en ligne est incomplète. Réessaie dans un instant.');
      }
      parts.add(d['data'] as String? ?? '');
    }
    // L'utilisateur a modifié des données pendant le téléchargement : on ne les
    // écrase pas, la prochaine synchronisation détectera le conflit.
    if (!force && _changeCounter != startCounter) return;

    final data = decodeSnapshot(parts);
    await app.replaceAllData(data);
    _state.lastVersion = meta.version;
    _state.lastSyncAt = DateTime.now();
    _state.dirty = false;
    await _state.save();
    conflict = null;
    _conflictMeta = null;
  }

  /// Conflit : garder les données de cet appareil (elles remplacent celles du serveur).
  Future<void> resolveKeepLocal() async {
    final meta = _conflictMeta;
    final u = user;
    if (meta == null || u == null) return;
    await _guarded(() async {
      final ok = await _push(u.uid, meta.version);
      if (!ok) {
        conflict = null;
        _conflictMeta = null;
        await _syncOnce(1);
      }
    });
  }

  /// Conflit : récupérer les données du serveur (elles remplacent celles de cet appareil).
  Future<void> resolveUseRemote() async {
    final meta = _conflictMeta;
    final u = user;
    if (meta == null || u == null) return;
    await _guarded(() => _pull(u.uid, meta, force: true));
  }

  // -------------------------------------------------------------------------
  // Comptes
  // -------------------------------------------------------------------------

  /// Les méthodes de connexion renvoient `null` en cas de succès (ou d'annulation
  /// par l'utilisateur), sinon un message d'erreur prêt à être affiché.
  Future<String?> signInWithEmail(String email, String password) =>
      _authCall(() => FirebaseAuth.instance.signInWithEmailAndPassword(email: email.trim(), password: password));

  Future<String?> registerWithEmail(String email, String password) =>
      _authCall(() => FirebaseAuth.instance.createUserWithEmailAndPassword(email: email.trim(), password: password));

  Future<String?> signInWithGoogle() => _authCall(() {
    final provider = GoogleAuthProvider();
    provider.setCustomParameters({'prompt': 'select_account'});
    return FirebaseAuth.instance.signInWithProvider(provider);
  });

  Future<String?> sendPasswordReset(String email) async {
    if (!available) return _unavailableMessage;
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email.trim());
      return null;
    } on FirebaseAuthException catch (e) {
      return _authMessage(e);
    } catch (e) {
      return 'Erreur : $e';
    }
  }

  static const String _unavailableMessage = 'Les comptes en ligne ne sont pas disponibles dans cette version de l’appli.';

  Future<String?> _authCall(Future<UserCredential> Function() call) async {
    if (!available) return _unavailableMessage;
    try {
      await call();
      // On n'attend pas l'événement de connexion pour mettre l'écran à jour.
      user = FirebaseAuth.instance.currentUser;
      notifyListeners();
      return null;
    } on FirebaseAuthException catch (e) {
      return _authMessage(e);
    } catch (e) {
      return 'Erreur : $e';
    }
  }

  String? _authMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'canceled':
      case 'cancelled':
      case 'web-context-canceled':
      case 'popup-closed-by-user':
        return null; // l'utilisateur a fermé la fenêtre : ce n'est pas une erreur
      case 'invalid-email':
        return 'Adresse e-mail invalide.';
      case 'user-disabled':
        return 'Ce compte a été désactivé.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'E-mail ou mot de passe incorrect.';
      case 'email-already-in-use':
        return 'Un compte existe déjà avec cette adresse. Connecte-toi, ou utilise « Mot de passe oublié ».';
      case 'weak-password':
        return 'Mot de passe trop faible : 8 caractères minimum.';
      case 'network-request-failed':
        return 'Pas de connexion internet.';
      case 'too-many-requests':
        return 'Trop de tentatives. Réessaie dans quelques minutes.';
      case 'operation-not-allowed':
        return 'Ce mode de connexion n’est pas activé dans Firebase.';
      case 'requires-recent-login':
        return 'Par sécurité, reconnecte-toi puis réessaie.';
      default:
        return 'Connexion impossible (${e.code}).';
    }
  }

  /// Se déconnecte. Les données restent sur l'appareil.
  Future<void> signOut() async {
    if (!available) return;
    _debounce?.cancel();
    await FirebaseAuth.instance.signOut();
  }

  /// Supprime le compte et toutes les données en ligne. Les données de l'élevage
  /// restent sur cet appareil.
  ///
  /// Renvoie `null` en cas de succès, sinon un message d'erreur.
  /// [password] est nécessaire pour un compte protégé par mot de passe.
  Future<String?> deleteAccount({String? password}) async {
    final u = user;
    if (!available || u == null) return 'Aucun compte connecté.';
    try {
      // 1. Confirmation récente de l'identité (exigée par Firebase pour supprimer).
      if (isPasswordAccount) {
        final mail = u.email;
        if (mail == null || password == null || password.isEmpty) {
          return 'Saisis ton mot de passe pour confirmer la suppression.';
        }
        await u.reauthenticateWithCredential(EmailAuthProvider.credential(email: mail, password: password));
      } else if (isGoogleAccount) {
        await u.reauthenticateWithProvider(GoogleAuthProvider());
      }

      // 2. Suppression des données en ligne.
      _debounce?.cancel();
      final col = FirebaseFirestore.instance.collection('users').doc(u.uid).collection('sync');
      final docs = await col.get(const GetOptions(source: Source.server)).timeout(_netTimeout);
      final batch = FirebaseFirestore.instance.batch();
      for (final d in docs.docs) {
        batch.delete(d.reference);
      }
      await batch.commit().timeout(_netTimeout);

      // 3. Suppression du compte lui-même.
      await u.delete();

      // Les données locales sont conservées : elles seront proposées à un futur compte.
      _state.uid = null;
      _state.lastVersion = null;
      _state.dirty = _state.everModified;
      _state.lastSyncAt = null;
      await _state.save();
      conflict = null;
      _conflictMeta = null;
      errorMessage = null;
      notifyListeners();
      return null;
    } on FirebaseAuthException catch (e) {
      return _authMessage(e) ?? 'Suppression annulée.';
    } on TimeoutException {
      return 'Pas de connexion internet. Réessaie une fois connecté.';
    } on FirebaseException catch (e) {
      return 'Suppression impossible (${e.code}).';
    } catch (e) {
      return 'Erreur : $e';
    }
  }
}
