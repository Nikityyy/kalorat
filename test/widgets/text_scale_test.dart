import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kalorat/main.dart' show maxTextScale;
import 'package:kalorat/theme/app_colors.dart';
import 'package:kalorat/widgets/me/today_stats_grid.dart';

Widget _grid({required double scale, required double width}) {
  Widget card(String title, String value, Color color) => Expanded(
    child: StatCard(
      title: title,
      value: value,
      unit: 'kcal',
      icon: Icons.local_fire_department_outlined,
      color: color,
      progress: 0.5,
    ),
  );

  return MaterialApp(
    home: MediaQuery(
      data: MediaQueryData(textScaler: TextScaler.linear(scale)),
      child: Scaffold(
        body: Center(
          child: SizedBox(
            width: width,
            child: Row(
              children: [
                card('Calories', '7421 / 1971', AppColors.primary),
                const SizedBox(width: 12),
                card('Carbohydrates', '1234 / 1500', AppColors.limestone),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  test('text scale is capped at 1.5', () {
    expect(maxTextScale, 1.5);
  });

  for (final scale in [1.0, 1.5]) {
    testWidgets('stat cards fit at ${scale}x on a narrow phone', (
      tester,
    ) async {
      await tester.pumpWidget(_grid(scale: scale, width: 330));
      expect(tester.takeException(), isNull);

      final card = tester.getRect(find.byType(StatCard).first);
      for (final text
          in find
              .descendant(
                of: find.byType(StatCard).first,
                matching: find.byType(Text),
              )
              .evaluate()) {
        final box = tester.getRect(find.byWidget(text.widget).first);
        expect(box.right, lessThanOrEqualTo(card.right + 0.5));
      }
    });
  }
}
