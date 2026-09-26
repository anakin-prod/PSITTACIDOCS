import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../logic/format.dart';
import '../logic/inbreeding.dart';
import '../logic/pdf_export.dart';
import '../models/bird.dart';
import '../models/bird_document.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/animations.dart';
import '../widgets/common.dart';
import 'birds_screen.dart';
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

const _healthIcons = {
  'Pesée': 'scale',
  'Traitement': 'leaf',
  'Visite vétérinaire': 'steth',
  'Vaccination': 'shield',
};

class BirdDetailScreen extends StatefulWidget {
  final AppState appState;
  final String ring;
  const BirdDetailScreen({super.key, required this.appState, required this.ring});

  @override
  State<BirdDetailScreen> createState() => _BirdDetailScreenState();
}

class _BirdDetailScreenState extends State<BirdDetailScreen> {
  late String _ring;
  bool _allHealth = false;

  @override
  void initState() {
    super.initState();
    _ring = widget.ring;
  }

  Future<void> _exportPdf(Bird bird) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await shareBirdSheet(widget.appState, bird);
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Export PDF impossible : $e')));
    }
  }

  Future<void> _edit() async {
    final newRing = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => EditBirdScreen(appState: widget.appState, ring: _ring)),
    );
    if (newRing != null) setState(() => _ring = newRing);
  }

  Future<void> _addHealth() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => NewHealthEntryScreen(appState: widget.appState, ring: _ring)),
    );
    setState(() {});
  }

  void _openBird(String ring) => Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => BirdDetailScreen(appState: widget.appState, ring: ring)),
  );

  Widget _tile(String label, String value, {Widget? extra}) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: AppDecor.tile(radius: 18),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: const TextStyle(fontSize: 11, letterSpacing: 0.7, color: AppColors.mute)),
        const SizedBox(height: 3),
        Row(
          children: [
            Flexible(
              child: Text(
                value,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.navy),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (extra != null) ...[const SizedBox(width: 8), Expanded(child: extra)],
          ],
        ),
      ],
    ),
  );

  Widget _pair(Widget a, Widget b) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [Expanded(child: a), const SizedBox(width: 10), Expanded(child: b)],
    ),
  );

  Widget _card({required List<Widget> children}) => Container(
    margin: const EdgeInsets.only(top: 14),
    padding: const EdgeInsets.all(16),
    decoration: AppDecor.card(radius: 22),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
  );

  Widget _cardTitle(String title, {String? action, VoidCallback? onAction}) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(child: Text(title, style: GoogleFonts.lora(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.navy))),
        if (action != null)
          GestureDetector(
            onTap: onAction,
            child: Text(action, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.bronzeDark)),
          ),
      ],
    ),
  );

  Widget _parentTile(String label, String? ring, {required bool father}) {
    final exists = ring != null && widget.appState.findBird(ring) != null;
    final bg = father ? const Color(0xFFF3F6FD) : const Color(0xFFFDF1F2);
    final fg = father ? AppColors.maleFg : AppColors.femaleFg;
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: exists ? () => _openBird(ring) : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: fg, letterSpacing: 0.6)),
              const SizedBox(height: 2),
              Text(ring ?? 'Inconnu', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.navy)),
            ],
          ),
        ),
      ),
    );
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
    final weighings = bird.weighingsSortedAsc;
    final last = weighings.isEmpty ? null : weighings.last;
    final delta = weighings.length >= 2 ? weighings.last.weight! - weighings[weighings.length - 2].weight! : null;
    final health = List.of(bird.health)..sort((a, b) => b.date.compareTo(a.date));
    final shownHealth = _allHealth ? health : health.take(3).toList();
    final coi = bird.hasParents ? appState.inbreedingOf(bird) : null;
    final hasChildren = appState.childrenOf(bird.ring).isNotEmpty;

    final protection = sp == null
        ? null
        : sp.isNotListed
            ? const Tag('Non inscrite CITES')
            : Tag('CITES ${sp.cites} · UE ${sp.ue}', tone: sp.isAnnexA ? TagTone.alert : TagTone.rose);

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            ListView(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 110),
              children: staggered([
                // Barre du haut : retour, export PDF, modification.
                Row(
                  children: [
                    CircleIconButton(
                      icon: Icons.arrow_back_rounded,
                      tooltip: 'Retour',
                      onPressed: () => Navigator.of(context).maybePop(),
                    ),
                    const Spacer(),
                    CircleIconButton(
                      icon: Icons.picture_as_pdf_outlined,
                      tooltip: 'Exporter la fiche en PDF',
                      onPressed: () => _exportPdf(bird),
                    ),
                    const SizedBox(width: 10),
                    CircleIconButton(icon: Icons.edit_outlined, tooltip: 'Modifier la fiche', onPressed: _edit),
                  ],
                ),
                const SizedBox(height: 14),
                // Identité
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: AppDecor.card(radius: 26),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          bird.photoPath != null
                              ? BirdAvatar(bird: bird, species: sp, size: 92)
                              : Container(
                                  width: 92,
                                  height: 92,
                                  decoration: BoxDecoration(color: AppColors.navy, borderRadius: BorderRadius.circular(28)),
                                  alignment: Alignment.center,
                                  child: Opacity(
                                    opacity: 0.9,
                                    child: Image.asset('assets/images/parrot_silhouette.png', width: 68, height: 68),
                                  ),
                                ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(bird.ring, style: GoogleFonts.lora(fontSize: 27, fontWeight: FontWeight.w600, color: AppColors.navy)),
                                Text(sp?.label ?? bird.sci, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.navy)),
                                Text(
                                  bird.sci,
                                  style: GoogleFonts.lora(fontSize: 13.5, fontStyle: FontStyle.italic, color: AppColors.mute),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [sexTag(bird.sex), statusTag(bird), if (protection != null) protection],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                // Informations en tuiles
                _pair(
                  _tile('Naissance', bird.born.isEmpty ? 'Inconnue' : formatIso(bird.born) + (bird.bornEstimated ? ' ~' : '')),
                  _tile('Mutation', bird.mutation.isEmpty ? '—' : bird.mutation),
                ),
                _pair(
                  _tile('Origine', bird.origin),
                  _tile('Bague', bird.ringType + (bird.ringDiameter.isNotEmpty ? ' · ${bird.ringDiameter} mm' : '')),
                ),
                _pair(
                  _tile('Emplacement', bird.location.isEmpty ? '—' : bird.location),
                  _tile(
                    'Consanguinité',
                    coi == null ? 'Inconnue' : formatPercent(coi),
                    extra: coi == null
                        ? null
                        : AnimatedBar(
                            value: (coi / 0.25).clamp(0.0, 1.0).toDouble(),
                            height: 5,
                            color: coi >= kInbreedingWarningThreshold ? AppColors.orangeFg : AppColors.bronze,
                            background: AppColors.neutralBg,
                          ),
                  ),
                ),
                // Santé
                _card(children: [
                  _cardTitle(
                    'Santé',
                    action: health.length > 3 ? (_allHealth ? 'Réduire' : 'Tout le journal') : null,
                    onAction: () => setState(() => _allHealth = !_allHealth),
                  ),
                  if (last != null) ...[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${formatNumber(last.weight!)} g',
                          style: GoogleFonts.lora(fontSize: 34, fontWeight: FontWeight.w600, color: AppColors.navy, height: 1),
                        ),
                        if (delta != null && delta != 0) ...[
                          const SizedBox(width: 10),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Tag(
                              '${delta > 0 ? '+' : '−'}${formatNumber(delta.abs())} g',
                              tone: delta > 0 ? TagTone.good : TagTone.alert,
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (weighings.length >= 2)
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: SizedBox(
                          height: 72,
                          width: double.infinity,
                          child: TweenAnimationBuilder<double>(
                            tween: Tween<double>(begin: 0, end: 1),
                            duration: const Duration(milliseconds: 1100),
                            curve: Curves.easeOutCubic,
                            builder: (context, t, _) => CustomPaint(
                              painter: _WeightChartPainter(weighings.map((w) => w.weight!).toList(), t),
                            ),
                          ),
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.only(top: 6, bottom: 4),
                      child: Text('Dernière pesée le ${formatIso(last.date)}', style: const TextStyle(fontSize: 12, color: AppColors.mute)),
                    ),
                  ],
                  if (health.isEmpty) const EmptyHint('Aucune entrée de santé pour l’instant.'),
                  for (final h in shownHealth)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Row(
                        children: [
                          IconTile(name: _healthIcons[h.type] ?? 'doc', size: 34),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  h.type + (h.type == 'Pesée' && h.weight != null ? ' · ${formatNumber(h.weight!)} g' : ''),
                                  style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: AppColors.navy),
                                ),
                                Text(
                                  formatIso(h.date) + (h.notes.isNotEmpty ? ' · ${h.notes}' : ''),
                                  style: const TextStyle(fontSize: 12, color: AppColors.mute),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                ]),
                // Parents et généalogie
                if (bird.hasParents || hasChildren)
                  _card(children: [
                    _cardTitle(
                      'Parents',
                      action: 'Voir l’arbre',
                      onAction: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => GenealogyScreen(appState: appState, ring: bird.ring)),
                      ),
                    ),
                    Row(
                      children: [
                        Expanded(child: _parentTile('PÈRE', bird.fatherRing, father: true)),
                        const SizedBox(width: 10),
                        Expanded(child: _parentTile('MÈRE', bird.motherRing, father: false)),
                      ],
                    ),
                  ]),
                // Documents
                const SectionLabel('Documents'),
                if (bird.documents.isEmpty)
                  const EmptyHint('Aucun document pour l’instant.')
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final BirdDocument d in bird.documents)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                          decoration: AppDecor.tile(radius: 12),
                          child: Text(d.type, style: const TextStyle(fontSize: 12.5, color: AppColors.navy)),
                        ),
                    ],
                  ),
                // Cession
                if (bird.cession != null)
                  _card(children: [
                    _cardTitle('Cession'),
                    Text(bird.cession!.buyer, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.navy)),
                    const SizedBox(height: 2),
                    Text(
                      '${formatIso(bird.cession!.date)}${bird.cession!.price.isNotEmpty ? ' · ${bird.cession!.price}' : ''}',
                      style: const TextStyle(fontSize: 12.5, color: AppColors.mute),
                    ),
                  ]),
                // Notes
                if (bird.notes.isNotEmpty)
                  _card(children: [
                    _cardTitle('Notes'),
                    Text(bird.notes, style: const TextStyle(fontSize: 13.5, height: 1.45, color: AppColors.navy)),
                  ]),
              ]),
            ),
            // Action principale, toujours à portée de pouce.
            Positioned(
              left: 18,
              right: 18,
              bottom: 16,
              child: Container(
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(18), boxShadow: AppDecor.shadowStrong),
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.add_rounded, size: 22),
                  label: const Text('Nouvelle pesée ou soin'),
                  onPressed: _addHealth,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Courbe de poids : trait bronze qui se dessine, points bleu nuit, dernier point mis en avant.
class _WeightChartPainter extends CustomPainter {
  final List<double> weights;
  final double progress; // 0 à 1 : avancement du tracé
  _WeightChartPainter(this.weights, this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    if (weights.length < 2) return;
    final minW = weights.reduce((a, b) => a < b ? a : b);
    final maxW = weights.reduce((a, b) => a > b ? a : b);
    const pad = 8.0;
    final stepX = (size.width - 2 * pad) / (weights.length - 1);

    Offset pointAt(int i) {
      final x = pad + stepX * i;
      final y = maxW == minW
          ? size.height / 2
          : size.height - pad - ((weights[i] - minW) / (maxW - minW)) * (size.height - 2 * pad);
      return Offset(x, y);
    }

    final path = Path()..moveTo(pointAt(0).dx, pointAt(0).dy);
    for (var i = 1; i < weights.length; i++) {
      path.lineTo(pointAt(i).dx, pointAt(i).dy);
    }
    // Tracé progressif
    for (final metric in path.computeMetrics()) {
      canvas.drawPath(
        metric.extractPath(0, metric.length * progress),
        Paint()
          ..color = AppColors.bronze
          ..strokeWidth = 2.5
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
    }
    final visible = (progress * (weights.length - 1)).floor();
    for (var i = 0; i <= visible && i < weights.length - 1; i++) {
      canvas.drawCircle(pointAt(i), 3.5, Paint()..color = AppColors.navy);
    }
    if (progress >= 1) {
      final p = pointAt(weights.length - 1);
      canvas.drawCircle(p, 6, Paint()..color = Colors.white);
      canvas.drawCircle(p, 4.5, Paint()..color = AppColors.bronze);
    }
  }

  @override
  bool shouldRepaint(covariant _WeightChartPainter old) => old.weights != weights || old.progress != progress;
}
