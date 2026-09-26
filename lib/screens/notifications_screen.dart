import 'package:flutter/material.dart';

import '../models/app_notification.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/app_icons.dart';
import '../widgets/common.dart';
import 'bird_detail_screen.dart';
import 'cessions_screen.dart';
import 'couple_detail_screen.dart';

class NotificationsScreen extends StatefulWidget {
  final AppState appState;
  const NotificationsScreen({super.key, required this.appState});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  Widget build(BuildContext context) {
    final appState = widget.appState;
    final list = appState.visibleNotifications;
    final unread = list.where((n) => !n.read).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (unread > 0)
            TextButton(
              onPressed: () async {
                await appState.markAllNotificationsRead();
                setState(() {});
              },
              child: const Text('Tout marquer comme lu'),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (list.isEmpty) const EmptyHint('Aucune notification pour l’instant.'),
          for (final n in list) _NotifTile(appState: appState, notif: n),
        ],
      ),
    );
  }
}

class _NotifTile extends StatelessWidget {
  final AppState appState;
  final AppNotification notif;
  const _NotifTile({required this.appState, required this.notif});

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: notif.read ? 0.6 : 1,
      child: InfoCard(
        leading: notif.urgent && !notif.read
            ? Container(width: 40, height: 40, decoration: BoxDecoration(color: const Color(0xFFFBE0E2), borderRadius: BorderRadius.circular(13)), child: Icon(iconFor(notif.icon), color: AppColors.redText, size: 20))
            : IconTile(name: notif.icon),
        title: notif.title,
        subtitle: '${notif.subtitle} · ${notif.when}',
        trailing: notif.read
            ? null
            : Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(color: AppColors.red, shape: BoxShape.circle),
              ),
        onTap: () async {
          await appState.markNotificationRead(notif);
          if (!context.mounted) return;
          switch (notif.navTarget) {
            case 'fiche':
              if (notif.navId != null) {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => BirdDetailScreen(appState: appState, ring: notif.navId!),
                  ),
                );
              }
              break;
            case 'couple':
              if (notif.navId != null) {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => CoupleDetailScreen(appState: appState, coupleId: notif.navId!),
                  ),
                );
              }
              break;
            case 'cessions':
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => CessionsScreen(appState: appState)),
              );
              break;
          }
        },
      ),
    );
  }
}
