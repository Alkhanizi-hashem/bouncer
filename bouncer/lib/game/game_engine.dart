import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/foundation.dart';

enum GameStatus { ready, running, paused, won, lost }

enum Difficulty { easy, normal, hard }

extension DifficultySettings on Difficulty {
  String get label => switch (this) {
    Difficulty.easy => 'EASY',
    Difficulty.normal => 'NORMAL',
    Difficulty.hard => 'HARD',
  };

  double get ballSpeed => switch (this) {
    Difficulty.easy => 250,
    Difficulty.normal => 310,
    Difficulty.hard => 380,
  };

  double get paddleWidthFactor => switch (this) {
    Difficulty.easy => 0.28,
    Difficulty.normal => 0.22,
    Difficulty.hard => 0.17,
  };

  int get brickRows => switch (this) {
    Difficulty.easy => 3,
    Difficulty.normal => 4,
    Difficulty.hard => 5,
  };
}

class Brick {
  const Brick({required this.rect, required this.colorIndex});

  final Rect rect;
  final int colorIndex;

  Brick scale(double scaleX, double scaleY) {
    return Brick(
      rect: Rect.fromLTRB(
        rect.left * scaleX,
        rect.top * scaleY,
        rect.right * scaleX,
        rect.bottom * scaleY,
      ),
      colorIndex: colorIndex,
    );
  }
}

class GameEngine {
  GameEngine({this.difficulty = Difficulty.normal});

  static const double ballRadius = 8;
  static const double paddleHeight = 13;
  static const double paddleBottomMargin = 24;

  Difficulty difficulty;
  GameStatus status = GameStatus.ready;
  Size size = Size.zero;
  Offset ballPosition = Offset.zero;
  Offset ballVelocity = Offset.zero;
  double paddleX = 0;
  double tilt = 0;
  int destroyedBricks = 0;
  List<Brick> bricks = const [];

  double get paddleWidth => size.width * difficulty.paddleWidthFactor;
  double get paddleY => size.height - paddleBottomMargin - paddleHeight;
  Rect get paddleRect =>
      Rect.fromLTWH(paddleX, paddleY, paddleWidth, paddleHeight);

  void resize(Size newSize) {
    if (newSize.isEmpty || newSize == size) return;

    if (size.isEmpty) {
      size = newSize;
      reset();
      return;
    }

    final scaleX = newSize.width / size.width;
    final scaleY = newSize.height / size.height;
    ballPosition = Offset(ballPosition.dx * scaleX, ballPosition.dy * scaleY);
    paddleX *= scaleX;
    bricks = bricks.map((brick) => brick.scale(scaleX, scaleY)).toList();
    size = newSize;
    _constrainPaddle();
  }

  void start() {
    if (!size.isEmpty &&
        (status == GameStatus.ready || status == GameStatus.paused)) {
      status = GameStatus.running;
    }
  }

  void pause() {
    if (status == GameStatus.running) status = GameStatus.paused;
  }

  void togglePause() {
    if (status == GameStatus.running) {
      pause();
    } else if (status == GameStatus.paused || status == GameStatus.ready) {
      start();
    }
  }

  void reset({Difficulty? toDifficulty}) {
    if (toDifficulty != null) difficulty = toDifficulty;
    if (size.isEmpty) return;

    status = GameStatus.ready;
    destroyedBricks = 0;
    tilt = 0;
    paddleX = (size.width - paddleWidth) / 2;
    ballPosition = Offset(size.width / 2, paddleY - ballRadius - 8);
    final speed = difficulty.ballSpeed;
    ballVelocity = Offset(speed * 0.62, -speed * 0.78);
    bricks = _createBricks();
  }

  void setTilt(double value) {
    tilt = value.clamp(-5.0, 5.0);
  }

  void movePaddle(double deltaX) {
    paddleX += deltaX;
    _constrainPaddle();
  }

  void update(double elapsedSeconds) {
    if (status != GameStatus.running || elapsedSeconds <= 0) return;

    paddleX += tilt * 105 * elapsedSeconds;
    _constrainPaddle();

    var remaining = math.min(elapsedSeconds, 0.05);
    const maxStep = 1 / 120;
    while (remaining > 0 && status == GameStatus.running) {
      final step = math.min(remaining, maxStep);
      _simulateStep(step);
      remaining -= step;
    }
  }

  void _simulateStep(double seconds) {
    final previousPosition = ballPosition;
    ballPosition += ballVelocity * seconds;

    if (ballPosition.dx - ballRadius <= 0 && ballVelocity.dx < 0) {
      ballPosition = Offset(ballRadius, ballPosition.dy);
      ballVelocity = Offset(-ballVelocity.dx, ballVelocity.dy);
    } else if (ballPosition.dx + ballRadius >= size.width &&
        ballVelocity.dx > 0) {
      ballPosition = Offset(size.width - ballRadius, ballPosition.dy);
      ballVelocity = Offset(-ballVelocity.dx, ballVelocity.dy);
    }

    if (ballPosition.dy - ballRadius <= 0 && ballVelocity.dy < 0) {
      ballPosition = Offset(ballPosition.dx, ballRadius);
      ballVelocity = Offset(ballVelocity.dx, -ballVelocity.dy);
    }

    if (ballPosition.dy + ballRadius >= size.height) {
      ballPosition = Offset(ballPosition.dx, size.height - ballRadius);
      status = GameStatus.lost;
      return;
    }

    if (ballVelocity.dy > 0 && _circleIntersects(paddleRect)) {
      ballPosition = Offset(ballPosition.dx, paddleRect.top - ballRadius);
      ballVelocity = Offset(ballVelocity.dx, -ballVelocity.dy.abs());
    }

    for (var index = bricks.length - 1; index >= 0; index--) {
      final brick = bricks[index];
      if (!_circleIntersects(brick.rect)) continue;

      _reflectFromRect(brick.rect, previousPosition);
      bricks = List<Brick>.of(bricks)..removeAt(index);
      destroyedBricks++;
      if (bricks.isEmpty) status = GameStatus.won;
      break;
    }
  }

  bool _circleIntersects(Rect rect) {
    final nearestX = ballPosition.dx.clamp(rect.left, rect.right);
    final nearestY = ballPosition.dy.clamp(rect.top, rect.bottom);
    final deltaX = ballPosition.dx - nearestX;
    final deltaY = ballPosition.dy - nearestY;
    return deltaX * deltaX + deltaY * deltaY <= ballRadius * ballRadius;
  }

  void _reflectFromRect(Rect rect, Offset previousPosition) {
    if (previousPosition.dy + ballRadius <= rect.top) {
      ballPosition = Offset(ballPosition.dx, rect.top - ballRadius);
      ballVelocity = Offset(ballVelocity.dx, -ballVelocity.dy.abs());
      return;
    }
    if (previousPosition.dy - ballRadius >= rect.bottom) {
      ballPosition = Offset(ballPosition.dx, rect.bottom + ballRadius);
      ballVelocity = Offset(ballVelocity.dx, ballVelocity.dy.abs());
      return;
    }
    if (previousPosition.dx + ballRadius <= rect.left) {
      ballPosition = Offset(rect.left - ballRadius, ballPosition.dy);
      ballVelocity = Offset(-ballVelocity.dx.abs(), ballVelocity.dy);
      return;
    }

    ballPosition = Offset(rect.right + ballRadius, ballPosition.dy);
    ballVelocity = Offset(ballVelocity.dx.abs(), ballVelocity.dy);
  }

  List<Brick> _createBricks() {
    const columns = 7;
    const horizontalPadding = 16.0;
    const gap = 5.0;
    const brickHeight = 18.0;
    const top = 28.0;
    final width =
        (size.width - horizontalPadding * 2 - gap * (columns - 1)) / columns;

    return [
      for (var row = 0; row < difficulty.brickRows; row++)
        for (var column = 0; column < columns; column++)
          Brick(
            rect: Rect.fromLTWH(
              horizontalPadding + column * (width + gap),
              top + row * (brickHeight + gap),
              width,
              brickHeight,
            ),
            colorIndex: row,
          ),
    ];
  }

  void _constrainPaddle() {
    paddleX = paddleX.clamp(0, math.max(0, size.width - paddleWidth));
  }

  @visibleForTesting
  void debugSetBall({required Offset position, required Offset velocity}) {
    ballPosition = position;
    ballVelocity = velocity;
  }

  @visibleForTesting
  void debugSetBricks(List<Brick> value) {
    bricks = List<Brick>.of(value);
  }
}
