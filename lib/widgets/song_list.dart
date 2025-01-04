import 'package:flutter/material.dart';
import 'package:sound/models/song.dart';
import 'package:sound/screens/player_screen.dart';
import 'package:sound/services/audio_scanner.dart';
import 'package:sound/services/audio_player_service.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';

import 'package:sound/widgets/mini_player.dart';

class SongList extends StatefulWidget {
  const SongList({super.key});

  @override
  State<SongList> createState() => _SongListState();
}

class _SongListState extends State<SongList> {
  final AudioScanner _scanner = AudioScanner();
  final AudioPlayerService _playerService = AudioPlayerService();
  List<Song> _songs = [];
  Song? _currentSong;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _loadSongs();
    _setupAudioPlayerListeners();
  }

  void _setupAudioPlayerListeners() {
    _playerService.currentSongStream.listen((song) {
      if (mounted) {
        setState(() {
          _currentSong = song;
        });
      }
    });
  }

  Future<void> _loadSongs() async {
    try {
      print("Début du scan des fichiers audio...");
      final songs = await _scanner.scanDevice();
      print("Nombre de chansons trouvées: ${songs.length}");

      if (mounted) {
        setState(() {
          _songs = songs;
          if (songs.isNotEmpty) {
            _playerService.playlistManager.setPlaylist(songs);
          }
        });
      }
    } catch (e) {
      print("Erreur lors du chargement des chansons: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Erreur lors du chargement des chansons"),
          ),
        );
      }
    }
  }

  void _showSongOptions(Song song, int index) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.play_arrow),
                title: const Text('Play Now'),
                onTap: () async {
                  Navigator.pop(context);
                  _playerService.playlistManager
                      .setPlaylist(_songs, startIndex: index);
                  await _playerService.playSong(song);
                  if (mounted) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PlayerScreen(
                          song: song,
                          playerService: _playerService,
                        ),
                      ),
                    );
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.queue),
                title: const Text('Play Next'),
                onTap: () {
                  // Implémenter la logique pour jouer ensuite
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Added to play next')),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Rename'),
                onTap: () {
                  Navigator.pop(context);
                  _showRenameDialog(song);
                },
              ),
              ListTile(
                leading: const Icon(Icons.favorite_border),
                title: const Text('Add to Favorites'),
                onTap: () {
                  // Implémenter la logique des favoris
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Added to favorites')),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete),
                title: const Text('Delete'),
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteConfirmation(song);
                },
              ),
              ListTile(
                leading: const Icon(Icons.info),
                title: const Text('File Info'),
                onTap: () {
                  Navigator.pop(context);
                  _showFileInfo(song);
                },
              ),
              ListTile(
                leading: const Icon(Icons.share),
                title: const Text('Share'),
                onTap: () async {
                  Navigator.pop(context);
                  await Share.shareXFiles([XFile(song.path)]);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showRenameDialog(Song song) {
    final TextEditingController controller =
        TextEditingController(text: song.title);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Rename Song'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'New name',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                // Implémenter la logique de renommage
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Song renamed')),
                );
              },
              child: const Text('Rename'),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteConfirmation(Song song) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Song'),
          content: const Text('Are you sure you want to delete this song?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                try {
                  final file = File(song.path);
                  await file.delete();
                  setState(() {
                    _songs.remove(song);
                  });
                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Song deleted')),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Error deleting song')),
                    );
                  }
                }
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  void _showFileInfo(Song song) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('File Information'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Title: ${song.title}'),
              Text('Artist: ${song.artist}'),
              Text('Album: ${song.album}'),
              Text('Path: ${song.path}'),
              Text('Duration: ${song.duration.inSeconds} seconds'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _playerService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_songs.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Recherche de musique...'),
          ],
        ),
      );
    }

    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              '${_songs.length} songs found',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _songs.length,
              itemBuilder: (context, index) {
                final song = _songs[index];
                final isCurrentSong = _currentSong?.id == song.id;

                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor:
                        isCurrentSong ? Theme.of(context).primaryColor : null,
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        color: isCurrentSong ? Colors.white : null,
                      ),
                    ),
                  ),
                  title: Text(
                    song.title,
                    style: TextStyle(
                      color:
                          isCurrentSong ? Theme.of(context).primaryColor : null,
                      fontWeight: isCurrentSong ? FontWeight.bold : null,
                    ),
                  ),
                  subtitle: Text(song.artist),
                  trailing: IconButton(
                    icon: const Icon(Icons.more_vert),
                    onPressed: () => _showSongOptions(song, index),
                  ),
                  onTap: () => _playSong(song),
                );
              },
            ),
          ),
        ],
      ),
      bottomSheet: MiniPlayer(
        playerService: _playerService,
        currentSong: _currentSong,
        onTap: () {
          if (_currentSong != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PlayerScreen(
                  song: _currentSong!,
                  playerService: _playerService,
                ),
              ),
            );
          }
        },
      ),
    );
  }

  void _playSong(Song song) async {
    final index = _songs.indexOf(song);
    _playerService.playlistManager.setPlaylist(_songs, startIndex: index);
    await _playerService.playSong(song);
    setState(() {
      _currentSong = song;
      _isPlaying = true;
    });
  }
}
