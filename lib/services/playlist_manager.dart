import 'package:sound/models/song.dart';

class PlaylistManager {
  final List<Song> _playlist = [];
  int _currentIndex = -1;

  // Getters
  List<Song> get playlist => List.unmodifiable(_playlist);
  Song? get currentSong => _currentIndex >= 0 ? _playlist[_currentIndex] : null;
  bool get hasNext => _currentIndex < _playlist.length - 1;
  bool get hasPrevious => _currentIndex > 0;

  void setPlaylist(List<Song> songs, {int startIndex = 0}) {
    _playlist.clear();
    _playlist.addAll(songs);
    _currentIndex = startIndex.clamp(0, songs.length - 1);
  }

  Song? nextSong() {
    if (hasNext) {
      _currentIndex++;
      return currentSong;
    }
    return null;
  }

  Song? previousSong() {
    if (hasPrevious) {
      _currentIndex--;
      return currentSong;
    }
    return null;
  }

  void addSong(Song song) {
    _playlist.add(song);
  }

  void removeSong(Song song) {
    final index = _playlist.indexOf(song);
    if (index <= _currentIndex) {
      _currentIndex--;
    }
    _playlist.remove(song);
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