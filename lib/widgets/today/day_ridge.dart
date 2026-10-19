import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../services/photo_store.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../common/meal_mark.dart';

/// One meal on the ridge: when it was eaten, in hours after the logical day
/// started, and what it added.
class RidgeStep {
  final String id;
  final double hour;
  final double kcal;
  final String? photoPath;

  /// Shown as a letter when there is no photo.
  final String name;

  const RidgeStep({
    required this.id,
    required this.hour,
    required this.kcal,
    this.photoPath,
    this.name = '',
  });
}

/// The day as a climb: every meal is a step up, the dashed line is the
/// target. Each step carries the meal's photo as a pin.
///
/// [progress] drives the climb of the steps in [fresh]: from 0 to 0.52 the
/// step rises, from 0.52 to 1 its pin lands. Every other step is drawn as it
/// is.
class DayRidge extends StatelessWidget {
  final List<RidgeStep> steps;
  final double target;

  /// The hour the line runs to: now on today, the end of the day before.
  final double endHour;

  /// The hour the clock shows when the logical day starts.
  final int dayStartHour;
  final Set<String> fresh;
  final Animation<double> progress;
  final ValueChanged<String>? onPinTap;

  const DayRidge({
    super.key,
    required this.steps,
    required this.target,
    required this.endHour,
    required this.progress,
    this.dayStartHour = 0,
    this.fresh = const {},
    this.onPinTap,
  });

  static const height = 176.0;
  static const pinSize = 40.0;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return AnimatedBuilder(
            animation: progress,
            builder: (context, _) {
              final layout = _RidgeLayout(
                steps: steps,
                target: target,
                endHour: endHour,
                fresh: fresh,
                t: progress.value,
                size: Size(constraints.maxWidth, height),
              );
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _RidgePainter(
                        layout,
                        dayStartHour,
                        AppColors.isDark,
                      ),
                    ),
                  ),
                  for (final pin in layout.pins)
                    Positioned(
                      left: pin.center.dx - pinSize / 2,
                      top: pin.center.dy - pinSize / 2,
                      width: pinSize,
                      height: pinSize,
                      child: Opacity(
                        opacity: pin.opacity,
                        child: Transform.scale(
                          scale: pin.scale,
                          alignment: Alignment.bottomCenter,
                          child: _Pin(
                            path: pin.step.photoPath,
                            name: pin.step.name,
                            onTap: onPinTap == null
                                ? null
                                : () => onPinTap!(pin.step.id),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _PinPlacement {
  final RidgeStep step;
  final Offset center;

  /// Where the pin's stem meets its step.
  final Offset foot;
  final double scale;
  final double opacity;

  const _PinPlacement(
    this.step,
    this.center,
    this.foot,
    this.scale,
    this.opacity,
  );
}

class _RidgeLayout {
  static const _slant = 6.0;
  static const _axisSpace = 22.0;
  static const _pinGap = 6.0;

  final List<Offset> line = [];
  final List<_PinPlacement> pins = [];
  late final double base;
  late final double goalY;
  late final Offset end;
  late final bool reached;
  late final double startHour;
  late final double lastHour;
  late final double Function(double hour) xOf;

  _RidgeLayout({
    required List<RidgeStep> steps,
    required double target,
    required double endHour,
    required Set<String> fresh,
    required double t,
    required Size size,
  }) {
    const pin = DayRidge.pinSize;
    final sorted = [...steps]..sort((a, b) => a.hour.compareTo(b.hour));
    final total = sorted.fold<double>(0, (sum, s) => sum + s.kcal);
    final scaleMax = math.max(math.max(target, total), 1.0);

    // The day is drawn from 5 o'clock on, or from the first meal if earlier.
    startHour = sorted.isEmpty
        ? 5
        : math.min(5, sorted.first.hour.floorToDouble());
    lastHour = 24;
    base = size.height - _axisSpace;
    final top = pin + 6;
    goalY = base - (base - top) * target / scaleMax;
    double x(double hour) =>
        size.width * ((hour - startHour) / (lastHour - startHour)).clamp(0, 1);
    xOf = x;
    double y(double kcal) => base - (base - top) * kcal / scaleMax;

    final rise = Curves.easeOutCubic.transform((t / 0.52).clamp(0, 1));
    final land = ((t - 0.52) / 0.48).clamp(0.0, 1.0);

    double climbed = 0;
    line.add(Offset(0, base));
    final feet = <(RidgeStep, Offset, bool)>[];
    for (final step in sorted) {
      final isFresh = fresh.contains(step.id);
      final added = isFresh ? step.kcal * rise : step.kcal;
      // Meals close together share the slant; the line never runs back.
      final sx = math.max(x(step.hour), line.last.dx);
      line.add(Offset(math.max(line.last.dx, sx - _slant), y(climbed)));
      climbed += added;
      line.add(Offset(sx, y(climbed)));
      feet.add((step, Offset(sx, y(climbed)), isFresh));
    }
    end = Offset(math.max(line.last.dx, x(endHour)), y(climbed));
    line.add(end);
    reached = target > 0 && climbed >= target;

    // Pins sit above their step. Where two would touch, the later one moves
    // right and its stem leans back to its step.
    final centers = <double>[];
    for (final (_, foot, _) in feet) {
      var cx = foot.dx.clamp(pin / 2, size.width - pin / 2);
      if (centers.isNotEmpty && cx - centers.last < pin + _pinGap) {
        cx = centers.last + pin + _pinGap;
      }
      centers.add(cx);
    }
    // If that pushed pins past the right edge, walk back from the edge.
    for (var i = centers.length - 1; i >= 0; i--) {
      final limit = i == centers.length - 1
          ? size.width - pin / 2
          : centers[i + 1] - pin - _pinGap;
      if (centers[i] > limit) centers[i] = limit;
    }
    for (var i = 0; i < feet.length; i++) {
      final (step, foot, isFresh) = feet[i];
      final cy = math.max(pin / 2, foot.dy - 10 - pin / 2);
      final scale = isFresh
          ? 0.6 + 0.4 * Curves.easeOutBack.transform(land)
          : 1.0;
      final opacity = isFresh ? Curves.easeOut.transform(land) : 1.0;
      pins.add(
        _PinPlacement(step, Offset(centers[i], cy), foot, scale, opacity),
      );
    }
  }
}

class _RidgePainter extends CustomPainter {
  final _RidgeLayout layout;
  final int dayStartHour;
  final bool dark;

  _RidgePainter(this.layout, this.dayStartHour, this.dark);

  @override
  void paint(Canvas canvas, Size size) {
    final accent = AppColors.primary;

    // The base and the target.
    canvas.drawLine(
      Offset(0, layout.base),
      Offset(size.width, layout.base),
      Paint()
        ..color = AppColors.border
        ..strokeWidth = 1,
    );
    final goal = Paint()
      ..color = layout.reached ? accent : AppColors.ink3
      ..strokeWidth = 1.2;
    for (double x = 0; x < size.width; x += 9) {
      canvas.drawLine(
        Offset(x, layout.goalY),
        Offset(math.min(x + 4, size.width), layout.goalY),
        goal,
      );
    }

    final path = Path()..moveTo(layout.line.first.dx, layout.line.first.dy);
    for (final p in layout.line.skip(1)) {
      path.lineTo(p.dx, p.dy);
    }
    final fill = Path.from(path)
      ..lineTo(layout.end.dx, layout.base)
      ..close();
    canvas.drawPath(fill, Paint()..color = AppColors.accentSoft);

    // Stems from each pin down to its step.
    final stem = Paint()
      ..color = AppColors.ink3
      ..strokeWidth = 1;
    for (final pin in layout.pins) {
      if (pin.opacity <= 0) continue;
      canvas.drawLine(
        Offset(pin.center.dx, pin.center.dy + DayRidge.pinSize / 2),
        pin.foot,
        stem..color = AppColors.ink3.withValues(alpha: 0.6 * pin.opacity),
      );
    }

    canvas.drawPath(
      path,
      Paint()
        ..color = accent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(layout.end, 4, Paint()..color = accent);

    // Clock hours under the base.
    for (final hour in [6, 12, 18, 24]) {
      final h = hour.toDouble();
      if (h < layout.startHour) continue;
      final clock = (hour + dayStartHour) % 24 == 0
          ? 24
          : (hour + dayStartHour) % 24;
      final label = TextPainter(
        text: TextSpan(
          text: '$clock',
          style: AppTypography.number(
            size: 12,
            weight: FontWeight.w400,
            color: AppColors.ink3,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final x = layout.xOf(h);
      final left = (x - label.width / 2).clamp(0.0, size.width - label.width);
      label.paint(canvas, Offset(left, layout.base + 5));
    }
  }

  @override
  bool shouldRepaint(_RidgePainter old) => true;
}

class _Pin extends StatelessWidget {
  final String? path;
  final String name;
  final VoidCallback? onTap;

  const _Pin({this.path, this.name = '', this.onTap});

  @override
  Widget build(BuildContext context) {
    final photo = path;
    final mark = MealMark(name: name, size: DayRidge.pinSize - 4);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.canvas,
          border: Border.all(color: AppColors.border),
        ),
        padding: const EdgeInsets.all(2),
        child: ClipOval(
          child: photo == null || photo.isEmpty
              ? mark
              : Image(
                  image: PhotoStore.instance.imageProvider(
                    photo,
                    cacheWidth: 120,
                  ),
                  fit: BoxFit.cover,
                  gaplessPlayback: true,
                  errorBuilder: (_, _, _) => mark,
                ),
        ),
      ),
    );
  }
}
