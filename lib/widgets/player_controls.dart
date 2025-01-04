import 'package:flutter/material.dart';
import 'package:sound/models/repeat_mode.dart';
import 'package:sound/models/song.dart';
import 'package:sound/screens/song_details_screen.dart';
import 'package:sound/services/audio_player_service.dart';

class PlayerControls extends StatefulWidget {
  final AudioPlayerService playerService;
  final Song song;

  const PlayerControls({
    super.key,
    required this.playerService,
    required this.song,
  });

  @override
  State<PlayerControls> createState() => _PlayerControlsState();
}

class _PlayerControlsState extends State<PlayerControls> {
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _setupStreams();
  }

  void _setupStreams() {
    widget.playerService.playerStateStream.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state.playing;
        });
      }
    });

    widget.playerService.positionStream.listen((pos) {
      if (mounted) {
        setState(() {
          _position = pos;
        });
      }
    });

    widget.playerService.durationStream.listen((dur) {
      if (mounted) {
        setState(() {
          _duration = dur ?? Duration.zero;
        });
      }
    });
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String minutes = twoDigits(duration.inMinutes.remainder(60));
    String seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Barre de progression
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              Slider(
                value: _position.inSeconds.toDouble(),
                min: 0,
                max: _duration.inSeconds.toDouble(),
                onChanged: (value) {
                  final newPosition = Duration(seconds: value.toInt());
                  widget.playerService.seek(newPosition);
                },
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(_formatDuration(_position)),
                    Text(_formatDuration(_duration)),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Contrôles de lecture
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              iconSize: 32,
              icon: const Icon(Icons.skip_previous),
              onPressed: widget.playerService.playlistManager.hasPrevious
                  ? () => widget.playerService.playPrevious()
                  : null,
            ),
            const SizedBox(width: 16),
            IconButton(
              iconSize: 64,
              icon: Icon(_isPlaying
                  ? Icons.pause_circle_filled
                  : Icons.play_circle_filled),
              onPressed: () {
                if (_isPlaying) {
                  widget.playerService.pause();
                } else {
                  widget.playerService.resume();
                }
              },
            ),
            const SizedBox(width: 16),
            IconButton(
              iconSize: 32,
              icon: const Icon(Icons.skip_next),
              onPressed: widget.playerService.playlistManager.hasNext
                  ? () => widget.playerService.playNext()
                  : null,
            ),
          ],
        ),

        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: Icon(_getRepeatIcon()),
              onPressed: widget.playerService.toggleRepeatMode,
            ),
            const SizedBox(width: 32),
            IconButton(
              icon: const Icon(Icons.info_outline),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SongDetailsScreen(song: widget.song),
                  ),
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  IconData _getRepeatIcon() {
    switch (widget.playerService.repeatMode) {
      case RepeatMode.off:
        return Icons.repeat;
      case RepeatMode.single:
        return Icons.repeat_one;
      case RepeatMode.all:
        return Icons.repeat_on;
    }
  }
}
