import 'dart:async';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:sound/models/repeat_mode.dart';
import 'package:sound/models/song.dart';
import 'package:sound/services/playlist_manager.dart';

class AudioPlayerService {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final PlaylistManager _playlistManager = PlaylistManager();
  ConcatenatingAudioSource? _playlist;

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
    _audioPlayer.currentIndexStream.listen((index) {
      if (index != null && _playlist != null) {
        final audioSource = _playlist!.children[index] as IndexedAudioSource;
        final mediaItem = audioSource.tag as MediaItem;
        final song = _playlistManager.playlist.firstWhere(
          (s) => s.path == mediaItem.id,
          orElse: () => _currentSong!,
        );
        _currentSong = song;
        _currentSongController.add(song);
      }
    });

    // Configurer les commandes de notification
    _audioPlayer.androidAudioSessionId; // Active la session audio
    _audioPlayer.setSkipSilenceEnabled(false);
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
      // Créer une playlist avec toutes les chansons, en commençant par celle sélectionnée
      List<Song> allSongs = [..._playlistManager.playlist];
      if (!allSongs.contains(song)) {
        allSongs = [song, ...allSongs];
      }
      await playPlaylist(allSongs, initialIndex: allSongs.indexOf(song));
    } catch (e) {
      print('Error playing song: $e');
    }
  }

  Future<void> playPlaylist(List<Song> songs, {int initialIndex = 0}) async {
    try {
      if (songs.isEmpty) return;

      _playlistManager.setPlaylist(songs, startIndex: initialIndex);

      _playlist = ConcatenatingAudioSource(
        children: songs.map((song) {
          return AudioSource.file(
            song.path,
            tag: MediaItem(
              id: song.path,
              album: "Album local",
              title: song.title,
              artist: song.artist,
              duration: song.duration,
              artUri: null,
              displayTitle: song.title,
              displaySubtitle: song.artist,
            ),
          );
        }).toList(),
      );

      await _audioPlayer.setAudioSource(_playlist!, initialIndex: initialIndex);
      await _audioPlayer.play();
      _currentSong = songs[initialIndex];
      _currentSongController.add(_currentSong);
    } catch (e) {
      print('Error playing playlist: $e');
    }
  }

  Future<void> playNext() async {
    try {
      if (_audioPlayer.hasNext) {
        await _audioPlayer.seekToNext();
      } else if (_repeatMode == RepeatMode.all) {
        await _audioPlayer.seek(Duration.zero, index: 0);
      }
    } catch (e) {
      print('Error playing next song: $e');
    }
  }

  Future<void> playPrevious() async {
    try {
      // Si on est au-delà de 3 secondes dans la chanson actuelle,
      // on revient au début de celle-ci
      if (await _audioPlayer.position >= const Duration(seconds: 3)) {
        await _audioPlayer.seek(Duration.zero);
      }
      // Sinon, on va à la chanson précédente
      else if (_audioPlayer.hasPrevious) {
        await _audioPlayer.seekToPrevious();
      }
      // Si on est au début de la première chanson et en mode repeat all,
      // on va à la dernière chanson
      else if (_repeatMode == RepeatMode.all && _playlist != null) {
        await _audioPlayer.seek(Duration.zero,
            index: _playlist!.children.length - 1);
      }
    } catch (e) {
      print('Error playing previous song: $e');
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
    _playlist = null;
    _audioPlayer.dispose();
    _currentSongController.close();
  }
}
