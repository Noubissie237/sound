import 'package:flutter/material.dart';
import 'package:sound/models/playlist.dart';
import 'package:sound/models/song.dart';
import 'package:sound/services/playlist_storage_service.dart';
import 'package:sound/services/audio_player_service.dart';

class PlaylistDetailScreen extends StatefulWidget {
  final Playlist playlist;
  final PlaylistStorageService storageService;

  const PlaylistDetailScreen({
    super.key,
    required this.playlist,
    required this.storageService,
  });

  @override
  State<PlaylistDetailScreen> createState() => _PlaylistDetailScreenState();
}

class _PlaylistDetailScreenState extends State<PlaylistDetailScreen> {
  late AudioPlayerService playerService;
  List<Song> _playlistSongs = [];

  @override
  void initState() {
    super.initState();
    playerService = AudioPlayerService();
    _loadPlaylistSongs();
  }

  Future<void> _loadPlaylistSongs() async {
    // Charger les chansons de la playlist
    // Note: plus tard, je vais implémenter une méthode pour récupérer les chansons par ID
    setState(() {
      // _playlistSongs = ...
    });
  }

  Future<void> _editPlaylistInfo() async {
    final nameController = TextEditingController(text: widget.playlist.name);
    final descController = TextEditingController(text: widget.playlist.description);

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Modifier la playlist'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Nom'),
            ),
            TextField(
              controller: descController,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty) {
                widget.playlist.name = nameController.text;
                widget.playlist.description = descController.text;
                await widget.storageService.updatePlaylist(widget.playlist);
                if (mounted) {
                  Navigator.pop(context);
                  setState(() {});
                }
              }
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }

  Future<void> _addSongs() async {
    await showDialog(
      context: context,
      builder: (context) => const AlertDialog(
        title: Text('Ajouter des chansons'),
        content: Text('Fonctionnalité à implémenter'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.playlist.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _editPlaylistInfo,
          ),
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'delete') {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Supprimer la playlist'),
                    content: const Text('Êtes-vous sûr de vouloir supprimer cette playlist ?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Annuler'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Supprimer'),
                      ),
                    ],
                  ),
                );

                if (confirmed == true) {
                  await widget.storageService.deletePlaylist(widget.playlist.id);
                  if (mounted) {
                    Navigator.pop(context);
                  }
                }
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'delete',
                child: Text('Supprimer la playlist'),
              ),
            ],
          ),
        ],
      ),
      body: _playlistSongs.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Aucune chanson dans cette playlist'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _addSongs,
                    child: const Text('Ajouter des chansons'),
                  ),
                ],
              ),
            )
          : ReorderableListView.builder(
              itemCount: _playlistSongs.length,
              onReorder: (oldIndex, newIndex) {
                setState(() {
                  if (newIndex > oldIndex) {
                    newIndex -= 1;
                  }
                  final item = _playlistSongs.removeAt(oldIndex);
                  _playlistSongs.insert(newIndex, item);
                  // Mettre à jour l'ordre des IDs dans la playlist
                  widget.playlist.songIds = _playlistSongs.map((s) => s.id).toList();
                  widget.storageService.updatePlaylist(widget.playlist);
                });
              },
              itemBuilder: (context, index) {
                final song = _playlistSongs[index];
                return ListTile(
                  key: Key(song.id),
                  title: Text(song.title),
                  subtitle: Text(song.artist),
                  trailing: IconButton(
                    icon: const Icon(Icons.remove_circle_outline),
                    onPressed: () async {
                      setState(() {
                        widget.playlist.songIds.remove(song.id);
                        _playlistSongs.remove(song);
                      });
                      await widget.storageService.updatePlaylist(widget.playlist);
                    },
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addSongs,
        child: const Icon(Icons.add),
      ),
    );
  }
}