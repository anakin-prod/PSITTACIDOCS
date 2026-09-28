import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../cloud/cloud_service.dart';
import '../config/app_config.dart';
import '../logic/format.dart';
import '../services.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'paywall_screen.dart';

/// Présentation d'un état de synchronisation : icône, couleur, titre, détail.
class SyncDescription {
  final IconData icon;
  final Color color;
  final String title;
  final String detail;
  const SyncDescription(this.icon, this.color, this.title, this.detail);
}

SyncDescription describeSync(CloudService c) {
  switch (c.status) {
    case SyncStatus.unavailable:
      return const SyncDescription(
        Icons.cloud_off_outlined,
        AppColors.mute,
        'Comptes indisponibles',
        'Cette version de l’appli n’est pas reliée aux comptes en ligne.',
      );
    case SyncStatus.signedOut:
      return const SyncDescription(Icons.cloud_off_outlined, AppColors.mute, 'Non connecté', 'Les données restent sur ce téléphone.');
    case SyncStatus.idle:
      final at = c.lastSyncAt;
      return SyncDescription(
        Icons.cloud_done_outlined,
        AppColors.goodFg,
        'Tout est synchronisé',
        at == null ? 'Rien à envoyer pour l’instant.' : 'Dernière synchronisation ${relativeAgo(at)}.',
      );
    case SyncStatus.pending:
      return const SyncDescription(
        Icons.cloud_upload_outlined,
        AppColors.bronzeDark,
        'Modifications en attente d’envoi',
        'Elles partent automatiquement, ou touche « Synchroniser maintenant ».',
      );
    case SyncStatus.syncing:
      return const SyncDescription(Icons.sync_rounded, AppColors.maleFg, 'Synchronisation en cours…', 'Un instant.');
    case SyncStatus.offline:
      return const SyncDescription(
        Icons.cloud_off_outlined,
        AppColors.mute,
        'Hors connexion',
        'Les données sont enregistrées sur le téléphone et partiront dès le retour du réseau.',
      );
    case SyncStatus.error:
      return SyncDescription(
        Icons.error_outline_rounded,
        AppColors.redText,
        'Synchronisation impossible',
        c.errorMessage ?? 'Une erreur est survenue.',
      );
    case SyncStatus.conflict:
      return const SyncDescription(
        Icons.compare_arrows_rounded,
        AppColors.orangeFg,
        'Deux versions différentes',
        'Cet appareil et la sauvegarde en ligne ont chacun des changements. Choisis celle à garder.',
      );
    case SyncStatus.premiumRequired:
      return const SyncDescription(
        Icons.workspace_premium_outlined,
        AppColors.bronzeDark,
        'Réservé à Premium',
        'La sauvegarde en ligne fait partie de la formule Premium.',
      );
  }
}

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  bool _deleting = false;

  Future<void> _signOut() async {
    final cloud = Services.cloud;
    final ok = await confirmDestructive(
      context,
      title: 'Se déconnecter ?',
      message: cloud.hasPendingChanges
          ? 'Certaines modifications n’ont pas encore été envoyées : elles restent sur cet appareil et partiront à ta prochaine connexion.'
          : 'Tes données restent sur cet appareil. Tu pourras te reconnecter à tout moment.',
      confirmLabel: 'Se déconnecter',
    );
    if (!ok) return;
    await cloud.signOut();
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  Future<void> _deleteAccount() async {
    final cloud = Services.cloud;
    final needsPassword = cloud.isPasswordAccount;
    final ctrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer mon compte ?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ton compte et toute ta sauvegarde en ligne seront supprimés définitivement. '
              'Les données présentes sur cet appareil ne sont pas effacées.',
            ),
            if (needsPassword) ...[
              const SizedBox(height: 14),
              TextField(
                controller: ctrl,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Ton mot de passe'),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    final password = ctrl.text;
    ctrl.dispose();
    if (confirmed != true || !mounted) return;

    setState(() => _deleting = true);
    final error = await cloud.deleteAccount(password: needsPassword ? password : null);
    if (!mounted) return;
    setState(() => _deleting = false);
    final messenger = ScaffoldMessenger.of(context);
    if (error == null) {
      Navigator.of(context).pop();
      messenger.showSnackBar(const SnackBar(content: Text('Ton compte et ta sauvegarde en ligne ont été supprimés.')));
    } else {
      messenger.showSnackBar(SnackBar(content: Text(error)));
    }
  }

  Future<void> _keepLocal() async {
    final ok = await confirmDestructive(
      context,
      title: 'Garder les données de cet appareil ?',
      message: 'La sauvegarde en ligne sera remplacée par les données de cet appareil.',
      confirmLabel: 'Garder cet appareil',
    );
    if (ok) await Services.cloud.resolveKeepLocal();
  }

  Future<void> _useRemote() async {
    final ok = await confirmDestructive(
      context,
      title: 'Récupérer la sauvegarde en ligne ?',
      message: 'Les données de cet appareil seront remplacées par celles de la sauvegarde en ligne.',
      confirmLabel: 'Récupérer',
    );
    if (ok) await Services.cloud.resolveUseRemote();
  }

  Widget _statusCard(CloudService cloud) {
    final d = describeSync(cloud);
    final syncing = cloud.status == SyncStatus.syncing;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppDecor.card(radius: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(color: d.color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(14)),
                child: syncing
                    ? Padding(
                        padding: const EdgeInsets.all(12),
                        child: CircularProgressIndicator(strokeWidth: 2.5, color: d.color),
                      )
                    : Icon(d.icon, color: d.color, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(d.title, style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w600, color: d.color)),
                    const SizedBox(height: 2),
                    Text(d.detail, style: const TextStyle(fontSize: 12.5, height: 1.4, color: AppColors.mute)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ElevatedButton.icon(
            icon: const Icon(Icons.sync_rounded, size: 20),
            label: const Text('Synchroniser maintenant'),
            onPressed: syncing || cloud.status == SyncStatus.premiumRequired || cloud.status == SyncStatus.conflict
                ? null
                : cloud.syncNow,
          ),
          if (cloud.status == SyncStatus.premiumRequired) ...[
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PaywallScreen())),
              child: const Text('Découvrir Premium'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _conflictCard(CloudService cloud) {
    final c = cloud.conflict;
    if (c == null) return const SizedBox.shrink();
    final remoteDate = c.remoteUpdatedAt == null ? '' : ' · modifiée ${relativeAgo(c.remoteUpdatedAt!)}';
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(16),
      decoration: AppDecor.card(radius: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Que veux-tu garder ?', style: GoogleFonts.lora(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.navy)),
          const SizedBox(height: 10),
          Text(
            'Cet appareil : ${c.localBirds} oiseau${c.localBirds > 1 ? 'x' : ''}, ${c.localCouples} couple${c.localCouples > 1 ? 's' : ''}.',
            style: const TextStyle(fontSize: 13, color: AppColors.navy),
          ),
          const SizedBox(height: 4),
          Text(
            'En ligne : ${c.remoteBirds} oiseau${c.remoteBirds > 1 ? 'x' : ''}, ${c.remoteCouples} couple${c.remoteCouples > 1 ? 's' : ''}$remoteDate.',
            style: const TextStyle(fontSize: 13, color: AppColors.navy),
          ),
          const SizedBox(height: 14),
          ElevatedButton(onPressed: _keepLocal, child: const Text('Garder cet appareil')),
          const SizedBox(height: 10),
          OutlinedButton(onPressed: _useRemote, child: const Text('Récupérer la sauvegarde en ligne')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mon compte')),
      body: ListenableBuilder(
        listenable: Listenable.merge([Services.cloud, Services.premium]),
        builder: (context, _) {
          final cloud = Services.cloud;
          final email = cloud.email ?? '';
          final initial = email.isEmpty ? '?' : email.substring(0, 1).toUpperCase();
          return ListView(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: AppDecor.card(radius: 22),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(color: AppColors.navy, borderRadius: BorderRadius.circular(17)),
                      alignment: Alignment.center,
                      child: Text(initial, style: GoogleFonts.lora(fontSize: 22, fontWeight: FontWeight.w600, color: AppColors.bronzeOnNavy)),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(email, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.navy), overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 6,
                            children: [
                              Tag(cloud.isGoogleAccount ? 'Compte Google' : 'E-mail et mot de passe'),
                              if (Services.premium.isPremium) const Tag('Premium', tone: TagTone.bronze),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SectionLabel('Synchronisation'),
              _statusCard(cloud),
              _conflictCard(cloud),
              const InfoBanner(
                'Les photos ne sont pas synchronisées : elles restent sur l’appareil où tu les as ajoutées.',
              ),
              const SectionLabel('Compte'),
              OutlinedButton.icon(
                icon: const Icon(Icons.logout_rounded, size: 20),
                label: const Text('Se déconnecter'),
                onPressed: _deleting ? null : _signOut,
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                icon: _deleting
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2.2))
                    : const Icon(Icons.delete_outline_rounded, size: 20, color: AppColors.red),
                label: Text('Supprimer mon compte', style: TextStyle(color: _deleting ? AppColors.mute : AppColors.red)),
                onPressed: _deleting ? null : _deleteAccount,
              ),
              const SizedBox(height: 18),
              Center(
                child: GestureDetector(
                  onTap: () => launchUrl(Uri.parse(kPrivacyPolicyUrl), mode: LaunchMode.externalApplication),
                  child: const Text(
                    'Politique de confidentialité',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.bronzeDark),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
