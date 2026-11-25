import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kalorat/l10n/app_localizations.dart';
import 'package:kalorat/models/meal_model.dart';
import 'package:kalorat/providers/app_provider.dart';
import 'package:kalorat/theme/app_colors.dart';
import 'package:kalorat/widgets/today/day_ridge.dart';
import 'package:kalorat/widgets/today/meal_row.dart';
import 'package:kalorat/widgets/today/today_stats_grid.dart';

Widget _harness(
  Widget child, {
  double width = 390,
  double textScale = 1.0,
  Locale locale = const Locale('en'),
}) {
  return MaterialApp(
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
        size: Size(width, 844),
        textScaler: TextScaler.linear(textScale),
      ),
      child: Scaffold(body: SingleChildScrollView(child: child)),
    ),
  );
}

void main() {
  tearDown(() => AppColors.setDark(false));

  testWidgets('TodayStatsGrid and StreakStrip fit narrow phone at 1.5x text scale', (
    tester,
  ) async {
    for (final dark in [false, true]) {
      AppColors.setDark(dark);
      await tester.pumpWidget(
        _harness(
          width: 320,
          textScale: 1.5,
          Column(
            children: [
              StreakStrip(
                data: StreakData(
                  streak: 19,
                  last7DaysPresence: const [
                    true,
                    true,
                    true,
                    false,
                    true,
                    true,
                    true,
                  ],
                ),
                language: 'en',
              ),
              const TodayStatsGrid(
                eaten: 1840,
                calorieTarget: 2100,
                protein: 148,
                proteinTarget: 160,
                carbs: 235,
                carbTarget: 220,
                fats: 64,
                fatTarget: 70,
                isToday: true,
              ),
            ],
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(find.textContaining('19d streak'), findsOneWidget);
      expect(find.textContaining('1840'), findsOneWidget);
      expect(find.textContaining('260 kcal left'), findsOneWidget);
      expect(find.textContaining('15 g over'), findsOneWidget);
    }
  });

  testWidgets('compact DayRidge renders cleanly below TodayStatsGrid', (
    tester,
  ) async {
    await tester.pumpWidget(
      _harness(
        Column(
          children: [
            const TodayStatsGrid(
              eaten: 1200,
              calorieTarget: 2000,
              protein: 90,
              proteinTarget: 150,
              carbs: 130,
              carbTarget: 220,
              fats: 40,
              fatTarget: 70,
              isToday: true,
            ),
            const SizedBox(height: 12),
            DayRidge(
              height: DayRidge.compactHeight,
              pinSize: DayRidge.compactPinSize,
              steps: const [
                RidgeStep(id: 'm1', hour: 9.5, kcal: 450, name: 'Oats'),
                RidgeStep(id: 'm2', hour: 13.0, kcal: 750, name: 'Bowl'),
              ],
              target: 2000,
              endHour: 15,
              progress: const AlwaysStoppedAnimation(1.0),
            ),
          ],
        ),
      ),
    );
    final gridBox = tester.getRect(find.byType(TodayStatsGrid));
    final ridgeBox = tester.getRect(find.byType(DayRidge));
    expect(ridgeBox.top, greaterThanOrEqualTo(gridBox.bottom));
    expect(ridgeBox.height, DayRidge.compactHeight);
  });

  testWidgets('MealRow displays time and P/C/F macro summary', (tester) async {
    final meal = MealModel(
      id: 'm1',
      timestamp: DateTime(2026, 11, 25, 12, 30),
      photoPaths: const [],
      mealName: 'Chicken Rice Bowl',
      calories: 640,
      protein: 45.2,
      carbs: 60.4,
      fats: 18.1,
    );

    await tester.pumpWidget(
      _harness(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: MealRow(meal: meal),
        ),
        locale: const Locale('en'),
      ),
    );
    expect(find.textContaining('45g P'), findsOneWidget);
    expect(find.textContaining('60g C'), findsOneWidget);
    expect(find.textContaining('18g F'), findsOneWidget);

    await tester.pumpWidget(
      _harness(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: MealRow(meal: meal),
        ),
        locale: const Locale('de'),
      ),
    );
    expect(find.textContaining('45g E'), findsOneWidget);
    expect(find.textContaining('60g KH'), findsOneWidget);
    expect(find.textContaining('18g F'), findsOneWidget);
  });
}
