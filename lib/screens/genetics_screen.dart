import 'package:flutter/material.dart';

import '../data/genetic_presets.dart';
import '../logic/genetics.dart';
import '../logic/inbreeding.dart' show formatPercent;
import '../models/species.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/animations.dart';
import '../widgets/common.dart';
import 'species_picker_screen.dart';

/// Calculateur génétique. Pour une espèce dont la liste des mutations a été
/// validée, des puces pré-remplies évitent de deviner le mode de
/// transmission. Pour toutes les autres espèces (ou en complément), le mode
/// libre reste disponible : l'éleveur saisit lui-même chaque mutation.
class GeneticsScreen extends StatefulWidget {
  final AppState appState;
  const GeneticsScreen({super.key, required this.appState});

  @override
  State<GeneticsScreen> createState() => _GeneticsScreenState();
}

class _GeneticsScreenState extends State<GeneticsScreen> {
  final List<GeneInput> _genes = [GeneInput()];
  final List<TextEditingController> _names = [TextEditingController()];
  Species? _species;

  Future<void> _pickSpecies() async {
    final picked = await Navigator.of(context).push<Species>(
      MaterialPageRoute(builder: (_) => SpeciesPickerScreen(appState: widget.appState)),
    );
    if (picked != null) setState(() => _species = picked);
  }

  /// Ajoute une mutation pré-remplie (ou la retire si elle est déjà présente).
  void _togglePreset(MutationPreset preset) {
    final i = _genes.indexWhere((g) => g.name == preset.name);
    if (i != -1) {
      _removeGene(i);
      return;
    }
    setState(() {
      // La toute première carte n'a encore jamais été touchée : on la
      // remplit plutôt que d'en ajouter une vide en plus.
      if (_genes.length == 1 && _genes[0].name.isEmpty) {
        _genes[0].name = preset.name;
        _genes[0].mode = preset.mode;
        _names[0].text = preset.name;
        return;
      }
      _genes.add(GeneInput(name: preset.name, mode: preset.mode));
      _names.add(TextEditingController(text: preset.name));
    });
  }

  @override
  void dispose() {
    for (final c in _names) {
      c.dispose();
    }
    super.dispose();
  }

  Widget _presetPicker() {
    final presets = geneticPresets[_species?.sci];
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: AppDecor.card(radius: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Espèce', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(height: 8),
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: _pickSpecies,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.neutralBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _species?.label ?? 'Choisir une espèce (facultatif)',
                      style: TextStyle(
                        fontSize: 13.5,
                        color: _species == null ? AppColors.mute : AppColors.navy,
                        fontWeight: _species == null ? FontWeight.w400 : FontWeight.w600,
                      ),
                    ),
                  ),
                  const Icon(Icons.chevron_right, size: 18, color: AppColors.mute),
                ],
              ),
            ),
          ),
          if (_species != null && presets == null) ...[
            const SizedBox(height: 10),
            Text(
              'Pas encore de mutations pré-remplies validées pour cette espèce : utilise le mode libre ci-dessous.',
              style: TextStyle(fontSize: 12, color: AppColors.mute, height: 1.4),
            ),
          ],
          if (presets != null) ...[
            const SizedBox(height: 10),
            Text(
              'Touche une mutation pour l\'ajouter à la liste ci-dessous.',
              style: TextStyle(fontSize: 12, color: AppColors.mute),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final p in presets)
                  PillChoice(
                    label: Text(p.note == null ? p.name : '${p.name} · ${p.note}'),
                    selected: _genes.any((g) => g.name == p.name),
                    onSelected: (_) => _togglePreset(p),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _addGene() => setState(() {
    _genes.add(GeneInput());
    _names.add(TextEditingController());
  });

  void _removeGene(int i) => setState(() {
    _genes.removeAt(i);
    _names.removeAt(i).dispose();
  });

  Widget _genotypeChips(GeneInput g, {required bool female}) {
    final options = genotypeOptions(g.mode, female: female);
    final current = female ? g.mother : g.father;
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final o in options)
          PillChoice(
            label: Text(o.label),
            selected: current == o.copies,
            onSelected: (_) => setState(() {
              if (female) {
                g.mother = o.copies;
              } else {
                g.father = o.copies;
              }
            }),
          ),
      ],
    );
  }

  Widget _geneCard(int i) {
    final g = _genes[i];
    return Container(
      // Clé propre à chaque mutation : si on en supprime une, les autres
      // cartes gardent leur propre état (liste déroulante comprise).
      key: ObjectKey(g),
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: AppDecor.card(radius: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _names[i],
                  onChanged: (v) => setState(() => g.name = v),
                  decoration: InputDecoration(labelText: 'Mutation ${i + 1}', hintText: 'ex. Lutino, Bleu, Pie…'),
                ),
              ),
              if (_genes.length > 1)
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.mute),
                  tooltip: 'Retirer cette mutation',
                  onPressed: () => _removeGene(i),
                ),
            ],
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<InheritanceMode>(
            initialValue: g.mode,
            decoration: const InputDecoration(labelText: 'Mode de transmission'),
            items: [
              for (final m in InheritanceMode.values)
                DropdownMenuItem(value: m, child: Text(inheritanceLabel(m))),
            ],
            onChanged: (m) => setState(() {
              if (m == null) return;
              g.mode = m;
              // Les génotypes possibles changent avec le mode : on repart de zéro.
              g.father = 0;
              g.mother = 0;
            }),
          ),
          const SizedBox(height: 12),
          const Text('Père', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(height: 6),
          _genotypeChips(g, female: false),
          const SizedBox(height: 10),
          const Text('Mère', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(height: 6),
          _genotypeChips(g, female: true),
        ],
      ),
    );
  }

  Widget _results(String title, List<GeneticOutcome> outcomes) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SectionLabel(title),
      for (final o in outcomes)
        Container(
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: AppDecor.card(radius: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  SizedBox(
                    width: 64,
                    child: Text(
                      formatPercent(o.probability),
                      style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.navy),
                    ),
                  ),
                  Expanded(child: Text(o.label, style: const TextStyle(fontSize: 13))),
                ],
              ),
              const SizedBox(height: 6),
              AnimatedBar(value: o.probability, height: 5),
            ],
          ),
        ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final result = computeOffspring(_genes);
    return Scaffold(
      appBar: AppBar(title: const Text('Calculateur génétique')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _presetPicker(),
          const InfoBanner(
            'Mode libre : tu indiques toi-même le mode de transmission de chaque mutation. '
            'Vérifie-le pour ton espèce : un mode erroné donne un résultat faux.',
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < _genes.length; i++) _geneCard(i),
          OutlinedButton.icon(
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Ajouter une mutation'),
            onPressed: _addGene,
          ),
          _results('Jeunes mâles', result.sons),
          _results('Jeunes femelles', result.daughters),
          const SizedBox(height: 8),
          const Text(
            'Pourcentages parmi les jeunes du même sexe, en théorie : sur une petite nichée, '
            'la répartition réelle peut s’en écarter. Limites : les mutations sont traitées comme '
            'indépendantes (la liaison entre mutations liées au sexe n’est pas prise en compte), '
            'et une série d’allèles d’un même gène doit être saisie comme une seule mutation.',
            style: TextStyle(fontSize: 11, color: AppColors.mute),
          ),
        ],
      ),
    );
  }
}
