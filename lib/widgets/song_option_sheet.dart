import 'package:flutter/material.dart';
import 'package:sound/models/song.dart';
import 'package:sound/widgets/option_title.dart';

class SongOptionsSheet extends StatelessWidget {
  final Song song;

  const SongOptionsSheet({super.key, required this.song});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          OptionTile(
            icon: Icons.play_arrow,
            title: 'Lire maintenant',
            onTap: () => Navigator.pop(context, 'play'),
          ),
          OptionTile(
            icon: Icons.queue,
            title: 'Lire ensuite',
            onTap: () => Navigator.pop(context, 'next'),
          ),
          OptionTile(
            icon: Icons.edit,
            title: 'Renommer',
            onTap: () => Navigator.pop(context, 'rename'),
          ),
          OptionTile(
            icon: Icons.favorite_border,
            title: 'Ajouter aux favoris',
            onTap: () => Navigator.pop(context, 'favorite'),
          ),
          OptionTile(
            icon: Icons.delete,
            title: 'Supprimer',
            onTap: () => Navigator.pop(context, 'delete'),
          ),
          OptionTile(
            icon: Icons.info,
            title: 'Informations',
            onTap: () => Navigator.pop(context, 'info'),
          ),
          OptionTile(
            icon: Icons.share,
            title: 'Partager',
            onTap: () => Navigator.pop(context, 'share'),
          ),
        ],
      ),
    );
  }
}