import 'package:flutter/material.dart';

/// Draws widgets once, hidden under the app, so the first time they really
/// show up does not stall. On an iPhone the browser compiles the code, the
/// shaders and the glyphs for a sheet the first time it is drawn, which froze
/// the first slide-in of a sheet for a moment; every later one was smooth.
///
/// [WarmUpLayer] sits under the app's pages, which are opaque, so what it
/// draws is painted and then covered. [WarmUp.run] shows one widget per frame,
/// with a pause between them, so no single frame gets long.
class WarmUp {
  WarmUp._();

  static final ValueNotifier<WidgetBuilder?> _current = ValueNotifier(null);
  static bool _started = false;

  /// Shows each of [builders] for one frame, after [delay]. Runs once per
  /// app start; later calls do nothing.
  static Future<void> run(
    List<WidgetBuilder> builders, {
    Duration delay = const Duration(seconds: 2),
    Duration gap = const Duration(milliseconds: 150),
  }) async {
    if (_started) return;
    _started = true;
    await Future<void>.delayed(delay);
    for (final builder in builders) {
      _current.value = builder;
      // Built and painted in the next frame, then taken away.
      await WidgetsBinding.instance.endOfFrame;
      _current.value = null;
      await Future<void>.delayed(gap);
    }
  }
}

/// Holds what [WarmUp.run] draws, under [child]. Wrap the app's pages.
class WarmUpLayer extends StatelessWidget {
  final Widget child;

  const WarmUpLayer({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        ValueListenableBuilder<WidgetBuilder?>(
          valueListenable: WarmUp._current,
          builder: (context, builder, _) {
            if (builder == null) return const SizedBox.shrink();
            return IgnorePointer(
              child: ExcludeSemantics(
                child: TickerMode(
                  enabled: false,
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Builder(builder: builder),
                  ),
                ),
              ),
            );
          },
        ),
        child,
      ],
    );
  }
}

/// A sheet's content on the surface a modal bottom sheet gives it, for
/// [WarmUp.run].
class WarmUpSheet extends StatelessWidget {
  final Widget child;

  const WarmUpSheet({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).bottomSheetTheme;
    return Material(
      color: theme.backgroundColor,
      shape: theme.shape,
      clipBehavior: theme.clipBehavior ?? Clip.none,
      child: child,
    );
  }
}
