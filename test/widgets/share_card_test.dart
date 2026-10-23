import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:kalorat/screens/share/meal_share_card.dart';

// A 1x1 transparent PNG.
final _png = Uint8List.fromList(const [
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, //
  0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
  0x0D, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
  0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49,
  0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
]);

ShareCardData _data({
  String name = 'Teriyaki chicken with rice',
  double calories = 501,
  double protein = 34,
  double carbs = 57,
  double fats = 3.4,
}) => ShareCardData(
  name: name,
  calories: calories,
  protein: protein,
  carbs: carbs,
  fats: fats,
  language: 'en',
  kcalLabel: 'kcal',
  proteinLabel: 'Protein',
  carbsLabel: 'Carbohydrates',
  fatsLabel: 'Fat',
);

Widget _card(
  ShareCardData data,
  ShareCardStyle style, {
  ImageProvider? photo,
  double textScale = 1,
  Key? boundary,
}) => Directionality(
  textDirection: TextDirection.ltr,
  child: MediaQuery(
    data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
    child: Center(
      child: RepaintBoundary(
        key: boundary,
        child: MealShareCard(data: data, style: style, photo: photo),
      ),
    ),
  ),
);

void main() {
  setUpAll(() => initializeDateFormatting('en'));

  group('ShareCardData', () {
    test('writes whole grams from 10 up and one decimal below', () {
      final data = _data();
      expect(data.amount(57.4), '57');
      expect(data.amount(9.96), '10');
      expect(data.amount(3.44), '3.4');
      expect(data.amount(0), '0');
      expect(data.caloriesText, '501');
    });

    test('writes numbers the way the language does', () async {
      await initializeDateFormatting('de');
      final data = ShareCardData(
        name: 'x',
        calories: 1234,
        protein: 3.4,
        carbs: 0,
        fats: 0,
        language: 'de',
        kcalLabel: 'kcal',
        proteinLabel: 'Eiweiß',
        carbsLabel: 'Kohlenhydrate',
        fatsLabel: 'Fett',
      );
      expect(data.amount(data.protein), '3,4');
    });
  });

  group('MealShareCard', () {
    for (final style in ShareCardStyle.values) {
      for (final photo in [null, MemoryImage(_png)]) {
        testWidgets(
          '${style.name} ${photo == null ? 'without' : 'with'} a photo keeps '
          'its size and shows the numbers, whatever the text size',
          (tester) async {
            tester.view.physicalSize = const Size(1200, 1400);
            tester.view.devicePixelRatio = 1;
            addTearDown(tester.view.reset);
            await tester.pumpWidget(
              _card(
                _data(
                  name:
                      'Spaghetti bolognese with parmesan, a side salad and '
                      'garlic bread',
                ),
                style,
                photo: photo,
                textScale: 1.5,
              ),
            );
            await tester.pump();

            expect(tester.takeException(), isNull);
            expect(
              tester.getSize(find.byType(MealShareCard)),
              MealShareCard.size,
            );
            expect(find.text('Protein'), findsOneWidget);
            expect(find.text('Carbohydrates'), findsOneWidget);
            expect(find.text('Fat'), findsOneWidget);
            expect(find.text('kcal'), findsOneWidget);
          },
        );
      }
    }

    testWidgets('makes a 1080 x 1920 picture at 3x', (tester) async {
      final key = GlobalKey();
      tester.view.physicalSize = const Size(1200, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        _card(_data(), ShareCardStyle.dark, boundary: key),
      );
      await tester.pump();

      final boundary =
          key.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = (await tester.runAsync(
        () => boundary.toImage(pixelRatio: 3),
      ))!;
      expect(image.width, 1080);
      expect(image.height, 1920);
      image.dispose();
    });

    test('takes the wordmark of its style', () {
      expect(
        MealShareCard.wordmarkFor(ShareCardStyle.dark),
        isNot(MealShareCard.wordmarkFor(ShareCardStyle.light)),
      );
      expect(
        MealShareCard.wordmarkFor(ShareCardStyle.light),
        MealShareCard.wordmarkFor(ShareCardStyle.light),
      );
    });
  });
}
