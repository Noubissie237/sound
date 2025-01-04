import 'package:flutter/material.dart';
import 'package:sound/models/song.dart';
import 'dart:io';

class SongDetailsScreen extends StatelessWidget {
  final Song song;

  const SongDetailsScreen({super.key, required this.song});

  String _formatFileSize(File file) {
    final bytes = file.lengthSync();
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    final file = File(song.path);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Détails de la chanson'),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Informations',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const Divider(),
                  _DetailItem(
                    icon: Icons.title,
                    label: 'Titre',
                    value: song.title,
                  ),
                  _DetailItem(
                    icon: Icons.person,
                    label: 'Artiste',
                    value: song.artist,
                  ),
                  _DetailItem(
                    icon: Icons.album,
                    label: 'Album',
                    value: song.album,
                  ),
                  _DetailItem(
                    icon: Icons.timer,
                    label: 'Durée',
                    value: '${song.duration.inMinutes}:${(song.duration.inSeconds % 60).toString().padLeft(2, '0')}',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Fichier',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const Divider(),
                  _DetailItem(
                    icon: Icons.folder,
                    label: 'Chemin',
                    value: song.path,
                  ),
                  _DetailItem(
                    icon: Icons.data_usage,
                    label: 'Taille',
                    value: _formatFileSize(file),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}