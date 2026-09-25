import 'package:flutter/material.dart';

import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/app_icons.dart';
import '../widgets/common.dart';
import 'bird_detail_screen.dart';
import 'new_document_screen.dart';

class DocumentsScreen extends StatefulWidget {
  final AppState appState;
  const DocumentsScreen({super.key, required this.appState});

  @override
  State<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen> {
  final _ctrl = TextEditingController();
  String _type = 'Tous';

  @override
  Widget build(BuildContext context) {
    final appState = widget.appState;
    final allDocs = appState.allDocuments;
    final types = ['Tous', ...{for (final e in allDocs) e.value.type}];
    final q = _ctrl.text.trim().toLowerCase();

    var docs = allDocs;
    if (_type != 'Tous') docs = docs.where((e) => e.value.type == _type).toList();
    if (q.isNotEmpty) {
      docs = docs.where((e) {
        final sp = appState.speciesBySci(e.key.sci);
        return e.key.ring.toLowerCase().contains(q) ||
            e.value.type.toLowerCase().contains(q) ||
            e.value.fileName.toLowerCase().contains(q) ||
            (sp?.label.toLowerCase().contains(q) ?? false);
      }).toList();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Documents'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => NewDocumentScreen(appState: appState)),
              );
              setState(() {});
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _ctrl,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              hintText: 'Bague, espèce, type de document',
              prefixIcon: Icon(Icons.search, size: 20),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: types.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) => ChoiceChip(
                label: Text(types[i]),
                selected: _type == types[i],
                onSelected: (_) => setState(() => _type = types[i]),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text('${docs.length} document${docs.length > 1 ? 's' : ''}', style: const TextStyle(fontSize: 12, color: AppColors.mute)),
          const SizedBox(height: 8),
          if (docs.isEmpty) const EmptyHint('Aucun document ne correspond.'),
          for (final e in docs)
            InfoCard(
              leading: CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.navy,
                child: Icon(iconFor('doc'), color: Colors.white, size: 18),
              ),
              title: e.value.type,
              subtitle: '${e.key.ring} · ${appState.speciesBySci(e.key.sci)?.label ?? e.key.sci} · ${e.value.fileName}',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => BirdDetailScreen(appState: appState, ring: e.key.ring),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
