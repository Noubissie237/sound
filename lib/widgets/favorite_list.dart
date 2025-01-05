import 'package:flutter/material.dart';
import 'package:sound/models/song.dart';
import 'package:sound/services/user_preferences_service.dart';
import 'package:sound/services/audio_player_service.dart';

class FavoritesList extends StatefulWidget {
  final UserPreferencesService preferencesService;

  const FavoritesList({
    super.key,
    required this.preferencesService,
  });

  @override
  State<FavoritesList> createState() => _FavoritesListState();
}

class _FavoritesListState extends State<FavoritesList> {
  late List<Song> _favorites;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  void _loadFavorites() {
    final favoritesJson = widget.preferencesService.getFavorites();
    setState(() {
      _favorites = favoritesJson.map((json) => Song.fromJson(json)).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_favorites.isEmpty) {
      return const Center(
        child: Text(
          'Aucun favori pour le moment',
          style: TextStyle(fontSize: 16),
        ),
      );
    }

    return ListView.builder(
      itemCount: _favorites.length,
      itemBuilder: (context, index) {
        final song = _favorites[index];
        return ListTile(
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.music_note,
              color: Theme.of(context).primaryColor,
            ),
          ),
          title: Text(song.title),
          subtitle: Text(song.artist),
          trailing: IconButton(
            icon: const Icon(Icons.favorite, color: Colors.red),
            onPressed: () async {
              await widget.preferencesService.toggleFavorite(song);
              _loadFavorites();
            },
          ),
          onTap: () async {
            final playerService = AudioPlayerService();
            playerService.playlistManager
                .setPlaylist(_favorites, startIndex: index);
            await playerService.playSong(song);
          },
        );
      },
    );
  }
}
