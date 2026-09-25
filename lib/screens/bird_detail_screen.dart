import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/bird.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/app_icons.dart';
import '../widgets/common.dart';
import 'edit_bird_screen.dart';
import 'genealogy_screen.dart';
import 'new_health_entry_screen.dart';

String formatIso(String? iso) {
  if (iso == null || iso.isEmpty) return '';
  try {
    final d = DateTime.parse(iso);
    return DateFormat('dd/MM/yyyy').format(d);
  } catch (_) {
    return iso;
  }
}

class BirdDetailScreen extends StatefulWidget {
  final AppState appState;
  final String ring;
  const BirdDetailScreen({super.key, required this.appState, required this.ring});

  @override
  State<BirdDetailScreen> createState() => _BirdDetailScreenState();
}

class _BirdDetailScreenState extends State<BirdDetailScreen> {
  late String _ring;

  @override
  void initState() {
    super.initState();
    _ring = widget.ring;
  }

  @override
  Widget build(BuildContext context) {
    final appState = widget.appState;
    final bird = appState.findBird(_ring);
    if (bird == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Fiche oiseau')),
        body: const Center(child: Text('Cet oiseau n’existe plus.')),
      );
    }
    final sp = appState.speciesBySci(bird.sci);
    final lastWeighing = bird.lastWeighing;
    final weighings = bird.weighingsSortedAsc;

    return Scaffold(
      appBar: AppBar(title: const Text('Fiche oiseau')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          Row(
            children: [
              BirdAvatar(bird: bird, species: sp, size: 56),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(bird.ring, style: Theme.of(context).textTheme.titleLarge),
                    Text(
                      '${sp?.label ?? bird.sci}, ${bird.sci}',
                      style: const TextStyle(fontStyle: FontStyle.italic, color: AppColors.mute, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              style: TextButton.styleFrom(padding: EdgeInsets.zero),
              onPressed: () async {
                final newRing = await Navigator.of(context).push<String>(
                  MaterialPageRoute(builder: (_) => EditBirdScreen(appState: appState, ring: _ring)),
                );
                if (newRing != null) setState(() => _ring = newRing);
              },
              child: const Text('Modifier cette fiche'),
            ),
          ),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 2.6,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            children: [
              _kv('Sexe', bird.sex == 'F' ? 'Femelle' : bird.sex == 'M' ? 'Mâle' : 'Inconnu'),
              _kv('Mutation', bird.mutation.isEmpty ? '—' : bird.mutation),
              _kv('Naissance', bird.born.isEmpty ? 'Inconnue' : formatIso(bird.born) + (bird.bornEstimated ? ' (estimée)' : '')),
              _kv('Origine', bird.origin),
              _kv('Bague', bird.ringType + (bird.ringDiameter.isNotEmpty ? ', ${bird.ringDiameter} mm' : '')),
              _kv('Statut', bird.status),
              _kv('Emplacement', bird.location.isEmpty ? '—' : bird.location),
              _kv(
                'CITES / UE',
                sp == null
                    ? '—'
                    : sp.isNotListed
                        ? 'Non inscrite'
                        : '${sp.cites} / ${sp.ue}',
              ),
            ],
          ),

          const SectionLabel('Santé'),
          if (lastWeighing != null)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: AppColors.navy, borderRadius: BorderRadius.circular(14)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Dernier poids · ${formatIso(lastWeighing.date)}',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${lastWeighing.weight!.toStringAsFixed(0)} g',
                    style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          if (weighings.length >= 2)
            Container(
              width: double.infinity,
              height: 90,
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.line),
              ),
              child: CustomPaint(painter: _WeightChartPainter(weighings.map((w) => w.weight!).toList())),
            ),
          if (bird.health.isEmpty) const EmptyHint('Aucune entrée de santé pour l’instant.'),
          for (final h in (List.of(bird.health)..sort((a, b) => b.date.compareTo(a.date))))
            InfoCard(
              leading: CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.navy,
                child: Icon(
                  iconFor(const {
                    'Pesée': 'scale',
                    'Traitement': 'leaf',
                    'Visite vétérinaire': 'steth',
                    'Vaccination': 'shield',
                  }[h.type] ?? 'doc'),
                  color: Colors.white,
                  size: 16,
                ),
              ),
              title: h.type + (h.type == 'Pesée' && h.weight != null ? ' · ${h.weight!.toStringAsFixed(0)} g' : ''),
              subtitle: formatIso(h.date) + (h.notes.isNotEmpty ? ' · ${h.notes}' : ''),
              dense: true,
            ),
          OutlinedButton.icon(
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Ajouter une entrée'),
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => NewHealthEntryScreen(appState: appState, ring: bird.ring)),
              );
              setState(() {});
            },
          ),

          if (bird.hasParents) ...[
            const SectionLabel('Parents'),
            InfoCard(
              leading: CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.navy,
                child: Icon(iconFor('tree'), color: Colors.white, size: 18),
              ),
              title: '${bird.fatherRing ?? '?'} × ${bird.motherRing ?? '?'}',
              subtitle: 'Voir la généalogie',
              trailing: const Icon(Icons.chevron_right, color: AppColors.mute),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => GenealogyScreen(appState: appState, ring: bird.ring)),
              ),
            ),
          ],

          const SectionLabel('Documents'),
          if (bird.documents.isEmpty) const EmptyHint('Aucun document pour l’instant.'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final d in bird.documents)
                Chip(label: Text(d.type)),
            ],
          ),

          if (bird.cession != null) ...[
            const SectionLabel('Cession'),
            InfoCard(
              leading: CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.navy,
                child: Icon(iconFor('out'), color: Colors.white, size: 18),
              ),
              title: bird.cession!.buyer,
              subtitle:
                  '${formatIso(bird.cession!.date)}${bird.cession!.price.isNotEmpty ? ' · ${bird.cession!.price}' : ''}',
            ),
          ],

          if (bird.notes.isNotEmpty) ...[
            const SectionLabel('Notes'),
            Text(bird.notes, style: const TextStyle(fontSize: 13)),
          ],
        ],
      ),
    );
  }

  Widget _kv(String label, String value) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppColors.line),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.mute)),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.navy),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    ),
  );
}

class _WeightChartPainter extends CustomPainter {
  final List<double> weights;
  _WeightChartPainter(this.weights);

  @override
  void paint(Canvas canvas, Size size) {
    if (weights.length < 2) return;
    final minW = weights.reduce((a, b) => a < b ? a : b);
    final maxW = weights.reduce((a, b) => a > b ? a : b);
    final pad = 6.0;
    final stepX = (size.width - 2 * pad) / (weights.length - 1);

    Offset pointAt(int i) {
      final x = pad + stepX * i;
      final y = maxW == minW
          ? size.height / 2
          : size.height - pad - ((weights[i] - minW) / (maxW - minW)) * (size.height - 2 * pad);
      return Offset(x, y);
    }

    final linePaint = Paint()
      ..color = AppColors.bronze
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    final dotPaint = Paint()..color = AppColors.navy;

    final path = Path()..moveTo(pointAt(0).dx, pointAt(0).dy);
    for (var i = 1; i < weights.length; i++) {
      final p = pointAt(i);
      path.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(path, linePaint);
    for (var i = 0; i < weights.length; i++) {
      canvas.drawCircle(pointAt(i), 3, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _WeightChartPainter oldDelegate) => oldDelegate.weights != weights;
}
