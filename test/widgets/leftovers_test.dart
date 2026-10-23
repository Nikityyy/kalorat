import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kalorat/l10n/app_localizations.dart';
import 'package:kalorat/screens/home/photo_review_view.dart';
import 'package:kalorat/widgets/leftovers_section.dart';

// A 1x1 transparent PNG.
final _png = Uint8List.fromList(const [
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, //
  0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
  0x0D, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
  0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49,
  0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
]);

Widget _app(Widget home, {bool scroll = false}) => MaterialApp(
  locale: const Locale('en'),
  localizationsDelegates: const [
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(body: scroll ? SingleChildScrollView(child: home) : home),
);

PhotoReviewView _review({
  bool hasLeftovers = false,
  ValueChanged<bool>? onLeftoversChanged,
  List<LeftoverPhoto> leftovers = const [],
  void Function(ImageSource)? onAddLeftover,
  bool canAnalyze = true,
  VoidCallback? onAnalyze,
}) => PhotoReviewView(
  photos: const ['a'],
  isAnalyzing: false,
  imageFor: (_) => MemoryImage(_png),
  onOpen: (_) {},
  onRemove: (_) async {},
  onReorder: (_, _) {},
  onDiscard: () {},
  onAddPhoto: () {},
  onAnalyze: onAnalyze ?? () {},
  hasLeftovers: hasLeftovers,
  onLeftoversChanged: onLeftoversChanged,
  leftovers: leftovers,
  onAddLeftover: onAddLeftover,
  canAnalyze: canAnalyze,
);

void main() {
  group('LeftoversSection', () {
    testWidgets('offers the camera and the gallery while there are none', (
      tester,
    ) async {
      final sources = <ImageSource>[];
      await tester.pumpWidget(
        _app(
          LeftoversSection(
            leftovers: const [],
            onAdd: sources.add,
            onRemove: (_) {},
          ),
          scroll: true,
        ),
      );
      expect(find.text('Subtract leftovers'), findsOneWidget);

      await tester.tap(find.text('Photograph leftovers'));
      await tester.tap(find.text('From photos'));
      expect(sources, [ImageSource.camera, ImageSource.gallery]);
    });

    testWidgets('shows the photos, removes one and offers another', (
      tester,
    ) async {
      final photo = LeftoverPhoto('p1', _png);
      final removed = <LeftoverPhoto>[];
      final sources = <ImageSource>[];
      await tester.pumpWidget(
        _app(
          LeftoversSection(
            leftovers: [photo],
            onAdd: sources.add,
            onRemove: removed.add,
          ),
          scroll: true,
        ),
      );
      expect(find.text('1 leftover photo'), findsOneWidget);
      expect(find.text('Photograph leftovers'), findsNothing);

      await tester.tap(find.text('Take another'));
      expect(sources, [ImageSource.camera]);

      await tester.tap(find.byIcon(Icons.close_rounded));
      expect(removed, [photo]);
    });

    testWidgets('stops offering photos at the maximum', (tester) async {
      await tester.pumpWidget(
        _app(
          LeftoversSection(
            leftovers: [
              for (var i = 0; i < maxLeftoverPhotos; i++)
                LeftoverPhoto('p$i', _png),
            ],
            onAdd: (_) {},
            onRemove: (_) {},
          ),
          scroll: true,
        ),
      );
      expect(find.text('$maxLeftoverPhotos leftover photos'), findsOneWidget);
      expect(find.text('Take another'), findsNothing);
    });
  });

  group('PhotoReviewView leftovers', () {
    // A phone-sized window, so nothing sits below the fold.
    setUp(() {
      final binding = TestWidgetsFlutterBinding.ensureInitialized();
      binding.platformDispatcher.views.first
        ..physicalSize = const Size(400, 1000)
        ..devicePixelRatio = 1;
    });
    tearDown(() {
      TestWidgetsFlutterBinding.ensureInitialized()
          .platformDispatcher
          .views
          .first
          .resetPhysicalSize();
    });

    testWidgets('does not ask while it cannot subtract leftovers', (
      tester,
    ) async {
      await tester.pumpWidget(_app(_review()));
      expect(find.text('Finished it all?'), findsNothing);
    });

    testWidgets('asks, and shows nothing more for "all"', (tester) async {
      await tester.pumpWidget(
        _app(_review(onLeftoversChanged: (_) {}, onAddLeftover: (_) {})),
      );
      expect(find.text('Finished it all?'), findsOneWidget);
      expect(find.text('Yes, all'), findsOneWidget);
      expect(find.text('From photos'), findsNothing);
    });

    testWidgets('"some left" reports the answer', (tester) async {
      final answers = <bool>[];
      await tester.pumpWidget(
        _app(_review(onLeftoversChanged: answers.add, onAddLeftover: (_) {})),
      );
      await tester.tap(find.text('No, some left'));
      expect(answers, [true]);
    });

    testWidgets('"some left" offers the photos', (tester) async {
      final sources = <ImageSource>[];
      await tester.pumpWidget(
        _app(
          _review(
            hasLeftovers: true,
            onLeftoversChanged: (_) {},
            onAddLeftover: sources.add,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('From photos'));
      await tester.pump();
      await tester.tap(find.text('From photos'));
      expect(sources, [ImageSource.gallery]);
    });

    testWidgets('analysing waits for the photo of the leftovers', (
      tester,
    ) async {
      var analysed = 0;
      await tester.pumpWidget(
        _app(_review(canAnalyze: false, onAnalyze: () => analysed++)),
      );
      await tester.tap(find.text('Analyze'));
      expect(analysed, 0);

      await tester.pumpWidget(
        _app(_review(canAnalyze: true, onAnalyze: () => analysed++)),
      );
      await tester.tap(find.text('Analyze'));
      expect(analysed, 1);
    });
  });
}
