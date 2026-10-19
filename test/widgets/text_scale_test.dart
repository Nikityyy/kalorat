import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kalorat/l10n/app_localizations.dart';
import 'package:kalorat/main.dart' show maxTextScale;
import 'package:kalorat/models/meal_model.dart';
import 'package:kalorat/widgets/today/meal_row.dart';

Widget _app(Widget child, {required double scale, required Locale locale}) =>
    MaterialApp(
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: MediaQuery(
        data: MediaQueryData(
          size: const Size(320, 640),
          textScaler: TextScaler.linear(scale),
        ),
        child: Scaffold(
          body: Padding(padding: const EdgeInsets.all(20), child: child),
        ),
      ),
    );

MealModel _meal({bool pending = false, String status = 'done'}) => MealModel(
  id: 'm1',
  timestamp: DateTime(2026, 10, 19, 19, 34),
  photoPaths: const [],
  mealName: 'Spaghetti bolognese with parmesan and a side salad',
  calories: 1812,
  protein: 141.3,
  carbs: 98,
  fats: 26.4,
  isPending: pending,
  analysisStatus: status,
);

void main() {
  test('text scale is capped at 1.5', () {
    expect(maxTextScale, 1.5);
  });

  for (final scale in [1.0, 1.5]) {
    for (final locale in const [Locale('en'), Locale('de')]) {
      testWidgets(
        'a meal row fits a narrow phone at ${scale}x in ${locale.languageCode}',
        (tester) async {
          await tester.pumpWidget(
            _app(
              MealRow(meal: _meal()),
              scale: scale,
              locale: locale,
            ),
          );
          expect(tester.takeException(), isNull);
          expect(find.text('1812'), findsOneWidget);
        },
      );
    }
  }

  testWidgets('a failed analysis offers a retry', (tester) async {
    var retried = 0;
    await tester.pumpWidget(
      _app(
        MealRow(
          meal: _meal(pending: true, status: 'failed'),
          onRetry: () => retried++,
        ),
        scale: 1,
        locale: const Locale('en'),
      ),
    );
    await tester.tap(find.byIcon(Icons.refresh));
    expect(retried, 1);
  });

  testWidgets('a meal without a photo shows the first letter of its name', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        MealPhoto(meal: _meal(), size: 56),
        scale: 1.0,
        locale: const Locale('en'),
      ),
    );
    expect(find.text('S'), findsOneWidget);
  });
}
