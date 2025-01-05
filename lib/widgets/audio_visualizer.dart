import 'dart:async';
import 'dart:math';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:sound/services/audio_player_service.dart';

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

    widget.playerService.playerStateStream.first.then((state) {
      if (state.playing) {
        _isPlaying = true;
        _startAnimations();
      }
    });
  }

  void _startAnimations() {
    _animationTimer?.cancel();

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