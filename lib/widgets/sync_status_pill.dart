import 'package:flutter/material.dart';

import '../cloud/cloud_service.dart';
import '../screens/account_screen.dart';
import '../services.dart';
import '../theme/app_theme.dart';
import 'animations.dart';

/// Petit indicateur d'état de la synchronisation, affiché sur l'Accueil quand un
/// compte est connecté : « Tout est synchronisé », « 3 modifications en
/// attente », « Hors connexion »… Un toucher ouvre l'écran du compte.
class SyncStatusPill extends StatelessWidget {
  const SyncStatusPill({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Services.cloud,
      builder: (context, _) {
        final cloud = Services.cloud;
        if (!cloud.available || !cloud.signedIn) return const SizedBox.shrink();
        final d = describeSync(cloud);
        final syncing = cloud.status == SyncStatus.syncing;
        return Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Align(
            alignment: Alignment.centerLeft,
            child: PressableScale(
              child: GestureDetector(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AccountScreen()),
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: d.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      syncing
                          ? SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: d.color))
                          : Icon(d.icon, size: 16, color: d.color),
                      const SizedBox(width: 7),
                      Flexible(
                        child: Text(
                          d.title,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: d.color),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
