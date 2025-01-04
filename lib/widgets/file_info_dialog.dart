
import 'package:flutter/material.dart';
import 'package:sound/models/song.dart';
import 'package:sound/widgets/info_row.dart';

class FileInfoDialog extends StatelessWidget {
  final Song song;

  const FileInfoDialog({super.key, required this.song});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Informations'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InfoRow(label: 'Titre', value: song.title),
          InfoRow(label: 'Artiste', value: song.artist),
          InfoRow(label: 'Album', value: song.album),
          InfoRow(label: 'Chemin', value: song.path),
          InfoRow(
            label: 'Durée',
            value: '${song.duration.inSeconds} secondes',
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Fermer'),
        ),
      ],
    );
  }
}


