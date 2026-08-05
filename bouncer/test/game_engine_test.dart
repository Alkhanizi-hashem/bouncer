import 'dart:ui';

import 'package:bouncer/game/game_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GameEngine', () {
    late GameEngine engine;

    setUp(() {
      engine = GameEngine()..resize(const Size(360, 640));
    });

    test('creates the correct number of blocks for each difficulty', () {
      expect(engine.bricks, hasLength(28));

      engine.reset(toDifficulty: Difficulty.easy);
      expect(engine.bricks, hasLength(21));

      engine.reset(toDifficulty: Difficulty.hard);
      expect(engine.bricks, hasLength(35));
    });

    test('keeps the paddle inside the board', () {
      engine.movePaddle(-1000);
      expect(engine.paddleX, 0);

      engine.movePaddle(2000);
      expect(engine.paddleRect.right, engine.size.width);
    });

    test('reflects horizontal velocity at a vertical wall', () {
      engine.debugSetBall(
        position: const Offset(9, 300),
        velocity: const Offset(-100, -20),
      );
      engine.start();

      engine.update(0.02);

      expect(engine.ballVelocity.dx, isPositive);
      expect(engine.ballVelocity.dy, -20);
      expect(
        engine.ballPosition.dx,
        greaterThanOrEqualTo(GameEngine.ballRadius),
      );
    });

    test('destroys a block and reflects from its horizontal surface', () {
      engine.debugSetBricks(const [
        Brick(rect: Rect.fromLTWH(100, 100, 60, 20), colorIndex: 0),
      ]);
      engine.debugSetBall(
        position: const Offset(130, 91),
        velocity: const Offset(25, 100),
      );
      engine.start();

      engine.update(0.03);

      expect(engine.bricks, isEmpty);
      expect(engine.destroyedBricks, 1);
      expect(engine.ballVelocity.dx, 25);
      expect(engine.ballVelocity.dy, isNegative);
      expect(engine.status, GameStatus.won);
    });

    test('loses when the ball touches the bottom edge', () {
      engine.debugSetBall(
        position: Offset(180, engine.size.height - GameEngine.ballRadius - 1),
        velocity: const Offset(0, 200),
      );
      engine.start();

      engine.update(0.02);

      expect(engine.status, GameStatus.lost);
    });
  });
}
