import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../extensions/l10n_extension.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_typography.dart';
import '../../utils/analysis_tracker.dart';

/// Shown while a meal is analysed: the photo full screen, and over its lower
/// part what the analysis has found so far. The components appear as chips
/// as the answer names them, and a ridge climbs from left to right as the
/// estimates come in. A meal described in words sits on the green field with
/// its description on top.
class AnalyzingView extends StatefulWidget {
  final ImageProvider? heroImage;
  final AnalysisTracker tracker;

  const AnalyzingView({
    super.key,
    required this.heroImage,
    required this.tracker,
  });

  @override
  State<AnalyzingView> createState() => _AnalyzingViewState();
}

class _AnalyzingViewState extends State<AnalyzingView>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker = createTicker(_tick);
  Duration _last = Duration.zero;
  Duration _stageStart = Duration.zero;
  Duration _now = Duration.zero;
  int _serial = -1;

  /// The progress line as drawn, from 0 to 1.
  double _shown = 0;

  /// Where the line was when each estimate came in, for its tick.
  final List<double> _estimateMarks = [];

  /// When each component chip appeared, to fade it in and to light the
  /// newest one.
  final List<Duration> _chipBorn = [];

  /// The number as drawn in the end, rolling up to the result.
  double _rolled = 0;
  double _rollFrom = 0;
  Duration? _doneAt;

  @override
  void initState() {
    super.initState();
    widget.tracker.addListener(_onTracker);
    _onTracker();
    _ticker.start();
  }

  @override
  void didUpdateWidget(AnalyzingView old) {
    super.didUpdateWidget(old);
    if (old.tracker != widget.tracker) {
      old.tracker.removeListener(_onTracker);
      widget.tracker.addListener(_onTracker);
    }
  }

  @override
  void dispose() {
    widget.tracker.removeListener(_onTracker);
    _ticker.dispose();
    super.dispose();
  }

  void _onTracker() {
    final t = widget.tracker;
    if (t.stageSerial != _serial) {
      _serial = t.stageSerial;
      _stageStart = _now;
    }
    while (_estimateMarks.length < t.estimates.length) {
      _estimateMarks.add(_shown);
    }
    if (_estimateMarks.length > t.estimates.length) _estimateMarks.clear();
    while (_chipBorn.length < t.components.length) {
      _chipBorn.add(_now);
    }
    if (_chipBorn.length > t.components.length) {
      _chipBorn.removeRange(t.components.length, _chipBorn.length);
    }
    if (t.stage == AnalysisStage.done && _doneAt == null) {
      _doneAt = _now;
      _rollFrom = t.estimates.isNotEmpty ? t.estimates.first : 0;
      _rolled = _rollFrom;
    }
    if (mounted) setState(() {});
  }

  /// The stretch of the line a stage may cover. The line eases into it and
  /// creeps on slowly while the stage lasts, but never past its end: only
  /// a real event moves it further.
  (double, double) _stageSpan() {
    final t = widget.tracker;
    switch (t.stage) {
      case AnalysisStage.reading:
        return (0.06, 0.38);
      case AnalysisStage.components:
        final n = math.min(t.components.length, 6);
        return (0.42 + 0.03 * n, 0.66);
      case AnalysisStage.estimates:
        final done = t.estimates.length / t.total;
        final start = 0.68 + 0.28 * done;
        return (start, math.min(start + 0.12, 0.97));
      case AnalysisStage.done:
        return (1, 1);
    }
  }

  void _tick(Duration elapsed) {
    final dt = (elapsed - _last).inMicroseconds / 1e6;
    _last = elapsed;
    _now = elapsed;
    final (start, end) = _stageSpan();
    final inStage = (elapsed - _stageStart).inMicroseconds / 1e6;
    final goal = start + (end - start) * (1 - math.exp(-inStage / 5));
    final reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final next = reduce
        ? goal
        : _shown + (goal - _shown) * (1 - math.exp(-dt / 0.35));
    final calories = widget.tracker.calories;
    if (calories != null && _doneAt != null) {
      final t = ((elapsed - _doneAt!).inMilliseconds / 650).clamp(0.0, 1.0);
      _rolled = reduce
          ? calories
          : _rollFrom +
                (calories - _rollFrom) * Curves.easeOutCubic.transform(t);
    }
    setState(() => _shown = math.max(_shown, next));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final t = widget.tracker;
    final media = MediaQuery.of(context);
    final image = widget.heroImage;
    final onPhoto = image != null;

    final (String title, String subtitle) = switch (t.stage) {
      AnalysisStage.reading => (
        t.textOnly ? l10n.analysisReadingText : l10n.analysisReadingPhoto,
        t.total > 1 ? l10n.analysisParallel(t.total) : l10n.analysisSingle,
      ),
      AnalysisStage.components => (
        l10n.analysisComponentsFound(t.components.length),
        l10n.analysisAmounts,
      ),
      AnalysisStage.estimates => (
        l10n.analysisEstimateOf(t.estimates.length, t.total),
        l10n.analysisSoFar(
          t.estimates.map((e) => e.round().toString()).join(' · '),
        ),
      ),
      AnalysisStage.done => (
        '',
        t.estimates.length > 1
            ? l10n.analysisMedianOf(t.estimates.length)
            : l10n.analysisDone,
      ),
    };

    final bottom = Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, media.padding.bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (t.stage == AnalysisStage.done) ...[
            Text(
              subtitle,
              style: AppTypography.secondary.copyWith(
                color: Colors.white.withValues(alpha: 0.78),
              ),
            ),
            const SizedBox(height: 2),
            Semantics(
              liveRegion: true,
              label: '${(t.calories ?? 0).round()} ${l10n.kcal}',
              excludeSemantics: true,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '${_rolled.round()}',
                    style: AppTypography.hero(size: 72).copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    l10n.kcal,
                    style: AppTypography.body.copyWith(
                      color: Colors.white.withValues(alpha: 0.78),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            Semantics(
              liveRegion: true,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                layoutBuilder: (current, previous) => Stack(
                  alignment: Alignment.topLeft,
                  children: [...previous, ?current],
                ),
                child: Text(
                  title,
                  key: ValueKey(title),
                  style: AppTypography.heading.copyWith(color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: AppTypography.secondary.copyWith(
                color: Colors.white.withValues(alpha: 0.78),
              ),
            ),
          ],
          if (t.components.isNotEmpty) ...[
            const SizedBox(height: 14),
            _ComponentChips(
              components: t.components,
              born: _chipBorn,
              now: _now,
              done: t.stage == AnalysisStage.done,
            ),
          ],
          const SizedBox(height: 20),
          SizedBox(
            height: 56,
            width: double.infinity,
            child: CustomPaint(
              painter: _ClimbPainter(
                progress: _shown,
                marks: _estimateMarks,
                pulse: (_now.inMilliseconds % 1600) / 1600,
                accent: onPhoto
                    ? AppColors.styrianForestLight
                    : AppColors.pureWhite,
              ),
            ),
          ),
        ],
      ),
    );

    return ColoredBox(
      color: onPhoto ? AppColors.deepSpaceBlack : AppColors.styrianForestColor,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (image != null) ...[
            Image(image: image, fit: BoxFit.cover, gaplessPlayback: true),
            // Dark under the words, clear over the food.
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: [0, 0.18, 0.42, 1],
                  colors: [
                    Color(0x59000000),
                    Color(0x00000000),
                    Color(0x14000000),
                    Color(0xE6000000),
                  ],
                ),
              ),
            ),
          ] else if (t.description != null && t.description!.isNotEmpty)
            Positioned(
              left: 20,
              right: 20,
              top: media.padding.top + 72,
              child: Text(
                '„${t.description}“',
                maxLines: 7,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.title.copyWith(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.w600,
                  height: 1.18,
                ),
              ),
            ),
          Positioned(left: 0, right: 0, bottom: 0, child: bottom),
        ],
      ),
    );
  }
}

class _ComponentChips extends StatelessWidget {
  final List<TrackedComponent> components;
  final List<Duration> born;
  final Duration now;
  final bool done;

  const _ComponentChips({
    required this.components,
    required this.born,
    required this.now,
    required this.done,
  });

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final l10n = context.l10n;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (var i = 0; i < components.length; i++)
          Builder(
            builder: (context) {
              final age = i < born.length
                  ? (now - born[i]).inMilliseconds
                  : 100000;
              final appear = reduce
                  ? 1.0
                  : Curves.easeOutCubic.transform((age / 320).clamp(0.0, 1.0));
              // The newest chip is lit for a moment.
              final lit = !done && i == components.length - 1 && age < 1400;
              final grams = components[i].grams;
              return Opacity(
                opacity: appear,
                child: Transform.translate(
                  offset: Offset(0, 8 * (1 - appear)),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: lit
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(
                        AppTheme.borderRadius,
                      ),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: lit ? 1 : 0.24),
                      ),
                    ),
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(text: components[i].name),
                          if (grams != null) ...[
                            const TextSpan(text: '  '),
                            TextSpan(
                              text: '${grams.round()}',
                              style: AppTypography.number(
                                size: 15,
                                color: Colors.white.withValues(alpha: 0.78),
                              ),
                            ),
                            TextSpan(
                              text: ' ${l10n.grams}',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.78),
                              ),
                            ),
                          ],
                        ],
                      ),
                      style: AppTypography.secondary.copyWith(
                        color: lit ? AppColors.deepSpaceBlack : Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}

/// The climb: a ridge across the width, drawn solid up to [progress] with a
/// wash under it and dotted ahead. A tick stands where each estimate came
/// in; a dot marks where the climb is.
class _ClimbPainter extends CustomPainter {
  final double progress;
  final List<double> marks;
  final double pulse;
  final Color accent;

  _ClimbPainter({
    required this.progress,
    required this.marks,
    required this.pulse,
    required this.accent,
  });

  /// The ridge's height at [x] (0 to 1): a few summits, rising overall.
  static double heightAt(double x) {
    final h =
        0.30 +
        0.30 * x +
        0.16 * math.sin(2 * math.pi * (1.6 * x + 0.05)) +
        0.08 * math.sin(2 * math.pi * (3.7 * x + 0.3)) +
        0.03 * math.sin(2 * math.pi * 9 * x);
    return h.clamp(0.05, 1.0);
  }

  @override
  void paint(Canvas canvas, Size size) {
    const samples = 96;
    final top = 8.0;
    final base = size.height;
    Offset at(double x) =>
        Offset(x * size.width, base - (base - top) * heightAt(x));

    final p = progress.clamp(0.0, 1.0);
    final done = Path()..moveTo(0, at(0).dy);
    for (var i = 1; i <= samples; i++) {
      final x = i / samples;
      if (x > p) break;
      done.lineTo(at(x).dx, at(x).dy);
    }
    final head = at(p);
    done.lineTo(head.dx, head.dy);

    final wash = Path.from(done)
      ..lineTo(head.dx, base)
      ..lineTo(0, base)
      ..close();
    canvas.drawPath(wash, Paint()..color = accent.withValues(alpha: 0.22));

    // Ahead: dots along the rest of the ridge.
    final dot = Paint()..color = Colors.white.withValues(alpha: 0.38);
    for (var x = p + 0.012; x <= 1; x += 0.014) {
      canvas.drawCircle(at(x), 1.1, dot);
    }

    canvas.drawPath(
      done,
      Paint()
        ..color = accent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round,
    );

    final tick = Paint()
      ..color = Colors.white
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    for (final m in marks) {
      final o = at(m.clamp(0.0, 1.0));
      canvas.drawLine(Offset(o.dx, o.dy - 6), Offset(o.dx, o.dy - 14), tick);
    }

    if (p < 1) {
      canvas.drawCircle(
        head,
        6 + 6 * pulse,
        Paint()..color = accent.withValues(alpha: 0.35 * (1 - pulse)),
      );
    }
    canvas.drawCircle(head, 6, Paint()..color = Colors.white);
    canvas.drawCircle(head, 4, Paint()..color = accent);
  }

  @override
  bool shouldRepaint(_ClimbPainter old) =>
      old.progress != progress ||
      old.pulse != pulse ||
      old.marks.length != marks.length ||
      old.accent != accent;
}
