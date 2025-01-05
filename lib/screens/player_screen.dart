import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sound/models/song.dart';
import 'package:sound/services/audio_player_service.dart';
import 'package:sound/widgets/audio_visualizer.dart';
import 'package:sound/widgets/player_controls.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

class PlayerScreen extends StatefulWidget {
  final Song initialSong;
  final AudioPlayerService playerService;

  const PlayerScreen({
    super.key,
    required this.initialSong,
    required this.playerService,
  });

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  final GlobalKey shuffleKey = GlobalKey();
  late TutorialCoachMark tutorialCoachMark;
  List<TargetFocus> targets = [];

  @override
  void initState() {
    super.initState();
    _checkFirstSeen();
  }

  Future<void> _checkFirstSeen() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool seen = (prefs.getBool('tutorial_seen') ?? false);

    if (!seen) {
      _initTargets();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showTutorial();
      });
      await prefs.setBool('tutorial_seen', true);
    }
  }

  void _initTargets() {
    targets = [
      TargetFocus(
        identify: "shuffle",
        keyTarget: shuffleKey,
        shape: ShapeLightFocus.Circle,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            builder: (context, controller) {
              return Container(
                padding: const EdgeInsets.all(15),
                child: Align(
                  alignment: Alignment.topCenter,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      const Text(
                        "Lecture aléatoire",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        "Cliquez ici pour commencer la lecture aléatoire de votre album",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    ];
  }

  void showTutorial() {
    tutorialCoachMark = TutorialCoachMark(
      targets: targets,
      colorShadow: Colors.black,
      paddingFocus: 10,
      opacityShadow: 0.8,
      onFinish: () {
        print("Tutoriel terminé");
      },
      onClickTarget: (target) {
        print('Cible ${target.identify} cliquée');
      },
      onSkip: () {
        print("Tutoriel ignoré");
        return true;
      },
    );
    tutorialCoachMark.show(context: context);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Song?>(
      stream: widget.playerService.currentSongStream,
      initialData: widget.initialSong,
      builder: (context, snapshot) {
        final currentSong = snapshot.data ?? widget.initialSong;

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
                key: shuffleKey,
                icon: const Icon(Icons.shuffle),
                tooltip: 'Lecture aléatoire',
                onPressed: () {
                  final songs = [
                    ...widget.playerService.playlistManager.playlist
                  ];
                  songs.shuffle();
                  if (songs.isNotEmpty) {
                    widget.playerService.playPlaylist(songs);
                    widget.playerService.toggleShuffle();
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
                        playerService: widget.playerService,
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
                      Share.shareXFiles([XFile(currentSong.path)]);
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
                      playerService: widget.playerService,
                    ),
                  ),
                  const SizedBox(height: 40),
                  StreamBuilder<bool>(
                    stream: widget.playerService.playerStateStream
                        .map((_) => widget.playerService.isShuffleEnabled),
                    initialData: widget.playerService.isShuffleEnabled,
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
                    playerService: widget.playerService,
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
