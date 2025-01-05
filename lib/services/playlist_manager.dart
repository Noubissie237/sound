import 'package:sound/models/song.dart';

class PlaylistManager {
  final List<Song> _playlist = [];
  int _currentIndex = -1;

  // Getters
  List<Song> get playlist => List.unmodifiable(_playlist);
  Song? get currentSong => _currentIndex >= 0 ? _playlist[_currentIndex] : null;
  bool get hasNext => _playlist.isNotEmpty;
  bool get hasPrevious => _playlist.isNotEmpty;

  void setPlaylist(List<Song> songs, {int startIndex = 0}) {
    _playlist.clear();
    _playlist.addAll(songs);
    _currentIndex = startIndex.clamp(0, songs.length - 1);
  }

  Song? nextSong() {
    if (_playlist.isEmpty) return null;
    _currentIndex =
        (_currentIndex + 1) % _playlist.length; // Circular navigation
    return currentSong;
  }

  Song? previousSong() {
    if (_playlist.isEmpty) return null;
    _currentIndex = (_currentIndex - 1 + _playlist.length) %
        _playlist.length; // Circular navigation
    return currentSong;
  }

  void addSong(Song song) {
    _playlist.add(song);
  }

  void removeSong(Song song) {
    final index = _playlist.indexOf(song);
    if (index != -1) {
      if (index <= _currentIndex) {
        _currentIndex--;
      }
      _playlist.removeAt(index);
    }
  }

  void shuffle() {
    if (_playlist.isEmpty) return;
    final currentSong = this.currentSong;
    _playlist.shuffle();
    if (currentSong != null) {
      _currentIndex = _playlist.indexOf(currentSong);
    }
  }
}
