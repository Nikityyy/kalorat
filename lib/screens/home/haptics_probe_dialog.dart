import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../extensions/l10n_extension.dart';
import '../../l10n/app_localizations.dart';
import '../../utils/haptics_probe.dart';

/// One way of getting a haptic out of an iPhone browser. Overlay variants
/// put something real under the finger (see web/haptics_probe.js); the
/// others run from the button's tap handler.
class _Variant {
  final String? mode;
  final String Function(AppLocalizations l10n) title;
  final bool Function()? onTap;

  const _Variant(this.title, {this.mode, this.onTap});
}

final _variants = <_Variant>[
  _Variant((l) => l.hapticsProbeVisible, mode: 'visible'),
  _Variant((l) => l.hapticsProbeClear, mode: 'clear'),
  _Variant((l) => l.hapticsProbeFaint, mode: 'faint'),
  _Variant((l) => l.hapticsProbeStill, mode: 'still'),
  _Variant((l) => l.hapticsProbeLabel, mode: 'label'),
  _Variant((l) => l.hapticsProbeOutside, mode: 'outside'),
  _Variant((l) => l.hapticsProbeScripted, onTap: scriptedHapticProbe),
  _Variant((l) => l.hapticsProbeVibrate, onTap: vibrateHapticProbe),
];

/// The person taps each button and says which numbers they felt; each row
/// counts the taps the app saw and the times the switch toggled.
void showHapticsProbeDialog(BuildContext context) {
  showDialog<void>(context: context, builder: (_) => const _ProbeDialog());
}

class _ProbeDialog extends StatefulWidget {
  const _ProbeDialog();

  @override
  State<_ProbeDialog> createState() => _ProbeDialogState();
}

class _ProbeDialogState extends State<_ProbeDialog> {
  final _taps = List<int>.filled(_variants.length, 0);
  late final Timer _refresh;

  @override
  void initState() {
    super.initState();
    // The switch counts live in the page; read them a few times a second.
    _refresh = Timer.periodic(
      const Duration(milliseconds: 250),
      (_) => setState(() {}),
    );
  }

  @override
  void dispose() {
    _refresh.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AlertDialog(
      title: Text(l10n.hapticsTest),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.hapticsTestIntro),
            const SizedBox(height: 12),
            for (var i = 0; i < _variants.length; i++) ...[
              _ProbeTarget(
                id: i,
                mode: _variants[i].mode,
                child: FilledButton(
                  onPressed: () {
                    _variants[i].onTap?.call();
                    setState(() => _taps[i]++);
                  },
                  child: Text(
                    '${i + 1} · ${_variants[i].title(l10n)}',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 4, bottom: 10),
                child: Text(
                  l10n.hapticsTestCounts(_taps[i], hapticProbeToggles(i)),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
            SelectableText(
              hapticProbeInfo(),
              style: const TextStyle(fontFamily: 'JetBrains Mono', fontSize: 9),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.close),
        ),
      ],
    );
  }
}

/// Keeps the overlay of [mode] over [child] on every frame, so it follows
/// the dialog's entrance and scrolling.
class _ProbeTarget extends StatefulWidget {
  final int id;
  final String? mode;
  final Widget child;

  const _ProbeTarget({
    required this.id,
    required this.mode,
    required this.child,
  });

  @override
  State<_ProbeTarget> createState() => _ProbeTargetState();
}

class _ProbeTargetState extends State<_ProbeTarget>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker = createTicker((_) => _place());

  @override
  void initState() {
    super.initState();
    if (widget.mode != null) _ticker.start();
  }

  void _place() {
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.attached || !box.hasSize) return;
    var rect = box.localToGlobal(Offset.zero) & box.size;
    // Scrolled partly out of the dialog: the overlay is not clipped like
    // the button, so it goes away rather than cover something else.
    final viewport = Scrollable.maybeOf(context)?.context.findRenderObject();
    if (viewport is RenderBox && viewport.hasSize) {
      final visible = viewport.localToGlobal(Offset.zero) & viewport.size;
      if (visible.intersect(rect) != rect) rect = Rect.zero;
    }
    placeHapticProbe(
      widget.id,
      widget.mode!,
      rect.left,
      rect.top,
      rect.width,
      rect.height,
    );
  }

  @override
  void dispose() {
    _ticker.dispose();
    removeHapticProbe(widget.id);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
