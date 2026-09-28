import 'dart:convert';
import 'dart:io' show gzip;

/// Taille maximale d'un morceau, en caractères. Le texte produit est de l'ASCII
/// pur (base64) : 1 caractère = 1 octet, donc bien sous la limite de 1 Mo par
/// document de Firestore.
const int kChunkSize = 700000;

/// Transforme les données de l'appli en texte compressé (gzip puis base64),
/// découpé en morceaux. Pour la plupart des élevages, un seul morceau suffit.
List<String> encodeSnapshot(Map<String, dynamic> data) {
  final bytes = utf8.encode(jsonEncode(data));
  final packed = base64Encode(gzip.encode(bytes));
  final chunks = <String>[];
  for (var i = 0; i < packed.length; i += kChunkSize) {
    final end = i + kChunkSize > packed.length ? packed.length : i + kChunkSize;
    chunks.add(packed.substring(i, end));
  }
  if (chunks.isEmpty) chunks.add('');
  return chunks;
}

/// Opération inverse de [encodeSnapshot].
Map<String, dynamic> decodeSnapshot(List<String> chunks) {
  final packed = chunks.join();
  final bytes = gzip.decode(base64Decode(packed));
  return jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
}
