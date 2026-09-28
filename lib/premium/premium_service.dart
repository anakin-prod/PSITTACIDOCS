import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:path_provider/path_provider.dart';

import '../config/app_config.dart';

/// Fonctions réservées à la formule Premium.
enum PremiumFeature {
  unlimitedBirds,
  cloudSync,
  geneticsCalculator,
  breedingLogs,
  pdfExport,
}

/// Abonnement Premium via Google Play Facturation.
///
/// L'abonnement est rattaché au compte Google Play de l'utilisateur : il se
/// retrouve sur tous ses appareils connectés à ce compte, grâce à « Restaurer
/// mes achats ». Le statut est vérifié auprès de Google Play à chaque démarrage.
///
/// Limite connue : la vérification se fait sur l'appareil, sans serveur. C'est
/// suffisant pour une petite appli ; une vérification côté serveur pourra être
/// ajoutée plus tard si le besoin s'en fait sentir.
///
/// Tant que [kPremiumEnforced] vaut `false`, toutes les fonctions sont ouvertes
/// à tout le monde.
class PremiumService extends ChangeNotifier {
  /// Durée pendant laquelle un statut Premium déjà vérifié reste valable sans
  /// pouvoir joindre Google Play (par exemple sans connexion).
  static const Duration _offlineGrace = Duration(days: 14);

  /// Délai laissé à Google Play pour renvoyer les abonnements actifs.
  static const Duration _restoreWait = Duration(seconds: 12);

  bool storeAvailable = false;
  bool loadingProducts = false;
  bool purchaseInProgress = false;
  List<ProductDetails> products = [];
  String? message;

  bool _premium = false;
  DateTime? _verifiedAt;
  bool _sawActiveThisSession = false;
  StreamSubscription<List<PurchaseDetails>>? _sub;
  Timer? _restoreTimer;

  bool get isPremium => _premium;

  /// Vrai si la fonction est utilisable (toujours vrai tant que le verrouillage
  /// est désactivé).
  bool allows(PremiumFeature feature) => !kPremiumEnforced || _premium;

  /// Vrai si l'utilisateur a atteint la limite d'oiseaux de la formule gratuite.
  bool birdLimitReached(int presentBirds) => kPremiumEnforced && !_premium && presentBirds >= kFreeBirdLimit;

  // -------------------------------------------------------------------------
  // Démarrage
  // -------------------------------------------------------------------------

  Future<void> init() async {
    await _loadCache();
    notifyListeners();
    try {
      final iap = InAppPurchase.instance;
      storeAvailable = await iap.isAvailable();
      _sub = iap.purchaseStream.listen(
        _onPurchases,
        onError: (Object e) {
          message = 'Erreur de la boutique : $e';
          notifyListeners();
        },
      );
      if (storeAvailable) {
        await loadProducts();
        await restore();
      }
    } catch (e) {
      storeAvailable = false;
      debugPrint('Boutique indisponible : $e');
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _sub?.cancel();
    _restoreTimer?.cancel();
    super.dispose();
  }

  // -------------------------------------------------------------------------
  // Produits, achat, restauration
  // -------------------------------------------------------------------------

  Future<void> loadProducts() async {
    loadingProducts = true;
    notifyListeners();
    try {
      final response = await InAppPurchase.instance.queryProductDetails(kSubscriptionIds);
      final list = List<ProductDetails>.of(response.productDetails);
      list.sort((a, b) => a.rawPrice.compareTo(b.rawPrice));
      products = list;
    } catch (e) {
      products = [];
      debugPrint('Produits introuvables : $e');
    }
    loadingProducts = false;
    notifyListeners();
  }

  Future<void> buy(ProductDetails product) async {
    if (!storeAvailable) {
      message = 'Google Play est inaccessible pour le moment.';
      notifyListeners();
      return;
    }
    purchaseInProgress = true;
    message = null;
    notifyListeners();
    try {
      await InAppPurchase.instance.buyNonConsumable(purchaseParam: PurchaseParam(productDetails: product));
    } catch (e) {
      purchaseInProgress = false;
      message = 'L’achat n’a pas pu démarrer.';
      notifyListeners();
    }
  }

  /// Interroge Google Play pour retrouver l'abonnement actif de ce compte Google.
  Future<void> restore() async {
    if (!storeAvailable) return;
    _sawActiveThisSession = false;
    try {
      await InAppPurchase.instance.restorePurchases();
    } catch (e) {
      debugPrint('Restauration impossible : $e');
      return;
    }
    // Google Play ne renvoie rien quand il n'y a plus d'abonnement actif : sans
    // réponse dans le délai, on considère que l'abonnement est terminé.
    _restoreTimer?.cancel();
    _restoreTimer = Timer(_restoreWait, () {
      if (!_sawActiveThisSession && _premium) {
        _premium = false;
        unawaited(_saveCache());
        notifyListeners();
      }
    });
  }

  Future<void> _onPurchases(List<PurchaseDetails> purchases) async {
    for (final p in purchases) {
      if (kSubscriptionIds.contains(p.productID)) {
        if (p.status == PurchaseStatus.purchased || p.status == PurchaseStatus.restored) {
          _grant();
        } else if (p.status == PurchaseStatus.pending) {
          purchaseInProgress = true;
        } else if (p.status == PurchaseStatus.error) {
          purchaseInProgress = false;
          message = 'L’achat n’a pas abouti. Aucun paiement n’a été effectué.';
        } else {
          // Achat annulé par l'utilisateur.
          purchaseInProgress = false;
        }
      }
      // Sans cette étape, Google Play rembourse l'achat au bout de 3 jours.
      if (p.pendingCompletePurchase) {
        try {
          await InAppPurchase.instance.completePurchase(p);
        } catch (e) {
          debugPrint('Confirmation de l’achat impossible : $e');
        }
      }
    }
    notifyListeners();
  }

  void _grant() {
    _premium = true;
    _verifiedAt = DateTime.now();
    _sawActiveThisSession = true;
    purchaseInProgress = false;
    message = null;
    unawaited(_saveCache());
  }

  // -------------------------------------------------------------------------
  // Mémoire locale du statut (pour fonctionner sans connexion)
  // -------------------------------------------------------------------------

  Future<File> _cacheFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/psittacidocs_premium.json');
  }

  Future<void> _loadCache() async {
    try {
      final f = await _cacheFile();
      if (!await f.exists()) return;
      final json = jsonDecode(await f.readAsString()) as Map<String, dynamic>;
      final verified = json['verifiedAt'] == null ? null : DateTime.tryParse(json['verifiedAt'] as String);
      _verifiedAt = verified;
      _premium = (json['premium'] as bool? ?? false) &&
          verified != null &&
          DateTime.now().difference(verified) < _offlineGrace;
    } catch (_) {
      _premium = false;
    }
  }

  Future<void> _saveCache() async {
    try {
      final f = await _cacheFile();
      await f.writeAsString(jsonEncode({
        'premium': _premium,
        'verifiedAt': _verifiedAt?.toIso8601String(),
      }));
    } catch (_) {
      // Sans conséquence : le statut sera revérifié auprès de Google Play.
    }
  }
}
