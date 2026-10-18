import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kalorat/l10n/app_localizations.dart';
import 'package:kalorat/screens/privacy_policy_screen.dart';

Widget _app(String language) => MaterialApp(
  locale: Locale(language),
  localizationsDelegates: const [
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  supportedLocales: AppLocalizations.supportedLocales,
  home: const PrivacyPolicyScreen(),
);

void main() {
  test('English and German describe the same sections', () {
    final en = privacyPolicySections('en');
    final de = privacyPolicySections('de');
    expect(de.length, en.length);
    for (final section in [...en, ...de]) {
      expect(section.title, isNotEmpty);
      expect(section.body, isNotEmpty);
    }
  });

  test('states where meal photos and the API key go', () {
    final text = privacyPolicySections('en').map((s) => s.body).join(' ');
    expect(text, contains('Gemini'));
    expect(text, contains('never synced'));
  });

  for (final language in ['en', 'de']) {
    testWidgets('renders every section in $language', (tester) async {
      tester.view.physicalSize = const Size(390, 20000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_app(language));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      for (final section in privacyPolicySections(language)) {
        expect(find.text(section.title), findsOneWidget);
      }
    });
  }
}
