import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kalorat/l10n/app_localizations.dart';
import 'package:kalorat/screens/home/analyzing_view.dart';
import 'package:kalorat/screens/home/meal_context_sheet.dart';
import 'package:kalorat/screens/home/quick_log_sheet.dart';
import 'package:kalorat/screens/meal_detail/components_section.dart';
import 'package:kalorat/screens/meal_detail/retry_sheet.dart';
import 'package:kalorat/theme/app_theme.dart';
import 'package:kalorat/widgets/common/warm_up.dart';

void main() {
  testWidgets('warm-up draws each widget once, under the app, then nothing', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        locale: const Locale('de'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => WarmUpLayer(child: child!),
        home: const Scaffold(body: Text('app')),
      ),
    );

    final builders = <WidgetBuilder>[
      mealContextSheetWarmUp,
      analyzingViewWarmUp,
      retrySheetWarmUp,
      componentSheetWarmUp,
      quickLogSheetWarmUp,
    ];
    final done = WarmUp.run(builders, delay: Duration.zero);
    var drawn = 0;
    for (var i = 0; i < 60 && drawn < builders.length; i++) {
      await tester.pump(const Duration(milliseconds: 50));
      if (find.byType(WarmUpSheet).evaluate().isNotEmpty ||
          find.byType(AnalyzingView).evaluate().isNotEmpty) {
        drawn++;
        expect(tester.takeException(), isNull);
      }
    }
    await tester.pump(const Duration(milliseconds: 300));
    await done;

    expect(drawn, builders.length);
    expect(find.byType(WarmUpSheet), findsNothing);
    expect(find.byType(AnalyzingView), findsNothing);
    expect(find.text('app'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
