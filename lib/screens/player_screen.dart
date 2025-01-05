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
              // Bouton de lecture aléatoire
              IconButton(
                icon: const Icon(Icons.shuffle),
                tooltip: 'Lecture aléatoire',
                onPressed: () {
                  // Obtenir toutes les chansons de la playlist
                  final songs = [...playerService.playlistManager.playlist];
                  // Les mélanger
                  songs.shuffle();
                  // Commencer la lecture
                  if (songs.isNotEmpty) {
                    playerService.playPlaylist(songs);
                    // Activer le mode shuffle
                    playerService.toggleShuffle();
                  }
                },
              ),
              IconButton(
                icon: const Icon(Icons.playlist_play),
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    backgroundColor: Colors.transparent,
                    builder: (context) => Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).scaffoldBackgroundColor,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(20),
                        ),
                      ),
                      child: PlaylistView(
                        playerService: playerService,
                        currentSong: currentSong,
                      ),
                    ),
                  );
                },
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                onSelected: (value) {
                  switch (value) {
                    case 'info':
                      _showSongInfo(context, currentSong);
                      break;
                    case 'share':
                      // Implémenter le partage
                      break;
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'info',
                    child: ListTile(
                      leading: Icon(Icons.info_outline),
                      title: Text('Informations'),
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'share',
                    child: ListTile(
                      leading: Icon(Icons.share),
                      title: Text('Partager'),
                    ),
                  ),
                ],
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
                  StreamBuilder<bool>(
                    stream: playerService.playerStateStream
                        .map((_) => playerService.isShuffleEnabled),
                    initialData: playerService.isShuffleEnabled,
                    builder: (context, shuffleSnapshot) {
                      return AnimatedSwitcher(
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
                          key: ValueKey(
                              'info-${currentSong.id}-${shuffleSnapshot.data}'),
                          song: currentSong,
                          isShuffleEnabled: shuffleSnapshot.data ?? false,
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
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

  void _showSongInfo(BuildContext context, Song song) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Informations'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Titre: ${song.title}'),
            const SizedBox(height: 8),
            Text('Artiste: ${song.artist}'),
            if (song.album.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('Album: ${song.album}'),
            ],
            const SizedBox(height: 8),
            Text('Durée: ${song.duration.toString().split('.').first}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }
}

class _SongInfo extends StatelessWidget {
  final Song song;
  final bool isShuffleEnabled;

  const _SongInfo({
    super.key,
    required this.song,
    required this.isShuffleEnabled,
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
          if (isShuffleEnabled) ...[
            const SizedBox(height: 8),
            Text(
              'Mode aléatoire activé',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).primaryColor,
                  ),
            ),
          ],
        ],
      ),
    );
  }
}

class PlaylistView extends StatelessWidget {
  final AudioPlayerService playerService;
  final Song currentSong;

  const PlaylistView({
    super.key,
    required this.playerService,
    required this.currentSong,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Text(
            'File de lecture',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: playerService.playlistManager.playlist.length,
            itemBuilder: (context, index) {
              final song = playerService.playlistManager.playlist[index];
              final isPlaying = song.path == currentSong.path;

              return ListTile(
                leading: isPlaying
                    ? Icon(Icons.music_note,
                        color: Theme.of(context).primaryColor)
                    : const Icon(Icons.music_note_outlined),
                title: Text(
                  song.title,
                  style: TextStyle(
                    fontWeight: isPlaying ? FontWeight.bold : FontWeight.normal,
                    color: isPlaying ? Theme.of(context).primaryColor : null,
                  ),
                ),
                subtitle: Text(song.artist),
                onTap: () => playerService.playSong(song),
              );
            },
          ),
        ),
      ],
    );
  }
}
