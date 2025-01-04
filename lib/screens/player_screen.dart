import 'package:flutter/material.dart';
import 'package:sound/models/song.dart';
import 'package:sound/services/audio_player_service.dart';
import 'package:sound/widgets/player_controls.dart';

class PlayerScreen extends StatelessWidget {
  final Song song;
  final AudioPlayerService playerService;

  const PlayerScreen({
    super.key,
    required this.song,
    required this.playerService,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Now Playing'),
        elevation: 0,
      ),
      body: Column(
        children: [
          const Spacer(),
          // Zone de l'image de la chanson (à implémenter plus tard)
          Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              color: Colors.grey[800],
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.music_note,
              size: 100,
              color: Colors.white54,
            ),
          ),
          const SizedBox(height: 32),
          // Informations sur la chanson
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                Text(
                  song.title,
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  song.artist,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          // Contrôles du lecteur
          PlayerControls(
            playerService: playerService,
            song: song,
          ),
          const Spacer(),
        ],
      ),
    );
  }
}