import 'package:just_audio/just_audio.dart';
import 'package:sound/models/repeat_mode.dart';
import 'package:sound/models/song.dart';
import 'package:sound/services/playlist_manager.dart';

class AudioPlayerService {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final PlaylistManager _playlistManager = PlaylistManager();

  PlaylistManager get playlistManager => _playlistManager;
  Stream<PlayerState> get playerStateStream => _audioPlayer.playerStateStream;
  Stream<Duration> get positionStream => _audioPlayer.positionStream;
  Stream<Duration?> get durationStream => _audioPlayer.durationStream;

  RepeatMode _repeatMode = RepeatMode.off;

  RepeatMode get repeatMode => _repeatMode;

  void toggleRepeatMode() {
    _repeatMode = _repeatMode.next();
    switch (_repeatMode) {
      case RepeatMode.off:
        _audioPlayer.setLoopMode(LoopMode.off);
        break;
      case RepeatMode.single:
        _audioPlayer.setLoopMode(LoopMode.one);
        break;
      case RepeatMode.all:
        _audioPlayer.setLoopMode(LoopMode.all);
        break;
    }
  }

  Future<void> playSong(Song song) async {
    await _audioPlayer.setFilePath(song.path);
    await _audioPlayer.play();
  }

  Future<void> playNext() async {
    if (_repeatMode == RepeatMode.all && !_playlistManager.hasNext) {
      // Revenir au début de la playlist
      _playlistManager.setPlaylist(_playlistManager.playlist, startIndex: 0);
      await playSong(_playlistManager.currentSong!);
    } else {
      final nextSong = _playlistManager.nextSong();
      if (nextSong != null) {
        await playSong(nextSong);
      }
    }
  }

  Future<void> playPrevious() async {
    final previousSong = _playlistManager.previousSong();
    if (previousSong != null) {
      await playSong(previousSong);
    }
  }

  Future<void> pause() async {
    await _audioPlayer.pause();
  }

  Future<void> resume() async {
    await _audioPlayer.play();
  }

  Future<void> seek(Duration position) async {
    await _audioPlayer.seek(position);
  }

  Future<void> stop() async {
    await _audioPlayer.stop();
  }

  void dispose() {
    _audioPlayer.dispose();
  }
}