import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kalorat/utils/haptics.dart';
import 'package:kalorat/widgets/inputs/action_button.dart';
import 'package:kalorat/widgets/inputs/bespoke_selection_card.dart';
import 'package:kalorat/widgets/inputs/pressable.dart';

double _scaleOf(WidgetTester tester) =>
    tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale;

double _opacityOf(WidgetTester tester) =>
    tester.widget<AnimatedOpacity>(find.byType(AnimatedOpacity)).opacity;

void main() {
  testWidgets('Pressable scales to 98% while pressed and eases back', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Center(
          child: Pressable(
            child: ColoredBox(
              color: Colors.red,
              child: SizedBox(width: 100, height: 50),
            ),
          ),
        ),
      ),
    );
    expect(_scaleOf(tester), 1);
    expect(_opacityOf(tester), 1);

    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(Pressable)),
    );
    await tester.pump();
    expect(_scaleOf(tester), 0.98);
    expect(_opacityOf(tester), lessThan(1));

    await gesture.up();
    await tester.pumpAndSettle();
    expect(_scaleOf(tester), 1);
    expect(_opacityOf(tester), 1);
  });

  testWidgets('Pressable stays still when disabled or animations are off', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Center(
          child: Pressable(
            enabled: false,
            child: ColoredBox(
              color: Colors.red,
              child: SizedBox(width: 100, height: 50),
            ),
          ),
        ),
      ),
    );
    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(Pressable)),
    );
    await tester.pump();
    expect(_scaleOf(tester), 1);
    await gesture.up();

    await tester.pumpWidget(
      const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: Center(
            child: Pressable(
              child: ColoredBox(
                color: Colors.red,
                child: SizedBox(width: 100, height: 50),
              ),
            ),
          ),
        ),
      ),
    );
    final again = await tester.startGesture(
      tester.getCenter(find.byType(Pressable)),
    );
    await tester.pump();
    expect(_scaleOf(tester), 1);
    await again.up();
  });

  testWidgets('ActionButton keeps its hit area and fires once per tap', (
    tester,
  ) async {
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 300,
              child: ActionButton(text: 'Go', onPressed: () => taps++),
            ),
          ),
        ),
      ),
    );
    final rect = tester.getRect(find.byType(ActionButton));
    expect(rect.height, 64);
    // Every corner of the button still reaches it, as without Pressable.
    for (final point in [
      rect.topLeft + const Offset(2, 2),
      rect.topRight + const Offset(-2, 2),
      rect.bottomLeft + const Offset(2, -2),
      rect.bottomRight + const Offset(-2, -2),
      rect.center,
    ]) {
      await tester.tapAt(point);
      await tester.pump();
    }
    expect(taps, 5);
    // Just outside the button does nothing.
    await tester.tapAt(rect.topLeft + const Offset(-6, -6));
    expect(taps, 5);
  });

  testWidgets('ActionButton does not fire while loading', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ActionButton(
            text: 'Go',
            isLoading: true,
            onPressed: () => taps++,
          ),
        ),
      ),
    );
    await tester.tap(find.byType(ActionButton));
    await tester.pump();
    expect(taps, 0);
  });

  testWidgets('selection card still selects on tap and scrolls with a drag', (
    tester,
  ) async {
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListView(
            children: [
              for (var i = 0; i < 12; i++)
                BespokeSelectionCard(
                  title: 'Card $i',
                  isSelected: false,
                  onTap: () => taps++,
                ),
            ],
          ),
        ),
      ),
    );
    await tester.tap(find.text('Card 0'));
    await tester.pump();
    expect(taps, 1);

    // A drag that starts on a card still scrolls the list and is not a tap.
    await tester.drag(find.text('Card 1'), const Offset(0, -200));
    await tester.pumpAndSettle();
    expect(taps, 1);
    expect(find.text('Card 0'), findsNothing);
  });

  test('Haptics never throws without a platform', () {
    Haptics.tick();
    Haptics.selection();
    Haptics.confirm();
  });
}
