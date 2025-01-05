import 'dart:async';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:sound/models/repeat_mode.dart';
import 'package:sound/models/song.dart';
import 'package:sound/services/playlist_manager.dart';

class AudioPlayerService {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final PlaylistManager _playlistManager = PlaylistManager();

  final _currentSongController = StreamController<Song?>.broadcast();
  Song? _currentSong;

  AudioPlayerService() {
    // Écouter les changements d'état du player
    _audioPlayer.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        playNext();
      }
    });

    // S'assurer que le stream est mis à jour quand la chanson change
    _audioPlayer.currentIndexStream.listen((_) {
      if (_currentSong != null) {
        _currentSongController.add(_currentSong);
      }
    });
  }

  PlaylistManager get playlistManager => _playlistManager;
  Stream<PlayerState> get playerStateStream => _audioPlayer.playerStateStream;
  Stream<Duration> get positionStream => _audioPlayer.positionStream;
  Stream<Duration?> get durationStream => _audioPlayer.durationStream;
  Stream<Song?> get currentSongStream => _currentSongController.stream;
  Song? get currentSong => _currentSong;

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
    try {
      // Créer les métadonnées pour la notification
      final mediaItem = MediaItem(
        id: song.path,
        album: "Album local", // Ajoutez si disponible
        title: song.title,
        artist: song.artist,
        duration: song.duration,
        artUri: null, // Ajoutez l'URI de la pochette si disponible
        displayTitle: song.title,
        displaySubtitle: song.artist,
      );

      // Configurer la source audio avec les métadonnées
      await _audioPlayer.setAudioSource(
        AudioSource.file(
          song.path,
          tag: mediaItem,
        ),
      );

      await _audioPlayer.play();
      _currentSong = song;
      _currentSongController.add(song);
    } catch (e) {
      print('Error playing song: $e');
    }
  }

  Future<void> playPlaylist(List<Song> songs, {int initialIndex = 0}) async {
    try {
      final playlist = ConcatenatingAudioSource(
        children: songs.map((song) {
          return AudioSource.file(
            song.path,
            tag: MediaItem(
              id: song.path,
              title: song.title,
              artist: song.artist,
              duration: song.duration,
              artUri: null,
              extras: {'file_path': song.path},
            ),
          );
        }).toList(),
      );

      await _audioPlayer.setAudioSource(playlist, initialIndex: initialIndex);
      await _audioPlayer.play();
      _currentSong = songs[initialIndex];
      _currentSongController.add(_currentSong);
    } catch (e) {
      print('Error playing playlist: $e');
    }
  }

  Future<void> playNext() async {
    if (_repeatMode == RepeatMode.all && !_playlistManager.hasNext) {
      // Revenir au début de la playlist
      final playlist = _playlistManager.playlist;
      await playPlaylist(playlist, initialIndex: 0);
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
    _currentSong = null;
    _currentSongController.add(null);
  }

  void dispose() {
    _audioPlayer.dispose();
    _currentSongController.close();
  }
}
