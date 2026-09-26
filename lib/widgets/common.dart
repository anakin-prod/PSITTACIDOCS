import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../logic/format.dart';
import '../models/bird.dart';
import '../models/species.dart';
import '../theme/app_theme.dart';
import 'animations.dart';
import 'app_icons.dart';

// ---------------------------------------------------------------------------
// Titres
// ---------------------------------------------------------------------------

/// Titre de section (Lora), avec un lien d'action facultatif à droite.
class SectionLabel extends StatelessWidget {
  final String text;
  final String? actionLabel;
  final VoidCallback? onAction;
  const SectionLabel(this.text, {super.key, this.actionLabel, this.onAction});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 22, bottom: 10),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Text(text, style: GoogleFonts.lora(fontSize: 19, fontWeight: FontWeight.w600, color: AppColors.navy)),
        ),
        if (actionLabel != null)
          GestureDetector(
            onTap: onAction,
            child: Text(
              actionLabel!,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.bronzeDark),
            ),
          ),
      ],
    ),
  );
}

/// Petit intitulé de groupe en capitales espacées (ex. « PIONE NOIRE · 3 »).
class GroupLabel extends StatelessWidget {
  final String text;
  const GroupLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 10, bottom: 8),
    child: Text(
      text.toUpperCase(),
      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.9, color: AppColors.bronzeDark),
    ),
  );
}

/// En-tête d'un écran principal : grand titre Lora, sous-titre, action à droite.
class ScreenHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;
  const ScreenHeader({super.key, required this.title, this.subtitle, this.trailing});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 4, bottom: 16),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: GoogleFonts.lora(fontSize: 30, fontWeight: FontWeight.w600, color: AppColors.navy, height: 1.15)),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(subtitle!, style: const TextStyle(fontSize: 13, color: AppColors.mute)),
              ],
            ],
          ),
        ),
        if (trailing != null) trailing!,
      ],
    ),
  );
}

// ---------------------------------------------------------------------------
// Boutons
// ---------------------------------------------------------------------------

/// Bouton carré arrondi blanc à ombre douce (actions d'en-tête).
class CircleIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final bool showDot;
  const CircleIconButton({super.key, required this.icon, required this.tooltip, this.onPressed, this.showDot = false});

  @override
  Widget build(BuildContext context) => PressableScale(
    child: Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onPressed,
          child: Container(
            width: 44,
            height: 44,
            decoration: AppDecor.card(radius: 14),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(icon, size: 21, color: AppColors.navy),
                if (showDot)
                  Positioned(
                    top: 9,
                    right: 10,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: AppColors.red,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

/// Bouton d'ajout bleu nuit (en-têtes des écrans principaux).
class AddButton extends StatelessWidget {
  final String tooltip;
  final VoidCallback onPressed;
  const AddButton({super.key, required this.tooltip, required this.onPressed});

  @override
  Widget build(BuildContext context) => PressableScale(
    child: Tooltip(
      message: tooltip,
      child: Material(
        color: AppColors.navy,
        borderRadius: BorderRadius.circular(16),
        elevation: 0,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onPressed,
          child: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [BoxShadow(color: Color(0x400E2254), blurRadius: 20, offset: Offset(0, 8))],
            ),
            child: const Icon(Icons.add_rounded, color: Colors.white, size: 26),
          ),
        ),
      ),
    ),
  );
}

// ---------------------------------------------------------------------------
// Pastilles et filtres
// ---------------------------------------------------------------------------

enum TagTone { female, male, neutral, warning, bronze, rose, good, alert }

/// Pastille colorée porteuse de sens (sexe, statut, protection…).
class Tag extends StatelessWidget {
  final String text;
  final TagTone tone;
  const Tag(this.text, {super.key, this.tone = TagTone.neutral});

  static (Color, Color) colors(TagTone t) => switch (t) {
    TagTone.female => (AppColors.femaleBg, AppColors.femaleFg),
    TagTone.male => (AppColors.maleBg, AppColors.maleFg),
    TagTone.warning => (AppColors.orangeBg, AppColors.orangeFg),
    TagTone.bronze => (AppColors.bronzeBg, AppColors.bronzeDark),
    TagTone.rose => (AppColors.chipBg, AppColors.chipText),
    TagTone.good => (AppColors.goodBg, AppColors.goodFg),
    TagTone.alert => (const Color(0xFFFBE0E2), AppColors.redText),
    TagTone.neutral => (AppColors.neutralBg, AppColors.neutralFg),
  };

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = colors(tone);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Text(text, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w500, color: fg)),
    );
  }
}

/// Pastille du sexe d'un oiseau.
Widget sexTag(String sex) => sex == 'M'
    ? const Tag('Mâle', tone: TagTone.male)
    : sex == 'F'
        ? const Tag('Femelle', tone: TagTone.female)
        : const Tag('Sexe inconnu');

/// Filtre en pastille (remplace les « ChoiceChip » standard) : bleu nuit quand
/// il est actif, blanc sinon, sans coche.
class PillChoice extends StatelessWidget {
  final Widget label;
  final bool selected;
  final ValueChanged<bool>? onSelected;
  const PillChoice({super.key, required this.label, required this.selected, this.onSelected});

  @override
  Widget build(BuildContext context) => PressableScale(
    child: GestureDetector(
      onTap: onSelected == null ? null : () => onSelected!(!selected),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.navy : Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: selected ? AppColors.navy : AppColors.pillBorder),
        ),
        child: DefaultTextStyle.merge(
          style: TextStyle(
            fontSize: 13,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            color: selected ? Colors.white : AppColors.navy,
          ),
          child: label,
        ),
      ),
    ),
  );
}

/// Champ de recherche blanc à ombre douce.
class SearchField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final ValueChanged<String>? onChanged;
  final bool autofocus;
  const SearchField({super.key, required this.controller, required this.hint, this.onChanged, this.autofocus = false});

  @override
  Widget build(BuildContext context) => Container(
    decoration: AppDecor.card(radius: 16),
    child: TextField(
      controller: controller,
      autofocus: autofocus,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: const Icon(Icons.search_rounded, size: 21, color: AppColors.mute),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.bronze, width: 1.5),
        ),
      ),
    ),
  );
}

// ---------------------------------------------------------------------------
// Icônes
// ---------------------------------------------------------------------------

/// Teinte associée à chaque type d'icône : chaque famille d'informations a sa
/// couleur, au lieu des mêmes cercles bleus partout.
(Color, Color) iconTint(String name) {
  switch (name) {
    case 'egg':
    case 'bowl':
      return (AppColors.orangeBg, AppColors.orangeFg);
    case 'thermo':
    case 'steth':
    case 'shield':
    case 'calendar':
    case 'genetics':
      return (AppColors.maleBg, AppColors.maleFg);
    case 'couple':
    case 'out':
    case 'pdf':
      return (AppColors.femaleBg, AppColors.femaleFg);
    case 'leaf':
      return (AppColors.goodBg, AppColors.goodFg);
    case 'doc':
    case 'gear':
      return (AppColors.neutralBg, AppColors.neutralFg);
    default:
      return (AppColors.bronzeBg, AppColors.bronzeDark);
  }
}

/// Icône dans un carré arrondi teinté.
class IconTile extends StatelessWidget {
  final String name;
  final double size;
  const IconTile({super.key, required this.name, this.size = 40});

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = iconTint(name);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(size * 0.32)),
      child: Icon(iconFor(name), color: fg, size: size * 0.5),
    );
  }
}

// ---------------------------------------------------------------------------
// Cartes
// ---------------------------------------------------------------------------

/// Carte de statistique : chiffre en avant (défile s'il est donné en [count]).
class StatCard extends StatelessWidget {
  final String label;
  final String value;
  final bool dark;
  final int? count;
  const StatCard({super.key, required this.label, this.value = '', this.dark = false, this.count});

  @override
  Widget build(BuildContext context) {
    final numberStyle = GoogleFonts.lora(
      fontSize: 28,
      fontWeight: FontWeight.w600,
      color: dark ? Colors.white : AppColors.navy,
      height: 1.1,
    );
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppDecor.card(radius: 20, color: dark ? AppColors.navy : Colors.white),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (count != null) AnimatedCount(value: count!, style: numberStyle) else Text(value, style: numberStyle),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 12, color: dark ? AppColors.onNavyMuted : AppColors.mute)),
        ],
      ),
    );
  }
}

/// Carte-ligne générique : élément à gauche, titre + sous-titre, élément à droite.
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
    final content = Padding(
      padding: EdgeInsets.symmetric(horizontal: 14, vertical: dense ? 10 : 13),
      child: Row(
        children: [
          leading,
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.navy, fontSize: 14.5)),
                if (subtitle != null && subtitle!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(subtitle!, style: const TextStyle(color: AppColors.mute, fontSize: 12.5, height: 1.35)),
                ],
              ],
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: 8), trailing!]
          else if (onTap != null) ...[
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right_rounded, color: AppColors.chevron, size: 22),
          ],
        ],
      ),
    );
    final card = Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: AppDecor.card(radius: 20),
      child: onTap == null
          ? content
          : Material(
              color: Colors.transparent,
              child: InkWell(borderRadius: BorderRadius.circular(20), onTap: onTap, child: content),
            ),
    );
    return onTap == null ? card : PressableScale(child: card);
  }
}

/// Carte d'échéance : la date en évidence dans un bloc teinté (selon le type
/// d'événement), un titre, un sous-titre et une pastille d'échéance.
class DateCard extends StatelessWidget {
  final DateTime date;
  final String icon;
  final String title;
  final String subtitle;
  final String? badge;
  final VoidCallback? onTap;
  final Widget? trailing;

  const DateCard({
    super.key,
    required this.date,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.badge,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = iconTint(icon);
    final content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 52,
            decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(14)),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('${date.day}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: fg, height: 1.1)),
                Text(frenchShortMonth(date.month), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: fg, letterSpacing: 0.6)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600, color: AppColors.navy)),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(fontSize: 12.5, color: AppColors.mute), maxLines: 2, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          if (badge != null) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
              child: Text(badge!, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: fg)),
            ),
          ],
          if (trailing != null) trailing!,
        ],
      ),
    );
    final card = Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: AppDecor.card(radius: 20),
      child: Material(
        color: Colors.transparent,
        child: InkWell(borderRadius: BorderRadius.circular(20), onTap: onTap, child: content),
      ),
    );
    return onTap == null ? card : PressableScale(child: card);
  }
}

/// Avatar d'un oiseau : sa photo, sinon ses initiales en bronze sur bleu nuit,
/// dans un carré aux coins très arrondis.
class BirdAvatar extends StatelessWidget {
  final Bird bird;
  final Species? species;
  final double size;
  const BirdAvatar({super.key, required this.bird, this.species, this.size = 52});

  String get _initials {
    final label = species?.label ?? bird.sci;
    final words = label.split(' ').where((w) => w.isNotEmpty).toList();
    if (words.isEmpty) return '?';
    if (words.length == 1) return words[0].substring(0, 1).toUpperCase();
    return (words[0].substring(0, 1) + words[1].substring(0, 1)).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(size * 0.33);
    final hasPhoto = bird.photoPath != null && File(bird.photoPath!).existsSync();
    return ClipRRect(
      borderRadius: radius,
      child: Container(
        width: size,
        height: size,
        color: AppColors.navy,
        alignment: Alignment.center,
        child: hasPhoto
            ? Image.file(File(bird.photoPath!), width: size, height: size, fit: BoxFit.cover)
            : Text(
                _initials,
                style: GoogleFonts.lora(color: AppColors.bronzeOnNavy, fontWeight: FontWeight.w600, fontSize: size * 0.33),
              ),
      ),
    );
  }
}

/// Statut CITES / UE d'une espèce, en texte coloré (rouge pour l'Annexe A).
class ProtectionBadge extends StatelessWidget {
  final Species species;
  const ProtectionBadge({super.key, required this.species});

  @override
  Widget build(BuildContext context) {
    if (species.isNotListed) {
      return const Text('Non inscrite', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.mute));
    }
    final a = species.isAnnexA;
    return Text(
      '${species.cites} · ${species.ue}',
      style: TextStyle(fontSize: 11.5, fontWeight: a ? FontWeight.w700 : FontWeight.w600, color: a ? AppColors.redText : AppColors.chipText),
    );
  }
}

/// Texte de repli quand une liste est vide.
class EmptyHint extends StatelessWidget {
  final String text;
  const EmptyHint(this.text, {super.key});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Text(text, style: const TextStyle(color: AppColors.mute, fontSize: 13.5)),
  );
}

/// Bandeau d'information doux, ou d'alerte.
class InfoBanner extends StatelessWidget {
  final String text;
  final bool warning;
  const InfoBanner(this.text, {super.key, this.warning = false});

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    margin: const EdgeInsets.only(top: 10),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: warning ? const Color(0xFFFBE0E2) : AppColors.bronzeBg,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Text(
      text,
      style: TextStyle(color: warning ? AppColors.redText : AppColors.bronzeDark, fontSize: 13, height: 1.4),
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
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
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
