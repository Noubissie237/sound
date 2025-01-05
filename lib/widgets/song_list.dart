import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sound/models/song.dart';
import 'package:sound/screens/player_screen.dart';
import 'package:sound/services/audio_scanner.dart';
import 'package:sound/services/audio_player_service.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sound/services/user_preferences_service.dart';
import 'package:sound/theme/app_theme.dart';
import 'package:sound/widgets/delete_confirmation_dialog.dart';
import 'package:sound/widgets/empty_view.dart';
import 'package:sound/widgets/file_info_dialog.dart';
import 'package:sound/widgets/loading_view.dart';
import 'package:sound/widgets/mini_player.dart';
import 'package:sound/widgets/rename_dialog.dart';
import 'package:sound/widgets/song_option_sheet.dart';

enum SongListFilter { all, favorites, history, stats }

class SongList extends StatefulWidget {
  final SongListFilter filter;

  const SongList({
    super.key,
    required this.filter,
  });

  @override
  State<SongList> createState() => _SongListState();
}

class _SongListState extends State<SongList> {
  final TextEditingController _searchController = TextEditingController();
  final AudioScanner _scanner = AudioScanner();
  final AudioPlayerService _playerService = AudioPlayerService();
  List<Song> _allSongs = [];
  List<Song> _displayedSongs = [];
  Song? _currentSong;
  bool _isLoading = true;
  bool _isSearching = false;
  late UserPreferencesService _preferencesService;
  int _currentTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_handleSearch);
    _initializePlayer();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _playerService.dispose();
    super.dispose();
  }

  void _handleSearch() {
    final searchTerm = _searchController.text.toLowerCase();
    if (searchTerm.isEmpty) {
      _filterSongs();
      return;
    }

    List<Song> filteredSongs;
    switch (widget.filter) {
      case SongListFilter.favorites:
        filteredSongs = _allSongs
            .where((song) => _preferencesService.isFavorite(song))
            .toList();
        break;
      case SongListFilter.history:
        // Implémenter la logique de l'historique ici
        filteredSongs = _allSongs;
        break;
      case SongListFilter.stats:
        // Implémenter la logique des stats ici
        filteredSongs = _allSongs;
        break;
      case SongListFilter.all:
        filteredSongs = _allSongs;
        break;
    }

    setState(() {
      _displayedSongs = filteredSongs.where((song) {
        return song.title.toLowerCase().contains(searchTerm) ||
            song.artist.toLowerCase().contains(searchTerm);
      }).toList();
    });

    _playerService.playlistManager.setPlaylist(_displayedSongs);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _preferencesService =
        Provider.of<UserPreferencesService>(context, listen: false);
  }

  @override
  void didUpdateWidget(SongList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.filter != widget.filter) {
      _filterSongs();
    }
  }

  void _filterSongs() {
    switch (widget.filter) {
      case SongListFilter.all:
        _displayedSongs = _allSongs;
        break;
      case SongListFilter.favorites:
        _displayedSongs = _allSongs
            .where((song) => _preferencesService.isFavorite(song))
            .toList();
        break;
      case SongListFilter.history:
        // Implement history filtering here
        _displayedSongs = _allSongs;
        break;
      case SongListFilter.stats:
        // Implement stats filtering here
        _displayedSongs = _allSongs;
        break;
    }
    _playerService.playlistManager.setPlaylist(_displayedSongs);
    setState(() {});
  }

  Future<void> _initializePlayer() async {
    await _loadSongs();
    _setupAudioPlayerListeners();
    if (mounted) {
      setState(() {
        _isLoading = false;
        _filterSongs(); 
      });
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
          _allSongs = songs;
          _filterSongs();
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
      final index = _displayedSongs.indexOf(song);
      _playerService.playlistManager
          .setPlaylist(_displayedSongs, startIndex: index);
      await _playerService.playSong(song);
      setState(() => _currentSong = song);
    } catch (e) {
      _showErrorSnackBar('Erreur lors de la lecture');
    }
  }

  Widget _buildSongTile(Song song, int index) {
    final isCurrentSong = _currentSong?.id == song.id;
    final theme = Theme.of(context);
    final isFavorite = _preferencesService.isFavorite(song);
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

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
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(
              isFavorite ? Icons.favorite : Icons.favorite_border,
              color: isFavorite
                  ? isDarkMode
                      ? AppTheme.primaryDark
                      : AppTheme.primaryLight
                  : null,
            ),
            onPressed: () => _toggleFavorite(song),
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () => _showSongOptions(song, index),
          ),
        ],
      ),
      onTap: () => _playSong(song),
    );
  }

  Future<void> _toggleFavorite(Song song) async {
    await _preferencesService.toggleFavorite(song);
    await _preferencesService.addToHistory(song);
    setState(() {}); // Rafraîchir l'UI
    _showSuccessSnackBar(
      _preferencesService.isFavorite(song)
          ? 'Ajouté aux favoris'
          : 'Retiré des favoris',
    );
  }

  void _handleAddToFavorites(Song song) {
    _toggleFavorite(song);
    _showSuccessSnackBar('Ajouté aux favoris');
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
    _playerService.playlistManager
        .setPlaylist(_displayedSongs, startIndex: index);
    await _playerService.playSong(song);
    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PlayerScreen(
          initialSong: song,
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
      // Implémentation à venir
      _showSuccessSnackBar('Chanson renommée');
    }
  }

  Future<void> _handleDelete(Song song) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => const DeleteConfirmationDialog(),
    );

    if (shouldDelete ?? false) {
      try {
        await File(song.path).delete();
        setState(() => _allSongs.remove(song));
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
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const LoadingView();
    }

    final String headerTitle;
    final String itemCount;

    switch (widget.filter) {
      case SongListFilter.favorites:
        headerTitle = 'Mes Favoris';
        itemCount =
            '${_displayedSongs.length} favori${_displayedSongs.length > 1 ? 's' : ''}';
        break;
      case SongListFilter.history:
        headerTitle = 'Historique';
        itemCount =
            '${_displayedSongs.length} morceau${_displayedSongs.length > 1 ? 'x' : ''}';
        break;
      case SongListFilter.stats:
        headerTitle = 'Statistiques';
        itemCount =
            '${_displayedSongs.length} morceau${_displayedSongs.length > 1 ? 'x' : ''}';
        break;
      case SongListFilter.all:
        headerTitle = 'Ma Bibliothèque';
        itemCount =
            '${_displayedSongs.length} morceau${_displayedSongs.length > 1 ? 'x' : ''} trouvé${_displayedSongs.length > 1 ? 's' : ''}';
    }

    return Scaffold(
      body: Column(
        children: [
          buildHeader(title: headerTitle, subtitle: itemCount),
          Expanded(
            child: _displayedSongs.isEmpty
                ? EmptyView(message: _getEmptyViewMessage())
                : ListView.builder(
                    itemCount: _displayedSongs.length,
                    itemBuilder: (context, index) =>
                        _buildSongTile(_displayedSongs[index], index),
                  ),
          ),
        ],
      ),
      bottomSheet: MiniPlayer(
        playerService: _playerService,
        currentSong: _currentSong,
        onTap: () {
          if (_currentSong == null) return;

          _navigateToPlayerScreen();
        },
      ),
    );
  }

  String _getEmptyViewMessage() {
    switch (widget.filter) {
      case SongListFilter.favorites:
        return 'Aucun favori pour le moment\nAppuyez sur le cœur pour en ajouter';
      case SongListFilter.history:
        return 'Aucun historique disponible\nÉcoutez de la musique pour commencer';
      case SongListFilter.stats:
        return 'Aucune statistique disponible\nÉcoutez de la musique pour commencer';
      case SongListFilter.all:
        return 'Aucune musique trouvée\nAjoutez des fichiers audio à votre appareil';
    }
  }

  Widget buildHeader({required String title, required String subtitle}) {
    return Column(
      children: [
        Container(
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
          child: Column(
            children: [
              Padding(
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
                        _getHeaderIcon(),
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.color,
                                  ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    IconButton(
                      icon: Icon(_isSearching ? Icons.close : Icons.search),
                      onPressed: () {
                        setState(() {
                          _isSearching = !_isSearching;
                          if (!_isSearching) {
                            _searchController.clear();
                          }
                        });
                      },
                    ),
                  ],
                ),
              ),
              if (_isSearching)
                Padding(
                  padding: const EdgeInsets.only(
                    left: 16,
                    right: 16,
                    bottom: 16,
                  ),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Rechercher par titre ou artiste...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      filled: true,
                      fillColor: Theme.of(context).cardColor,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => _handleSearch(),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  IconData _getHeaderIcon() {
    switch (_currentTabIndex) {
      case 1:
        return Icons.favorite;
      case 2:
        return Icons.history;
      case 3:
        return Icons.bar_chart;
      default:
        return Icons.music_note;
    }
  }

  void _navigateToPlayerScreen() {
    if (_currentSong == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PlayerScreen(
          initialSong: _currentSong!,
          playerService: _playerService,
        ),
      ),
    );
  }
}
