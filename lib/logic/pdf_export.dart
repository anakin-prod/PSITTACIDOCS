import 'dart:io';

import 'package:cross_file/cross_file.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../models/bird.dart';
import '../state/app_state.dart';
import 'format.dart';
import 'inbreeding.dart';

/// Exports PDF : fiche d'un oiseau et inventaire de l'élevage.
///
/// Les documents sont générés sur le téléphone (police Poppins intégrée, pour
/// les accents), puis proposés via la feuille de partage d'Android : e-mail,
/// messagerie, enregistrement dans les fichiers, impression…

final PdfColor _navy = PdfColor.fromHex('#0E2254');
final PdfColor _bronze = PdfColor.fromHex('#C39463');
final PdfColor _line = PdfColor.fromHex('#F0DAD8');
final PdfColor _mute = PdfColor.fromHex('#5B6280');

const String _disclaimer =
    'Document informatif généré par Psittacidocs. Il ne remplace pas les documents '
    'officiels (certificat intracommunautaire, certificat de cession, etc.).';

Future<pw.ThemeData> _theme() async {
  final regular = pw.Font.ttf(await rootBundle.load('assets/fonts/Poppins-Regular.ttf'));
  final bold = pw.Font.ttf(await rootBundle.load('assets/fonts/Poppins-Bold.ttf'));
  return pw.ThemeData.withFont(base: regular, bold: bold);
}

String _date(String iso) {
  if (iso.isEmpty) return '';
  try {
    return formatDate(DateTime.parse(iso));
  } catch (_) {
    return iso;
  }
}

String _sex(String s) => s == 'M' ? 'Mâle' : s == 'F' ? 'Femelle' : 'Inconnu';

String _protection(AppState app, String sci) {
  final sp = app.speciesBySci(sci);
  if (sp == null) return '—';
  if (sp.isNotListed) return 'Non inscrite';
  return '${sp.cites} / ${sp.ue}';
}

String _safeFileName(String s) => s.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');

pw.Widget _header(String title, String subtitle, String elevage) => pw.Container(
  padding: const pw.EdgeInsets.only(bottom: 8),
  margin: const pw.EdgeInsets.only(bottom: 10),
  decoration: pw.BoxDecoration(
    border: pw.Border(bottom: pw.BorderSide(color: _bronze, width: 1.5)),
  ),
  child: pw.Row(
    crossAxisAlignment: pw.CrossAxisAlignment.end,
    children: [
      pw.Expanded(
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(title, style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: _navy)),
            pw.Text(subtitle, style: pw.TextStyle(fontSize: 10, color: _mute)),
          ],
        ),
      ),
      pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          pw.Text('Psittacidocs', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: _navy)),
          if (elevage.isNotEmpty) pw.Text(elevage, style: pw.TextStyle(fontSize: 9, color: _mute)),
        ],
      ),
    ],
  ),
);

pw.Widget _footer(pw.Context context, String generated) => pw.Container(
  margin: const pw.EdgeInsets.only(top: 8),
  child: pw.Row(
    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
    children: [
      pw.Text(generated, style: pw.TextStyle(fontSize: 8, color: _mute)),
      pw.Text('Page ${context.pageNumber} / ${context.pagesCount}', style: pw.TextStyle(fontSize: 8, color: _mute)),
    ],
  ),
);

pw.Widget _section(String title) => pw.Padding(
  padding: const pw.EdgeInsets.only(top: 14, bottom: 6),
  child: pw.Text(title, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: _navy)),
);

pw.Widget _keyValues(List<List<String>> rows) => pw.Table(
  border: pw.TableBorder.all(color: _line, width: 0.8),
  columnWidths: const {0: pw.FlexColumnWidth(1), 1: pw.FlexColumnWidth(2)},
  children: [
    for (final r in rows)
      pw.TableRow(
        children: [
          pw.Padding(
            padding: const pw.EdgeInsets.all(5),
            child: pw.Text(r[0], style: pw.TextStyle(fontSize: 9, color: _mute)),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.all(5),
            child: pw.Text(r[1], style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
          ),
        ],
      ),
  ],
);

pw.Widget _dataTable(List<String> headers, List<List<String>> data) => pw.TableHelper.fromTextArray(
  headers: headers,
  data: data,
  headerStyle: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
  headerDecoration: pw.BoxDecoration(color: _navy),
  cellStyle: const pw.TextStyle(fontSize: 8.5),
  cellAlignment: pw.Alignment.centerLeft,
  border: pw.TableBorder.all(color: _line, width: 0.6),
  cellPadding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
);

pw.Widget _smallText(String text) =>
    pw.Text(text, style: pw.TextStyle(fontSize: 8, color: _mute));

/// Enregistre le PDF dans un dossier temporaire et ouvre la feuille de partage.
Future<void> _share(pw.Document doc, String fileName, String subject) async {
  final bytes = await doc.save();
  final dir = await getTemporaryDirectory();
  final file = File('${dir.path}/$fileName');
  await file.writeAsBytes(bytes, flush: true);
  await SharePlus.instance.share(
    ShareParams(
      files: [XFile(file.path, mimeType: 'application/pdf')],
      subject: subject,
      text: subject,
    ),
  );
}

/// Fiche PDF complète d'un oiseau.
Future<void> shareBirdSheet(AppState app, Bird b) async {
  final theme = await _theme();
  final sp = app.speciesBySci(b.sci);
  final generated = 'Généré le ${formatDateTime(DateTime.now())}';
  final parents = b.hasParents ? '${b.fatherRing ?? '?'} × ${b.motherRing ?? '?'}' : 'Inconnus';
  final coi = b.hasParents ? formatPercent(app.inbreedingOf(b)) : 'Parents inconnus';
  final health = List.of(b.health)..sort((x, y) => y.date.compareTo(x.date));

  final doc = pw.Document(title: 'Fiche ${b.ring}', author: 'Psittacidocs');
  doc.addPage(
    pw.MultiPage(
      theme: theme,
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(32),
      header: (context) => _header(
        'Fiche ${b.ring}',
        '${sp?.label ?? b.sci} · ${b.sci}',
        app.settings.elevageName,
      ),
      footer: (context) => _footer(context, generated),
      build: (context) => [
        _section('Identité'),
        _keyValues([
          ['Espèce', '${sp?.label ?? b.sci} (${b.sci})'],
          ['Sexe', _sex(b.sex)],
          ['Mutation', b.mutation.isEmpty ? '—' : b.mutation],
          ['Naissance', b.born.isEmpty ? 'Inconnue' : '${_date(b.born)}${b.bornEstimated ? ' (estimée)' : ''}'],
          ['Origine', b.origin],
          ['Bague', '${b.ringType}${b.ringDiameter.isNotEmpty ? ', ${b.ringDiameter} mm' : ''}'],
          ['Statut', b.status],
          ['Emplacement', b.location.isEmpty ? '—' : b.location],
          ['CITES / UE', _protection(app, b.sci)],
          ['Parents (père × mère)', parents],
          ['Consanguinité', coi],
        ]),
        _section('Santé'),
        if (health.isEmpty)
          _smallText('Aucune entrée de santé.')
        else
          _dataTable(
            ['Date', 'Type', 'Poids', 'Notes'],
            [
              for (final h in health)
                [
                  _date(h.date),
                  h.type,
                  h.weight == null ? '' : '${formatNumber(h.weight!)} g',
                  h.notes,
                ],
            ],
          ),
        _section('Documents'),
        if (b.documents.isEmpty)
          _smallText('Aucun document.')
        else
          _dataTable(['Type', 'Fichier'], [for (final d in b.documents) [d.type, d.fileName]]),
        if (b.cession != null) ...[
          _section('Cession'),
          _keyValues([
            ['Nouveau propriétaire', b.cession!.buyer],
            ['Date', _date(b.cession!.date)],
            if (b.cession!.price.isNotEmpty) ['Prix', b.cession!.price],
            if (b.cession!.contact.isNotEmpty) ['Contact', b.cession!.contact],
            if (b.cession!.notes.isNotEmpty) ['Notes', b.cession!.notes],
          ]),
        ],
        if (b.notes.isNotEmpty) ...[
          _section('Notes'),
          pw.Text(b.notes, style: const pw.TextStyle(fontSize: 10)),
        ],
        pw.SizedBox(height: 18),
        _smallText(_disclaimer),
      ],
    ),
  );
  await _share(doc, 'Psittacidocs_fiche_${_safeFileName(b.ring)}.pdf', 'Fiche ${b.ring}');
}

/// Inventaire PDF de tous les oiseaux de l'élevage (format paysage).
Future<void> shareInventory(AppState app) async {
  final theme = await _theme();
  final generated = 'Généré le ${formatDateTime(DateTime.now())}';
  final birds = List.of(app.birds)
    ..sort((a, b) {
      final sa = app.speciesBySci(a.sci)?.label ?? a.sci;
      final sb = app.speciesBySci(b.sci)?.label ?? b.sci;
      final c = sa.compareTo(sb);
      return c != 0 ? c : a.ring.compareTo(b.ring);
    });
  final present = birds.where((b) => !b.isCeded).length;
  final ceded = birds.length - present;

  final doc = pw.Document(title: 'Inventaire de l’élevage', author: 'Psittacidocs');
  doc.addPage(
    pw.MultiPage(
      theme: theme,
      pageFormat: PdfPageFormat.a4.landscape,
      margin: const pw.EdgeInsets.all(28),
      header: (context) => _header(
        'Inventaire de l’élevage',
        '$present oiseau${present > 1 ? 'x' : ''} présent${present > 1 ? 's' : ''}'
            '${ceded > 0 ? ' · $ceded cédé${ceded > 1 ? 's' : ''}' : ''}',
        app.settings.elevageName,
      ),
      footer: (context) => _footer(context, generated),
      build: (context) => [
        _dataTable(
          ['Bague', 'Espèce', 'Sexe', 'Naissance', 'Origine', 'Statut', 'Emplacement', 'CITES / UE', 'Parents', 'Cession'],
          [
            for (final b in birds)
              [
                b.ring,
                app.speciesBySci(b.sci)?.label ?? b.sci,
                _sex(b.sex),
                b.born.isEmpty ? '' : _date(b.born),
                b.origin,
                b.status,
                b.location,
                _protection(app, b.sci),
                b.hasParents ? '${b.fatherRing ?? '?'} × ${b.motherRing ?? '?'}' : '',
                b.cession == null ? '' : '${b.cession!.buyer}${b.cession!.date.isNotEmpty ? ', ${_date(b.cession!.date)}' : ''}',
              ],
          ],
        ),
        pw.SizedBox(height: 14),
        _smallText(_disclaimer),
      ],
    ),
  );
  await _share(doc, 'Psittacidocs_inventaire.pdf', 'Inventaire de l’élevage');
}
