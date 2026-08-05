import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:sensors_plus/sensors_plus.dart';

import 'game_engine.dart';

class BouncerGameScreen extends StatefulWidget {
  const BouncerGameScreen({super.key, this.sensorsEnabled = true});

  final bool sensorsEnabled;

  @override
  State<BouncerGameScreen> createState() => _BouncerGameScreenState();
}

class _BouncerGameScreenState extends State<BouncerGameScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final Ticker _ticker;
  final GameEngine _engine = GameEngine();
  StreamSubscription<AccelerometerEvent>? _sensorSubscription;
  Duration _lastTick = Duration.zero;
  double _filteredTilt = 0;
  bool _sensorAvailable = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _ticker = createTicker(_onTick)..start();
    if (widget.sensorsEnabled) _listenToAccelerometer();
  }

  void _listenToAccelerometer() {
    try {
      _sensorSubscription = accelerometerEventStream().listen(
        (event) {
          _filteredTilt = _filteredTilt * 0.82 + (-event.x) * 0.18;
          _engine.setTilt(_filteredTilt.abs() < 0.12 ? 0 : _filteredTilt);
        },
        onError: (_) {
          if (mounted) setState(() => _sensorAvailable = false);
        },
      );
    } on Object {
      _sensorAvailable = false;
    }
  }

  void _onTick(Duration elapsed) {
    final delta = _lastTick == Duration.zero
        ? 0.0
        : (elapsed - _lastTick).inMicroseconds / Duration.microsecondsPerSecond;
    _lastTick = elapsed;
    if (_engine.status != GameStatus.running) return;

    _engine.update(delta);
    if (mounted) setState(() {});
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed &&
        _engine.status == GameStatus.running) {
      setState(_engine.pause);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _sensorSubscription?.cancel();
    _ticker.dispose();
    super.dispose();
  }

  void _toggleGame() {
    setState(() {
      if (_engine.status == GameStatus.won ||
          _engine.status == GameStatus.lost) {
        _engine.reset();
      }
      _engine.togglePause();
    });
  }

  void _restart() => setState(_engine.reset);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF12152B), Color(0xFF070812)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
            child: Column(
              children: [
                _GameHeader(
                  destroyed: _engine.destroyedBricks,
                  total: _engine.difficulty.brickRows * 7,
                  status: _engine.status,
                  onPause: _toggleGame,
                  onRestart: _restart,
                ),
                const SizedBox(height: 12),
                Expanded(child: _buildGameBoard()),
                const SizedBox(height: 12),
                _DifficultySelector(
                  selected: _engine.difficulty,
                  onSelected: (difficulty) {
                    setState(() => _engine.reset(toDifficulty: difficulty));
                  },
                ),
                const SizedBox(height: 10),
                Text(
                  _sensorAvailable
                      ? 'TILT TO STEER  •  DRAG FOR TOUCH CONTROL'
                      : 'SENSOR UNAVAILABLE  •  DRAG TO STEER',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF858AA8),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGameBoard() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final boardSize = Size(constraints.maxWidth, constraints.maxHeight);
        _engine.resize(boardSize);

        return GestureDetector(
          key: const Key('game-board'),
          behavior: HitTestBehavior.opaque,
          onTap: _toggleGame,
          onHorizontalDragUpdate: (details) {
            setState(() => _engine.movePaddle(details.delta.dx));
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xFF0C1020),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFF303758), width: 1.5),
                boxShadow: const [
                  BoxShadow(color: Color(0x337CF7D4), blurRadius: 22),
                ],
              ),
              child: Stack(
                children: [
                  const Positioned.fill(
                    child: CustomPaint(painter: _GridPainter()),
                  ),
                  for (final brick in _engine.bricks)
                    Positioned.fromRect(
                      rect: brick.rect,
                      child: _BrickTile(colorIndex: brick.colorIndex),
                    ),
                  Positioned(
                    left: _engine.paddleX,
                    top: _engine.paddleY,
                    width: _engine.paddleWidth,
                    height: GameEngine.paddleHeight,
                    child: const _Paddle(),
                  ),
                  Positioned(
                    left: _engine.ballPosition.dx - GameEngine.ballRadius,
                    top: _engine.ballPosition.dy - GameEngine.ballRadius,
                    width: GameEngine.ballRadius * 2,
                    height: GameEngine.ballRadius * 2,
                    child: const _Ball(),
                  ),
                  if (_engine.status != GameStatus.running)
                    Positioned.fill(
                      child: _StatusOverlay(
                        status: _engine.status,
                        onPressed: _toggleGame,
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _GameHeader extends StatelessWidget {
  const _GameHeader({
    required this.destroyed,
    required this.total,
    required this.status,
    required this.onPause,
    required this.onRestart,
  });

  final int destroyed;
  final int total;
  final GameStatus status;
  final VoidCallback onPause;
  final VoidCallback onRestart;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'BOUNCER',
              style: TextStyle(
                color: Color(0xFFF4F5FF),
                fontSize: 24,
                height: 1,
                fontWeight: FontWeight.w900,
                letterSpacing: 3.2,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'NEON BREAK PROTOCOL',
              style: TextStyle(
                color: Color(0xFF7CF7D4),
                fontSize: 9,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.4,
              ),
            ),
          ],
        ),
        const Spacer(),
        _ScoreCard(value: '$destroyed/$total'),
        const SizedBox(width: 8),
        IconButton.filledTonal(
          tooltip: status == GameStatus.running ? 'Pause game' : 'Resume game',
          onPressed: onPause,
          icon: Icon(
            status == GameStatus.running
                ? Icons.pause_rounded
                : Icons.play_arrow_rounded,
          ),
        ),
        IconButton(
          tooltip: 'Restart game',
          onPressed: onRestart,
          icon: const Icon(Icons.refresh_rounded),
        ),
      ],
    );
  }
}

class _ScoreCard extends StatelessWidget {
  const _ScoreCard({required this.value});

  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF191D34),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF353B5E)),
      ),
      child: Column(
        children: [
          const Text(
            'BLOCKS',
            style: TextStyle(
              color: Color(0xFF858AA8),
              fontSize: 8,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFFF4F5FF),
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _DifficultySelector extends StatelessWidget {
  const _DifficultySelector({required this.selected, required this.onSelected});

  final Difficulty selected;
  final ValueChanged<Difficulty> onSelected;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (final difficulty in Difficulty.values)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ChoiceChip(
              label: Text(difficulty.label),
              selected: selected == difficulty,
              onSelected: (_) => onSelected(difficulty),
              labelStyle: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
                color: selected == difficulty
                    ? const Color(0xFF09120F)
                    : const Color(0xFFA4A9C5),
              ),
              selectedColor: const Color(0xFF7CF7D4),
              backgroundColor: const Color(0xFF171A2D),
              side: const BorderSide(color: Color(0xFF333958)),
              showCheckmark: false,
            ),
          ),
      ],
    );
  }
}

class _StatusOverlay extends StatelessWidget {
  const _StatusOverlay({required this.status, required this.onPressed});

  final GameStatus status;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final (title, subtitle, color) = switch (status) {
      GameStatus.ready => (
        'READY?',
        'Keep the pulse above the line',
        const Color(0xFF7CF7D4),
      ),
      GameStatus.paused => (
        'PAUSED',
        'The arena is holding',
        const Color(0xFFFFD166),
      ),
      GameStatus.won => (
        'YOU WON!',
        'Every block has been cleared',
        const Color(0xFF7CF7D4),
      ),
      GameStatus.lost => (
        'YOU LOST!',
        'The pulse crossed the floor',
        const Color(0xFFFF6680),
      ),
      GameStatus.running => ('', '', Colors.transparent),
    };

    return ColoredBox(
      color: const Color(0xB3090B16),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: TextStyle(
                color: color,
                fontSize: 31,
                fontWeight: FontWeight.w900,
                letterSpacing: 3,
                shadows: [
                  Shadow(color: color.withValues(alpha: 0.55), blurRadius: 18),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: const TextStyle(color: Color(0xFFB4B8D0), fontSize: 12),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              key: const Key('start-game'),
              onPressed: onPressed,
              icon: const Icon(Icons.play_arrow_rounded),
              label: Text(
                status == GameStatus.won || status == GameStatus.lost
                    ? 'PLAY AGAIN'
                    : 'START',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BrickTile extends StatelessWidget {
  const _BrickTile({required this.colorIndex});

  static const colors = [
    Color(0xFFFF6680),
    Color(0xFFFFA85C),
    Color(0xFFFFD166),
    Color(0xFF7CF7D4),
    Color(0xFF7AA8FF),
  ];

  final int colorIndex;

  @override
  Widget build(BuildContext context) {
    final color = colors[colorIndex % colors.length];
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.white.withValues(alpha: 0.34)),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.34), blurRadius: 7),
        ],
      ),
    );
  }
}

class _Paddle extends StatelessWidget {
  const _Paddle();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF7CF7D4), Color(0xFF36C9A4)],
        ),
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [BoxShadow(color: Color(0xAA7CF7D4), blurRadius: 12)],
      ),
    );
  }
}

class _Ball extends StatelessWidget {
  const _Ball();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Color(0xFFF7FAFF),
        boxShadow: [
          BoxShadow(color: Color(0xFFFFFFFF), blurRadius: 7),
          BoxShadow(color: Color(0xFF7AA8FF), blurRadius: 17, spreadRadius: 2),
        ],
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  const _GridPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0x0D91A0D8)
      ..strokeWidth = 1;
    const spacing = 24.0;
    for (var x = 0.0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (var y = 0.0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
    canvas.drawLine(
      Offset(0, size.height - 2),
      Offset(size.width, size.height - 2),
      Paint()
        ..color = const Color(0x99FF6680)
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
