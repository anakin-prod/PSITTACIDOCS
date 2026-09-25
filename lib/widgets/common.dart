import 'dart:io';

import 'package:flutter/material.dart';

import '../models/bird.dart';
import '../models/species.dart';
import '../theme/app_theme.dart';

/// Un petit titre de section, dans le style bronze utilisé partout dans
/// l'appli (ex. "Documents", "Santé", "Parents").
class SectionLabel extends StatelessWidget {
  final String text;
  const SectionLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 18, bottom: 8),
    child: Text(
      text,
      style: const TextStyle(
        color: AppColors.bronzeDark,
        fontWeight: FontWeight.w600,
        fontSize: 13,
      ),
    ),
  );
}

/// Une carte de statistique (chiffre en avant), utilisée sur l'accueil et
/// les statistiques.
class StatCard extends StatelessWidget {
  final String label;
  final String value;
  final bool dark;
  const StatCard({super.key, required this.label, required this.value, this.dark = false});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: dark ? AppColors.navy : Colors.white,
      borderRadius: BorderRadius.circular(14),
      border: dark ? null : Border.all(color: AppColors.line),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: dark ? Colors.white70 : AppColors.mute,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: dark ? Colors.white : AppColors.navy,
          ),
        ),
      ],
    ),
  );
}

/// Une carte-ligne générique (icône ou avatar à gauche, titre + sous-titre,
/// éventuellement une flèche ou un widget à droite). C'est le composant le
/// plus utilisé de l'appli, pour toutes les listes.
class InfoCard extends StatelessWidget {
  final Widget leading;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool dense;

  const InfoCard({
    super.key,
    required this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.dense = false,
  });

  @override
  Widget build(BuildContext context) {
    final card = Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.symmetric(horizontal: 14, vertical: dense ? 10 : 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        children: [
          leading,
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.navy,
                    fontSize: 14,
                  ),
                ),
                if (subtitle != null && subtitle!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: const TextStyle(color: AppColors.mute, fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
    if (onTap == null) return card;
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: card,
    );
  }
}

/// L'avatar circulaire d'un oiseau : sa photo si elle existe, sinon ses
/// initiales sur fond bleu nuit.
class BirdAvatar extends StatelessWidget {
  final Bird bird;
  final Species? species;
  final double size;
  const BirdAvatar({super.key, required this.bird, this.species, this.size = 40});

  String get _initials {
    final label = species?.label ?? bird.sci;
    final words = label.split(' ').where((w) => w.isNotEmpty).toList();
    if (words.isEmpty) return '?';
    if (words.length == 1) return words[0].substring(0, 1).toUpperCase();
    return (words[0].substring(0, 1) + words[1].substring(0, 1)).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final hasPhoto = bird.photoPath != null && File(bird.photoPath!).existsSync();
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: AppColors.navy,
      backgroundImage: hasPhoto ? FileImage(File(bird.photoPath!)) : null,
      child: hasPhoto
          ? null
          : Text(
              _initials,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: size * 0.32,
              ),
            ),
    );
  }
}

/// Le badge d'annexe CITES / UE d'une espèce (ex. "I · A", "II · B").
class ProtectionBadge extends StatelessWidget {
  final Species species;
  const ProtectionBadge({super.key, required this.species});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    String text;
    if (species.isNotListed) {
      bg = const Color(0xFFEDEFF5);
      fg = AppColors.mute;
      text = 'Non inscrite';
    } else if (species.isAnnexA) {
      bg = const Color(0xFFF8D9DB);
      fg = const Color(0xFF9A1B24);
      text = '${species.cites} · A';
    } else {
      bg = AppColors.chipBg;
      fg = AppColors.chipText;
      text = '${species.cites} · B';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Text(text, style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.w500)),
    );
  }
}

/// Un simple texte de repli quand une liste est vide.
class EmptyHint extends StatelessWidget {
  final String text;
  const EmptyHint(this.text, {super.key});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Text(text, style: const TextStyle(color: AppColors.mute, fontSize: 13)),
  );
}

/// Une bannière d'information douce (fond rosé), pour les explications ou
/// avertissements non bloquants.
class InfoBanner extends StatelessWidget {
  final String text;
  final bool warning;
  const InfoBanner(this.text, {super.key, this.warning = false});

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    margin: const EdgeInsets.only(top: 10),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: warning ? const Color(0xFFFBEAE9) : const Color(0xFFF6E3E1),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Text(
      text,
      style: TextStyle(
        color: warning ? const Color(0xFF9A1B24) : const Color(0xFF6B3B3F),
        fontSize: 13,
      ),
    ),
  );
}

/// Demande une confirmation avant une action destructive (suppression).
Future<bool> confirmDestructive(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Supprimer définitivement',
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Annuler'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: TextButton.styleFrom(foregroundColor: AppColors.red),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return result ?? false;
}
