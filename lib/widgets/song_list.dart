import 'dart:io';
import 'package:flutter/material.dart';
import 'package:sound/models/song.dart';
import 'package:sound/screens/player_screen.dart';
import 'package:sound/services/audio_scanner.dart';
import 'package:sound/services/audio_player_service.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sound/widgets/delete_confirmation_dialog.dart';
import 'package:sound/widgets/empty_view.dart';
import 'package:sound/widgets/file_info_dialog.dart';
import 'package:sound/widgets/loading_view.dart';
import 'package:sound/widgets/mini_player.dart';
import 'package:sound/widgets/rename_dialog.dart';
import 'package:sound/widgets/song_option_sheet.dart';

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
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    await _loadSongs();
    _setupAudioPlayerListeners();
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  void _setupAudioPlayerListeners() {
    _playerService.currentSongStream.listen(
      (song) {
        if (mounted) setState(() => _currentSong = song);
      },
      onError: (error) {
        _showErrorSnackBar('Erreur de lecture audio');
      },
    );
  }

  Future<void> _loadSongs() async {
    try {
      final songs = await _scanner.scanDevice();
      if (mounted) {
        setState(() {
          _songs = songs;
          if (songs.isNotEmpty) {
            _playerService.playlistManager.setPlaylist(songs);
          }
        });
      }
    } catch (e) {
      _showErrorSnackBar('Erreur lors du chargement des chansons');
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showSuccessSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _playSong(Song song) async {
    try {
      final index = _songs.indexOf(song);
      _playerService.playlistManager.setPlaylist(_songs, startIndex: index);
      await _playerService.playSong(song);
      setState(() => _currentSong = song);
    } catch (e) {
      _showErrorSnackBar('Erreur lors de la lecture');
    }
  }

  Widget _buildSongTile(Song song, int index) {
    final isCurrentSong = _currentSong?.id == song.id;
    final theme = Theme.of(context);

    return ListTile(
      leading: _buildSongNumber(index, isCurrentSong),
      title: Text(
        song.title,
        style: TextStyle(
          color: isCurrentSong ? theme.primaryColor : null,
          fontWeight: isCurrentSong ? FontWeight.bold : null,
        ),
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        song.artist,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: IconButton(
        icon: const Icon(Icons.more_vert),
        onPressed: () => _showSongOptions(song, index),
      ),
      onTap: () => _playSong(song),
    );
  }

  Widget _buildSongNumber(int index, bool isCurrentSong) {
    return CircleAvatar(
      backgroundColor: isCurrentSong
          ? Theme.of(context).primaryColor
          : Theme.of(context).primaryColor.withOpacity(0.1),
      child: Text(
        '${index + 1}',
        style: TextStyle(
          color: isCurrentSong ? Colors.white : Theme.of(context).primaryColor,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Future<void> _showSongOptions(Song song, int index) async {
    final options = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SongOptionsSheet(song: song),
    );

    if (options == null) return;

    switch (options) {
      case 'play':
        await _handlePlayNow(song, index);
        break;
      case 'next':
        _handlePlayNext(song);
        break;
      case 'rename':
        await _handleRename(song);
        break;
      case 'favorite':
        _handleAddToFavorites(song);
        break;
      case 'delete':
        await _handleDelete(song);
        break;
      case 'info':
        _showFileInfo(song);
        break;
      case 'share':
        await Share.shareXFiles([XFile(song.path)]);
        break;
    }
  }

  Future<void> _handlePlayNow(Song song, int index) async {
    _playerService.playlistManager.setPlaylist(_songs, startIndex: index);
    await _playerService.playSong(song);
    if (!mounted) return;

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

  void _handlePlayNext(Song song) {
    // Implémentation à venir
    _showSuccessSnackBar('Ajouté à "Jouer ensuite"');
  }

  Future<void> _handleRename(Song song) async {
    final newTitle = await showDialog<String>(
      context: context,
      builder: (context) => RenameDialog(initialTitle: song.title),
    );

    if (newTitle != null && newTitle.isNotEmpty) {
      // Implémenter la logique de renommage
      _showSuccessSnackBar('Chanson renommée');
    }
  }

  void _handleAddToFavorites(Song song) {
    // Implémenter la logique des favoris
    _showSuccessSnackBar('Ajouté aux favoris');
  }

  Future<void> _handleDelete(Song song) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => const DeleteConfirmationDialog(),
    );

    if (shouldDelete ?? false) {
      try {
        await File(song.path).delete();
        setState(() => _songs.remove(song));
        _showSuccessSnackBar('Chanson supprimée');
      } catch (e) {
        _showErrorSnackBar('Erreur lors de la suppression');
      }
    }
  }

  void _showFileInfo(Song song) {
    showDialog(
      context: context,
      builder: (context) => FileInfoDialog(song: song),
    );
  }

  @override
  void dispose() {
    _playerService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const LoadingView();
    }

    return Scaffold(
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _songs.isEmpty
                ? const EmptyView()
                : ListView.builder(
                    itemCount: _songs.length,
                    itemBuilder: (context, index) =>
                        _buildSongTile(_songs[index], index),
                  ),
          ),
        ],
      ),
      bottomSheet: MiniPlayer(
        playerService: _playerService,
        currentSong: _currentSong,
        onTap: _navigateToPlayerScreen,
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).primaryColor.withOpacity(0.05),
            Theme.of(context).colorScheme.secondary.withOpacity(0.05),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.music_note,
                color: Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ma Bibliothèque',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_songs.length} morceau${_songs.length > 1 ? 'x' : ''} trouvé${_songs.length > 1 ? 's' : ''}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToPlayerScreen() {
    if (_currentSong == null) return;

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
}
