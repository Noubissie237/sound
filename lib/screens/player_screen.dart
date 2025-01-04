import 'dart:async';
import 'dart:math' as math;
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:sound/models/song.dart';
import 'package:sound/services/audio_player_service.dart';
import 'package:sound/widgets/player_controls.dart';

class PlayerScreen extends StatelessWidget {
  final Song song;
  final AudioPlayerService playerService;

  const PlayerScreen({
    super.key,
    required this.song,
    required this.playerService,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_down),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.playlist_play),
            onPressed: () {
              // Implémenter l'ouverture de la playlist
            },
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              // Implémenter le menu d'options
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).primaryColor.withOpacity(0.2),
              Theme.of(context).scaffoldBackgroundColor,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const Spacer(),
              // Visualiseur audio
              AudioVisualizer(playerService: playerService),
              const SizedBox(height: 40),
              // Informations sur la chanson
              _SongInfo(song: song),
              const SizedBox(height: 24),
              // Contrôles du lecteur
              PlayerControls(
                playerService: playerService,
                song: song,
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}

class AudioVisualizer extends StatefulWidget {
  final AudioPlayerService playerService;

  const AudioVisualizer({
    super.key,
    required this.playerService,
  });

  @override
  State<AudioVisualizer> createState() => _AudioVisualizerState();
}

class _AudioVisualizerState extends State<AudioVisualizer>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  final int _barCount = 20;
  final Random _random = Random();
  Timer? _animationTimer;
  StreamSubscription<PlayerState>? _playerStateSubscription;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      _barCount,
      (index) => AnimationController(
        vsync: this,
        duration: Duration(milliseconds: 600 + _random.nextInt(400)),
      ),
    );

    // S'abonner aux changements d'état du lecteur
    _playerStateSubscription =
        widget.playerService.playerStateStream.listen((state) {
      final bool shouldPlay = state.playing;
      if (shouldPlay != _isPlaying) {
        setState(() {
          _isPlaying = shouldPlay;
        });
        if (_isPlaying) {
          _startAnimations();
        } else {
          _stopAnimations();
        }
      }
    });

    // Vérifier l'état initial
    widget.playerService.playerStateStream.first.then((state) {
      if (state.playing) {
        _isPlaying = true;
        _startAnimations();
      }
    });
  }

  void _startAnimations() {
    // Arrêter le timer existant s'il y en a un
    _animationTimer?.cancel();

    // Réinitialiser et démarrer les animations
    for (var controller in _controllers) {
      controller.value = 0.3;
    }

    _animationTimer =
        Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (!_isPlaying) {
        timer.cancel();
        return;
      }

      for (var i = 0; i < _controllers.length; i++) {
        if (!_controllers[i].isAnimating) {
          double nextHeight = 0.3 + _random.nextDouble() * 0.7;
          _controllers[i]
            ..duration = Duration(milliseconds: 600 + _random.nextInt(400))
            ..animateTo(nextHeight, curve: Curves.easeInOut);
        }
      }
    });
  }

  void _stopAnimations() {
    _animationTimer?.cancel();
    _animationTimer = null;

    // Animer toutes les barres vers leur position de repos
    for (var controller in _controllers) {
      controller.animateTo(0.3, duration: const Duration(milliseconds: 300));
    }
  }

  @override
  void dispose() {
    _playerStateSubscription?.cancel();
    _animationTimer?.cancel();
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      height: 300,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: CustomPaint(
        painter: DiscBackgroundPainter(
          color: Theme.of(context).primaryColor.withOpacity(0.05),
        ),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: List.generate(
              _barCount,
              (index) => _AnimatedBar(
                controller: _controllers[index],
                color: Theme.of(context).primaryColor,
                isPlaying: _isPlaying,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AnimatedBar extends StatelessWidget {
  final AnimationController controller;
  final Color color;
  final bool isPlaying;

  const _AnimatedBar({
    required this.controller,
    required this.color,
    required this.isPlaying,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return Container(
          width: 4,
          height: 20 + (130 * controller.value),
          decoration: BoxDecoration(
            color: color.withOpacity(
                isPlaying ? (0.6 + (0.4 * controller.value)) : 0.3),
            borderRadius: BorderRadius.circular(5),
          ),
        );
      },
    );
  }
}

class DiscBackgroundPainter extends CustomPainter {
  final Color color;

  DiscBackgroundPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    for (var i = 0; i < 4; i++) {
      canvas.drawCircle(center, (size.width / 2) - (i * 20), paint);
    }

    final linePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    for (var i = 0; i < 12; i++) {
      final angle = (i * 30) * (math.pi / 180);
      canvas.drawLine(
        center,
        Offset(
          center.dx + math.cos(angle) * size.width / 2,
          center.dy + math.sin(angle) * size.height / 2,
        ),
        linePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _SongInfo extends StatelessWidget {
  final Song song;

  const _SongInfo({required this.song});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          Text(
            song.title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Text(
            song.artist,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.grey,
                ),
            textAlign: TextAlign.center,
          ),
          if (song.album.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              song.album,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.withOpacity(0.7),
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}
