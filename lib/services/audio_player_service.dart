import 'dart:async';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:sound/models/repeat_mode.dart';
import 'package:sound/models/song.dart';
import 'package:sound/services/playlist_manager.dart';
import 'package:sound/utils/utils.dart';

class AudioPlayerService {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final PlaylistManager _playlistManager = PlaylistManager();
  ConcatenatingAudioSource? _playlist;

  final _currentSongController = StreamController<Song?>.broadcast();
  Song? _currentSong;

  bool _isShuffleEnabled = false;
  bool get isShuffleEnabled => _isShuffleEnabled;

  List<int>? _shuffleIndices;

  AudioPlayerService() {
    _audioPlayer.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        playNext();
      }
    });

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

    _audioPlayer.androidAudioSessionId; 
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

  void toggleShuffle() {
    _isShuffleEnabled = !_isShuffleEnabled;
    if (_isShuffleEnabled) {
      _shuffleIndices =
          List.generate(_playlistManager.playlist.length, (i) => i)..shuffle();
      if (_audioPlayer.currentIndex != null) {
        final currentIndex = _audioPlayer.currentIndex!;
        _shuffleIndices!.remove(currentIndex);
        _shuffleIndices!.insert(0, currentIndex);
      }
    } else {
      _shuffleIndices = null;
    }
    _audioPlayer.setShuffleModeEnabled(_isShuffleEnabled);
  }

  Future<void> playSong(Song song) async {
    try {
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
        children: await Future.wait(songs.map((song) async {
          final localImagePath = await getLocalImagePath("assets/img/bg1.png");
          return AudioSource.file(
            song.path,
            tag: MediaItem(
              id: song.path,
              album: "Album local",
              title: song.title,
              artist: song.artist,
              duration: song.duration,
              artUri: Uri.file(localImagePath),
              displayTitle: "🎵 ${song.title}",
              displaySubtitle: song.artist,
            ),
          );
        }).toList()),
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
      if (_isShuffleEnabled && _shuffleIndices != null) {
        final currentIndex = _audioPlayer.currentIndex;
        if (currentIndex != null) {
          final currentShuffleIndex = _shuffleIndices!.indexOf(currentIndex);
          if (currentShuffleIndex < _shuffleIndices!.length - 1) {
            final nextIndex = _shuffleIndices![currentShuffleIndex + 1];
            await _audioPlayer.seek(Duration.zero, index: nextIndex);
            return;
          }
        }
      }

      if (_audioPlayer.hasNext) {
        await _audioPlayer.seekToNext();
      } else if (_repeatMode == RepeatMode.all) {
        await _audioPlayer.seek(Duration.zero, index: 0);
      } else if (_repeatMode == RepeatMode.off &&
          _playlistManager.playlist.isNotEmpty) {
        await _audioPlayer.seek(Duration.zero, index: 0);
      }
    } catch (e) {
      print('Error playing next song: $e');
    }
  }

  Future<void> playPrevious() async {
    try {
      if (_isShuffleEnabled && _shuffleIndices != null) {
        final currentIndex = _audioPlayer.currentIndex;
        if (currentIndex != null) {
          final currentShuffleIndex = _shuffleIndices!.indexOf(currentIndex);
          if (currentShuffleIndex > 0) {
            final previousIndex = _shuffleIndices![currentShuffleIndex - 1];
            await _audioPlayer.seek(Duration.zero, index: previousIndex);
            return;
          }
        }
      }

      if (_audioPlayer.hasPrevious) {
        await _audioPlayer.seekToPrevious();
      } else if (_playlistManager.playlist.isNotEmpty) {
        await _audioPlayer.seek(Duration.zero,
            index: _playlistManager.playlist.length - 1);
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
