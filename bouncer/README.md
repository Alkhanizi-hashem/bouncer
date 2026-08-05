# Bouncer

Bouncer is a retro-style Flutter brick breaker controlled by a phone's accelerometer. Tilt the device to move the paddle, keep the ball above the bottom edge, and clear every block to win.

## Features

- Real-time accelerometer input through `sensors_plus`
- Ticker-driven game loop with frame-rate-independent movement
- Axis-correct reflection from walls, blocks, and the paddle
- Circle-to-rectangle collision detection and block destruction
- Win, loss, ready, pause, restart, and app-lifecycle states
- Paddle clamping that keeps the full paddle inside the screen
- Easy, normal, and hard modes with different speeds, paddle widths, and block counts
- Drag control fallback for simulators, desktops, and inaccessible sensors
- Responsive portrait layout with a retro neon visual style
- Unit tests for physics and widget tests for primary game flows

## Requirements

- Flutter 3.44 or newer
- Dart 3.12 or newer
- Android or iOS physical device for accelerometer testing

## Run

```bash
flutter pub get
flutter run
```

The app is locked to portrait orientation so the accelerometer's horizontal axis maps consistently to paddle movement.

## Controls

- Tilt left or right to steer the paddle.
- Drag horizontally on the game board for touch control.
- Tap the board or the play button to start and pause.
- Use the restart button to reset the current difficulty.
- Select `EASY`, `NORMAL`, or `HARD` below the board. Changing difficulty resets the round.

## Game Rules

- The ball reflects horizontally from left and right walls.
- The ball reflects vertically from the ceiling, paddle, and horizontal block faces.
- A block is removed immediately after a collision.
- Clearing all blocks displays `YOU WON!`.
- Touching the bottom edge displays `YOU LOST!`.

Physics updates are split into small fixed substeps. This reduces collision tunneling on slower frames and at higher difficulty speeds while visual movement remains tied to Flutter's display ticker.

## Project Structure

```text
lib/
  main.dart                 App setup and portrait orientation
  game/
    game_engine.dart        State, movement, collision, and difficulty rules
    game_screen.dart        Sensor lifecycle, ticker, controls, and UI
test/
  game_engine_test.dart     Deterministic physics tests
  widget_test.dart          Game-screen interaction tests
```

## Quality Checks

```bash
dart format --set-exit-if-changed lib test
flutter analyze
flutter test
```

## Physical Device Testing

Emulators generally do not provide representative accelerometer behavior. Test both slow and quick tilts on a physical device and confirm:

- Right tilt moves the paddle right and left tilt moves it left.
- The paddle never crosses either screen edge.
- Backgrounding the app pauses the game.
- All three difficulty modes remain playable at the device's refresh rate.

If a specific device reports the horizontal sensor axis in the opposite direction, invert `event.x` in `lib/game/game_screen.dart`.
