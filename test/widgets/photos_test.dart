import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kalorat/l10n/app_localizations.dart';
import 'package:kalorat/screens/home/photo_review_view.dart';
import 'package:kalorat/screens/home/photo_viewer.dart';

// A 1x1 transparent PNG.
final _png = Uint8List.fromList(const [
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, //
  0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
  0x0D, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
  0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49,
  0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
]);

Widget _app(Widget home) => MaterialApp(
  locale: const Locale('en'),
  localizationsDelegates: const [
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  supportedLocales: AppLocalizations.supportedLocales,
  home: home,
);

void main() {
  testWidgets('holding a photo and dragging it reorders the grid', (
    tester,
  ) async {
    final photos = ['a', 'b', 'c'];
    await tester.pumpWidget(
      _app(
        StatefulBuilder(
          builder: (context, setState) => PhotoReviewView(
            photos: photos,
            isAnalyzing: false,
            imageFor: (_) => MemoryImage(_png),
            onOpen: (_) {},
            onRemove: (_) async {},
            onReorder: (from, to) =>
                setState(() => photos.insert(to, photos.removeAt(from))),
            onDiscard: () {},
            onAddPhoto: () {},
            onAnalyze: () {},
          ),
        ),
      ),
    );
    expect(find.text('Cover'), findsOneWidget);
    expect(find.text('Hold and drag to change the order'), findsOneWidget);

    // Drag the first photo onto the second's place.
    final first = tester.getCenter(find.byType(Image).at(0));
    final second = tester.getCenter(find.byType(Image).at(1));
    final gesture = await tester.startGesture(first);
    await tester.pump(const Duration(milliseconds: 600));
    await gesture.moveTo(second);
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();
    expect(photos, ['b', 'a', 'c']);
  });

  testWidgets('the viewer swipes between photos and returns the last one', (
    tester,
  ) async {
    int? shown;
    await tester.pumpWidget(
      _app(
        Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                shown = await showPhotoViewer(
                  context,
                  images: [MemoryImage(_png), MemoryImage(_png)],
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('1/2'), findsOneWidget);
    await tester.fling(find.byType(PageView), const Offset(-300, 0), 1000);
    await tester.pumpAndSettle();
    expect(find.text('2/2'), findsOneWidget);
    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();
    expect(shown, 1);
  });

  testWidgets('dragging the viewer down closes it', (tester) async {
    await tester.pumpWidget(
      _app(
        Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () =>
                  showPhotoViewer(context, images: [MemoryImage(_png)]),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.byType(PageView), findsOneWidget);
    await tester.drag(find.byType(PageView), const Offset(0, 300));
    await tester.pumpAndSettle();
    expect(find.byType(PageView), findsNothing);
  });
}
