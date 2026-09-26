import 'package:flutter/material.dart';

import '../logic/genetics.dart';
import '../logic/inbreeding.dart' show formatPercent;
import '../theme/app_theme.dart';
import '../widgets/animations.dart';
import '../widgets/common.dart';

/// Calculateur génétique en mode libre : l'éleveur saisit chaque mutation,
/// son mode de transmission et le génotype des deux parents.
class GeneticsScreen extends StatefulWidget {
  const GeneticsScreen({super.key});

  @override
  State<GeneticsScreen> createState() => _GeneticsScreenState();
}

class _GeneticsScreenState extends State<GeneticsScreen> {
  final List<GeneInput> _genes = [GeneInput()];
  final List<TextEditingController> _names = [TextEditingController()];

  @override
  void dispose() {
    for (final c in _names) {
      c.dispose();
    }
    super.dispose();
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
