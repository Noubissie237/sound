import 'package:flutter/material.dart';
import 'package:sound/models/playlist.dart';
import 'package:sound/screens/playlist_detail_screen.dart';
import 'package:sound/services/playlist_storage_service.dart';

class PlaylistsScreen extends StatefulWidget {
  final PlaylistStorageService storageService;

  const PlaylistsScreen({super.key, required this.storageService});

  @override
  State<PlaylistsScreen> createState() => _PlaylistsScreenState();
}

class _PlaylistsScreenState extends State<PlaylistsScreen> {
  List<Playlist> _playlists = [];

  @override
  void initState() {
    super.initState();
    _loadPlaylists();
  }

  Future<void> _loadPlaylists() async {
    final playlists = await widget.storageService.getPlaylists();
    setState(() {
      _playlists = playlists;
    });
  }

  Future<void> _createPlaylist() async {
    final nameController = TextEditingController();
    final descController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nouvelle Playlist'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Nom',
                hintText: 'Entrez le nom de la playlist',
              ),
            ),
            TextField(
              controller: descController,
              decoration: const InputDecoration(
                labelText: 'Description (optionnel)',
                hintText: 'Entrez une description',
              ),
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
                await widget.storageService.createPlaylist(
                  nameController.text,
                  description: descController.text.isEmpty ? null : descController.text,
                );
                if (mounted) {
                  Navigator.pop(context);
                  _loadPlaylists();
                }
              }
            },
            child: const Text('Créer'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes Playlists'),
        elevation: 0,
      ),
      body: _playlists.isEmpty
          ? const Center(
              child: Text('Aucune playlist'),
            )
          : ListView.builder(
              itemCount: _playlists.length,
              itemBuilder: (context, index) {
                final playlist = _playlists[index];
                return ListTile(
                  leading: const Icon(Icons.queue_music),
                  title: Text(playlist.name),
                  subtitle: playlist.description != null
                      ? Text(playlist.description!)
                      : null,
                  trailing: Text('${playlist.songIds.length} titres'),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PlaylistDetailScreen(
                          playlist: playlist,
                          storageService: widget.storageService,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createPlaylist,
        child: const Icon(Icons.add),
      ),
    );
  }
}