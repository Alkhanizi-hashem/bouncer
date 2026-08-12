# Bouncer

Bouncer is a portrait Flutter brick-breaker game with a retro neon presentation. Tilt a phone or drag across the board to steer the paddle, keep the ball above the floor, and clear every brick.

## Features

- Accelerometer-based paddle control with low-pass tilt filtering
- Horizontal drag fallback for touch devices and unavailable sensors
- Ticker-driven, frame-rate-independent game loop
- Fixed physics substeps to reduce collision tunneling
- Ball reflection against walls, paddle, and brick faces
- Ready, running, paused, won, and lost states
- Automatic pause when the application leaves the foreground
- Easy, normal, and hard settings with different speeds, paddle widths, and brick rows
- Live destroyed-brick count, restart action, and touch-to-pause board
- Unit-tested physics separated from the Flutter presentation

## Tech Stack

- Flutter and Dart 3.12+
- Sensors Plus for accelerometer events
- Flutter `Ticker` for the update loop
- Custom painting and positioned widgets for the arena
- Flutter Test for physics and interaction coverage

## Project Structure

```text
bouncer/
|-- lib/
|   |-- game/
|   |   |-- game_engine.dart  State, sizing, physics, collisions, and difficulty
|   |   `-- game_screen.dart  Sensor lifecycle, ticker, controls, and rendering
|   `-- main.dart             App theme and portrait lock
`-- test/
    |-- game_engine_test.dart Deterministic physics tests
    `-- widget_test.dart      Start and difficulty-selection tests
```

## Getting Started

### Prerequisites

- A Flutter SDK that includes Dart 3.12.2 or newer
- A configured Flutter target
- A physical Android or iOS device for tilt control

The accelerometer is optional on Android and the drag fallback remains usable without it. Simulators and desktop targets are suitable for drag-control testing, but not for representative tilt behavior.

### Run

From the repository root:

```sh
cd bouncer
flutter pub get
flutter run
```

No API key, network service, or environment file is required. iOS includes a motion-usage description and may request motion access according to the operating-system version.

## Usage

- Tap the board or **Start** to begin; tap again or use the header control to pause.
- Tilt left and right to steer the paddle on a supported phone.
- Drag horizontally on the arena for direct touch control.
- Select `EASY`, `NORMAL`, or `HARD` to reset with that difficulty.
- Use restart to reset the current difficulty at any time.

| Difficulty | Ball speed | Paddle width | Bricks |
| --- | ---: | ---: | ---: |
| Easy | 250 px/s | 28% of board width | 21 |
| Normal | 310 px/s | 22% of board width | 28 |
| Hard | 380 px/s | 17% of board width | 35 |

Clearing the final brick wins the round. Letting the ball touch the bottom edge loses it.

## Quality Checks

```sh
cd bouncer
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
```
