import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

Future<String> getLocalImagePath(String assetPath) async {
  final byteData = await rootBundle.load(assetPath);

  final tempDir = await getTemporaryDirectory();

  final filePath = '${tempDir.path}/${assetPath.split('/').last}';

  final file = File(filePath);
  if (!(await file.exists())) {
    await file.writeAsBytes(byteData.buffer.asUint8List());
  }

  return filePath;
}
