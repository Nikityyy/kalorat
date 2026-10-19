import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kalorat/l10n/app_localizations.dart';
import 'package:kalorat/widgets/common/adaptive.dart';

Widget _app(TargetPlatform platform, void Function(BuildContext) onPressed) =>
    MaterialApp(
      theme: ThemeData(platform: platform),
      locale: const Locale('en'),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () => onPressed(context),
            child: const Text('open'),
          ),
        ),
      ),
    );

void main() {
  for (final platform in [TargetPlatform.iOS, TargetPlatform.android]) {
    testWidgets('confirm dialog is Material on ${platform.name}', (
      tester,
    ) async {
      bool? answer;
      await tester.pumpWidget(
        _app(platform, (context) async {
          answer = await showConfirmDialog(
            context,
            title: 'Delete?',
            message: 'Gone for good.',
            confirmLabel: 'Delete',
            destructive: true,
          );
        }),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      // Material on both: a web app cannot show the real iOS alert.
      expect(find.byType(CupertinoAlertDialog), findsNothing);
      expect(find.byType(AlertDialog), findsOneWidget);
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();
      expect(answer, isTrue);
    });

    testWidgets('prompt returns the typed values on ${platform.name}', (
      tester,
    ) async {
      List<String>? values;
      await tester.pumpWidget(
        _app(platform, (context) async {
          values = await showPromptDialog(
            context,
            title: 'Edit',
            fields: const [
              PromptField(initial: 'Toast'),
              PromptField(initial: '1', suffix: 'g'),
            ],
          );
        }),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(EditableText).first, 'Pasta');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(values, ['Pasta', '1']);
    });

    testWidgets('a cancelled prompt returns null on ${platform.name}', (
      tester,
    ) async {
      List<String>? values = const ['unchanged'];
      await tester.pumpWidget(
        _app(platform, (context) async {
          values = await showPromptDialog(
            context,
            title: 'Edit',
            fields: const [PromptField(initial: 'Toast')],
          );
        }),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(values, isNull);
    });
  }

  for (final (locale, expected) in [
    ('de', ['330', '12,5', '0,3', '70']),
    ('en', ['330', '12.5', '0.3', '70']),
  ]) {
    testWidgets('number fields start without a trailing zero in $locale', (
      tester,
    ) async {
      late List<String> texts;
      await tester.pumpWidget(
        Localizations(
          locale: Locale(locale),
          delegates: const [GlobalWidgetsLocalizations.delegate],
          child: Builder(
            builder: (context) {
              texts = [
                for (final v in [330.0, 12.5, 0.25, 70.04])
                  PromptField.numberText(context, v),
              ];
              return const SizedBox();
            },
          ),
        ),
      );
      expect(texts, expected);
    });
  }
}
