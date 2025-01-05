import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

Future<String> getLocalImagePath(String assetPath) async {
  // Charger l'image depuis les assets
  final byteData = await rootBundle.load(assetPath);

  // Obtenir le répertoire temporaire
  final tempDir = await getTemporaryDirectory();

  // Définir un chemin pour l'image temporaire
  final filePath = '${tempDir.path}/${assetPath.split('/').last}';

  // Écrire l'image dans un fichier temporaire
  final file = File(filePath);
  if (!(await file.exists())) {
    await file.writeAsBytes(byteData.buffer.asUint8List());
  }

  return filePath;
}
