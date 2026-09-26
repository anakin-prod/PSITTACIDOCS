import 'package:flutter/material.dart';

import '../models/species.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'species_detail_screen.dart';

/// Regroupement indicatif par famille/genre courant en aviculture, pour
/// filtrer plus vite dans la liste des 381 espèces.
String speciesGroup(Species s) {
  final genus = s.sci.split(' ').first;
  const map = {
    'Ara': 'Aras', 'Anodorhynchus': 'Aras', 'Cyanopsitta': 'Aras', 'Primolius': 'Aras',
    'Orthopsittaca': 'Aras', 'Diopsittaca': 'Aras',
    'Amazona': 'Amazones', 'Alipiopsitta': 'Amazones',
    'Cacatua': 'Cacatoès', 'Probosciger': 'Cacatoès', 'Nymphicus': 'Cacatoès',
    'Callocephalon': 'Cacatoès', 'Zanda': 'Cacatoès', 'Lophochroa': 'Cacatoès', 'Eolophus': 'Cacatoès',
    'Aratinga': 'Conures', 'Psittacara': 'Conures', 'Eupsittula': 'Conures', 'Thectocercus': 'Conures',
    'Guaruba': 'Conures', 'Nandayus': 'Conures',
    'Pyrrhura': 'Conures', 'Enicognathus': 'Conures', 'Cyanoliseus': 'Conures',
    'Pionus': 'Piones', 'Pionopsitta': 'Piones', 'Pyrilia': 'Piones', 'Graydidascalus': 'Piones',
    'Psittacus': 'Perroquets', 'Poicephalus': 'Perroquets', 'Eclectus': 'Perroquets',
    'Psittacula': 'Perruches', 'Platycercus': 'Perruches',
    'Cyanoramphus': 'Perruches', 'Barnardius': 'Perruches', 'Northiella': 'Perruches',
    'Neophema': 'Perruches', 'Neopsephotus': 'Perruches', 'Psephotus': 'Perruches',
    'Psephotellus': 'Perruches', 'Melopsittacus': 'Perruches', 'Polytelis': 'Perruches',
    'Alisterus': 'Perruches', 'Aprosmictus': 'Perruches', 'Eunymphicus': 'Perruches',
    'Purpureicephalus': 'Perruches', 'Pezoporus': 'Perruches',
    'Bolbopsittacus': 'Perruches', 'Tanygnathus': 'Perruches', 'Prioniturus': 'Perruches',
    'Agapornis': 'Inséparables',
    'Trichoglossus': 'Loris', 'Eos': 'Loris', 'Lorius': 'Loris', 'Vini': 'Loris',
    'Chalcopsitta': 'Loris', 'Pseudeos': 'Loris', 'Glossopsitta': 'Loris', 'Parvipsitta': 'Loris',
    'Charmosyna': 'Loris', 'Phigys': 'Loris', 'Psitteuteles': 'Loris', 'Oreopsittacus': 'Loris',
    'Neopsittacus': 'Loris',
    'Pionites': 'Caïques',
    'Touit': 'Touis', 'Forpus': 'Touis', 'Brotogeris': 'Touis', 'Nannopsittaca': 'Touis',
    'Bolborhynchus': 'Touis', 'Myiopsitta': 'Touis',
  };
  return map[genus] ?? 'Autres';
}

const kSpeciesGroups = [
  'Toutes',
  'Aras', 'Amazones', 'Cacatoès', 'Conures', 'Piones', 'Perroquets',
  'Perruches', 'Inséparables', 'Loris', 'Caïques', 'Touis', 'Autres',
];

const kProtectionFilters = [
  'Toutes protections', 'Annexe A (UE)', 'Annexe B (UE)', 'Non inscrites',
];

class SpeciesScreen extends StatefulWidget {
  final AppState appState;
  const SpeciesScreen({super.key, required this.appState});

  @override
  State<SpeciesScreen> createState() => _SpeciesScreenState();
}

class _SpeciesScreenState extends State<SpeciesScreen> {
  final _ctrl = TextEditingController();
  String _group = 'Toutes';
  String _prot = 'Toutes protections';

  @override
  Widget build(BuildContext context) {
    final q = _ctrl.text.trim().toLowerCase();
    var list = widget.appState.species;
    if (_group != 'Toutes') list = list.where((s) => speciesGroup(s) == _group).toList();
    if (_prot != 'Toutes protections') {
      list = list.where((s) {
        switch (_prot) {
          case 'Annexe A (UE)':
            return s.ue == 'A';
          case 'Annexe B (UE)':
            return s.ue == 'B';
          case 'Non inscrites':
            return s.isNotListed;
          default:
            return true;
        }
      }).toList();
    }
    if (q.isNotEmpty) {
      list = list.where((s) => s.label.toLowerCase().contains(q) || s.sci.toLowerCase().contains(q)).toList();
    }
    final shown = list.take(120).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Espèces de psittacidés')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _ctrl,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              hintText: 'Nom français ou latin',
              prefixIcon: Icon(Icons.search, size: 20),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: kSpeciesGroups.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) => PillChoice(
                label: Text(kSpeciesGroups[i]),
                selected: _group == kSpeciesGroups[i],
                onSelected: (_) => setState(() => _group = kSpeciesGroups[i]),
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: kProtectionFilters.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) => PillChoice(
                label: Text(kProtectionFilters[i]),
                selected: _prot == kProtectionFilters[i],
                onSelected: (_) => setState(() => _prot = kProtectionFilters[i]),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text('${list.length} espèce${list.length > 1 ? 's' : ''}', style: const TextStyle(fontSize: 12, color: AppColors.mute)),
          const SizedBox(height: 8),
          for (final s in shown)
            InfoCard(
              leading: const CircleAvatar(radius: 4, backgroundColor: AppColors.bronze),
              title: s.label,
              subtitle: s.sci,
              trailing: ProtectionBadge(species: s),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => SpeciesDetailScreen(appState: widget.appState, sci: s.sci),
                ),
              ),
            ),
          if (list.length > 120)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Affinez la recherche pour voir les ${list.length - 120} autres.',
                style: const TextStyle(fontSize: 12, color: AppColors.mute),
              ),
            ),
        ],
      ),
    );
  }
}
