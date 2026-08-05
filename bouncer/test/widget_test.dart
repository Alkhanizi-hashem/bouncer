import 'package:bouncer/game/game_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('starts a game from the ready overlay', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: BouncerGameScreen(sensorsEnabled: false)),
    );

    expect(find.text('BOUNCER'), findsOneWidget);
    expect(find.text('READY?'), findsOneWidget);
    expect(find.text('0/28'), findsOneWidget);

    await tester.tap(find.byKey(const Key('start-game')));
    await tester.pump(const Duration(milliseconds: 16));

    expect(find.text('READY?'), findsNothing);
    expect(find.byKey(const Key('game-board')), findsOneWidget);
  });

  testWidgets('selecting a difficulty resets the block count', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: BouncerGameScreen(sensorsEnabled: false)),
    );

    await tester.tap(find.text('HARD'));
    await tester.pump();

    expect(find.text('0/35'), findsOneWidget);
    expect(find.text('READY?'), findsOneWidget);
  });
}
