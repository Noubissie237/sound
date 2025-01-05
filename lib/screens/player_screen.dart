import 'package:flutter/material.dart';
import 'package:sound/models/song.dart';
import 'package:sound/services/audio_player_service.dart';
import 'package:sound/widgets/audio_visualizer.dart';
import 'package:sound/widgets/player_controls.dart';

class PlayerScreen extends StatelessWidget {
  final Song initialSong;
  final AudioPlayerService playerService;

  const PlayerScreen({
    super.key,
    required this.initialSong,
    required this.playerService,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Song?>(
      // Ajoutez cette méthode dans AudioPlayerService pour obtenir la chanson en cours
      stream: playerService.currentSongStream,
      initialData: initialSong,
      builder: (context, snapshot) {
        final currentSong = snapshot.data ?? initialSong;

        return Scaffold(
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.keyboard_arrow_down),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.playlist_play),
                onPressed: () {
                  // Implémenter l'ouverture de la playlist
                },
              ),
              IconButton(
                icon: const Icon(Icons.more_vert),
                onPressed: () {
                  // Implémenter le menu d'options
                },
              ),
            ],
          ),
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Theme.of(context).primaryColor.withOpacity(0.2),
                  Theme.of(context).scaffoldBackgroundColor,
                ],
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  const Spacer(),
                  // Visualiseur audio avec animation
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 500),
                    transitionBuilder:
                        (Widget child, Animation<double> animation) {
                      return FadeTransition(
                        opacity: animation,
                        child: ScaleTransition(
                          scale: animation,
                          child: child,
                        ),
                      );
                    },
                    child: AudioVisualizer(
                      key: ValueKey('visualizer-${currentSong.id}'),
                      playerService: playerService,
                    ),
                  ),
                  const SizedBox(height: 40),
                  // Informations sur la chanson avec animation
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 400),
                    transitionBuilder:
                        (Widget child, Animation<double> animation) {
                      return SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0.0, 0.2),
                          end: Offset.zero,
                        ).animate(CurvedAnimation(
                          parent: animation,
                          curve: Curves.easeOutCubic,
                        )),
                        child: FadeTransition(
                          opacity: animation,
                          child: child,
                        ),
                      );
                    },
                    child: _SongInfo(
                      key: ValueKey('info-${currentSong.id}'),
                      song: currentSong,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Contrôles du lecteur
                  PlayerControls(
                    playerService: playerService,
                    song: currentSong,
                  ),
                  const Spacer(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SongInfo extends StatelessWidget {
  final Song song;

  const _SongInfo({
    super.key,
    required this.song,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          Text(
            song.title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Text(
            song.artist,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.grey,
                ),
            textAlign: TextAlign.center,
          ),
          if (song.album.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              song.album,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.withOpacity(0.7),
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}
