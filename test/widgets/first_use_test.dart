import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kalorat/l10n/app_localizations.dart';
import 'package:kalorat/widgets/first_use_card.dart';

Widget _app(Widget child, {required double scale, Locale? locale}) =>
    MaterialApp(
      locale: locale ?? const Locale('en'),
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
        child: Scaffold(body: child),
      ),
    );

void main() {
  for (final scale in [1.0, 1.5]) {
    testWidgets('first use card fits at ${scale}x and dismisses', (
      tester,
    ) async {
      var dismissed = 0;
      var acted = 0;
      await tester.pumpWidget(
        _app(
          SingleChildScrollView(
            child: FirstUseCard(
              icon: Icons.cloud_upload_outlined,
              title: 'Keep your meals safe',
              body:
                  'Your data is only stored on this device. Signing in with '
                  'Google backs it up and makes it available on other devices.',
              dismissLabel: 'Not now',
              actionLabel: 'Open settings',
              onDismiss: () => dismissed++,
              onAction: () => acted++,
            ),
          ),
          scale: scale,
        ),
      );
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Not now'));
      await tester.tap(find.text('Open settings'));
      expect((dismissed, acted), (1, 1));
    });
  }
}
