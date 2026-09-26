import 'package:flutter/material.dart';

import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/animations.dart';
import '../widgets/common.dart';
import 'bird_detail_screen.dart';
import 'incubation_detail_screen.dart';
import 'new_event_screen.dart';

const _dayLetters = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];

DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

class AgendaScreen extends StatefulWidget {
  final AppState appState;
  const AgendaScreen({super.key, required this.appState});

  @override
  State<AgendaScreen> createState() => _AgendaScreenState();
}

class _AgendaScreenState extends State<AgendaScreen> {
  DateTime? _selected; // jour choisi dans la semaine (null = tout afficher)

  Widget _card(AgendaItem item) {
    final appState = widget.appState;
    final date = DateTime.tryParse(item.date) ?? DateTime.now();
    VoidCallback? onTap;
    if (item.birdRing != null) {
      onTap = () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => BirdDetailScreen(appState: appState, ring: item.birdRing!)),
      );
    } else if (item.incubationId != null) {
      onTap = () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => IncubationDetailScreen(appState: appState, incubationId: item.incubationId!)),
      );
    }
    return DateCard(
      date: date,
      icon: item.icon,
      title: item.title,
      subtitle: item.subtitle,
      badge: appState.relativeLabel(item.date),
      onTap: onTap,
      trailing: item.auto
          ? null
          : IconButton(
              tooltip: 'Supprimer',
              icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.chevron),
              onPressed: () async {
                final ok = await confirmDestructive(
                  context,
                  title: 'Supprimer cet événement ?',
                  message: '« ${item.title} » sera retiré de l’agenda.',
                  confirmLabel: 'Supprimer',
                );
                if (ok) await appState.deleteEvent(item.deleteId!);
              },
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = widget.appState;
    final items = appState.agendaItems();
    final today = _day(DateTime.now());
    final monday = today.subtract(Duration(days: today.weekday - 1));
    final week = List.generate(7, (i) => monday.add(Duration(days: i)));
    final endOfWeek = week.last;
    final busy = {for (final it in items) if (DateTime.tryParse(it.date) != null) _day(DateTime.parse(it.date))};

    final upcoming = items.where((it) {
      final d = DateTime.tryParse(it.date);
      return d != null && !_day(d).isBefore(today);
    }).toList();
    final shown = _selected == null
        ? upcoming
        : items.where((it) => DateTime.tryParse(it.date) != null && _day(DateTime.parse(it.date)) == _selected).toList();
    final thisWeek = shown.where((it) => !_day(DateTime.parse(it.date)).isAfter(endOfWeek)).toList();
    final later = shown.where((it) => _day(DateTime.parse(it.date)).isAfter(endOfWeek)).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 110),
      children: staggered([
        ScreenHeader(
          title: 'Agenda',
          subtitle: '${upcoming.length} échéance${upcoming.length > 1 ? 's' : ''} à venir',
          trailing: AddButton(
            tooltip: 'Ajouter un événement',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => NewEventScreen(appState: appState)),
            ),
          ),
        ),
        // Semaine interactive : toucher un jour filtre la liste.
        Row(
          children: [
            for (var i = 0; i < 7; i++) ...[
              if (i > 0) const SizedBox(width: 6),
              Expanded(
                child: _DayPill(
                  letter: _dayLetters[i],
                  day: week[i].day,
                  isToday: week[i] == today,
                  isSelected: _selected == week[i],
                  hasEvents: busy.contains(week[i]),
                  onTap: () => setState(() => _selected = _selected == week[i] ? null : week[i]),
                ),
              ),
            ],
          ],
        ),
        if (_selected != null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Événements du ${_selected!.day}/${_selected!.month.toString().padLeft(2, '0')}',
                    style: const TextStyle(fontSize: 13, color: AppColors.mute),
                  ),
                ),
                GestureDetector(
                  onTap: () => setState(() => _selected = null),
                  child: const Text('Tout afficher', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.bronzeDark)),
                ),
              ],
            ),
          ),
        if (shown.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: EmptyHint(
              _selected == null
                  ? 'Aucune échéance à venir. Ajoute un rendez-vous ou une tâche avec le bouton +.'
                  : 'Rien de prévu ce jour-là.',
            ),
          ),
        if (thisWeek.isNotEmpty) ...[
          SectionLabel(_selected == null ? 'Cette semaine' : 'Ce jour-là'),
          for (final it in thisWeek) _card(it),
        ],
        if (later.isNotEmpty) ...[
          SectionLabel(_selected == null ? 'Plus tard' : 'Ce jour-là'),
          for (final it in later) _card(it),
        ],
      ]),
    );
  }
}

/// Jour de la semaine : lettre + numéro ; aujourd'hui en bleu nuit, jour choisi
/// en bronze, point bronze s'il y a un événement.
class _DayPill extends StatelessWidget {
  final String letter;
  final int day;
  final bool isToday;
  final bool isSelected;
  final bool hasEvents;
  final VoidCallback onTap;

  const _DayPill({
    required this.letter,
    required this.day,
    required this.isToday,
    required this.isSelected,
    required this.hasEvents,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isSelected ? AppColors.bronze : (isToday ? AppColors.navy : Colors.white);
    final fg = isSelected || isToday ? Colors.white : AppColors.navy;
    return PressableScale(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          height: 64,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(16),
            boxShadow: isToday || isSelected ? null : AppDecor.shadowLight,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(letter, style: TextStyle(fontSize: 11, color: isSelected || isToday ? Colors.white70 : AppColors.mute)),
              const SizedBox(height: 2),
              Text('$day', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: fg)),
              const SizedBox(height: 3),
              Container(
                width: 5,
                height: 5,
                decoration: BoxDecoration(
                  color: hasEvents ? (isSelected || isToday ? Colors.white : AppColors.bronze) : Colors.transparent,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
