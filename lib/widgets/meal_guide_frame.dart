import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Painter for the framing guide: four rounded corner brackets joined by a
/// faint line, optionally over a fill.
class MealGuideFramePainter extends CustomPainter {
  final Color cornerColor;
  final Color lineColor;
  final Color fillColor;
  final double strokeWidth;
  final double cornerLength;
  final double borderRadius;

  MealGuideFramePainter({
    this.cornerColor = Colors.white,
    this.lineColor = const Color(0x59FFFFFF),
    this.fillColor = Colors.transparent,
    this.strokeWidth = 4.0,
    this.cornerLength = 34.0,
    this.borderRadius = 26.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double r = math.min(borderRadius, size.shortestSide / 2);
    final double cl = math.max(
      0,
      math.min(cornerLength, size.shortestSide / 2 - r),
    );
    final RRect fullRRect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(r),
    );

    if (fillColor.a > 0) {
      canvas.drawRRect(fullRRect, Paint()..color = fillColor);
    }

    // 1. Draw faint connecting border
    final Paint linePaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawRRect(fullRRect, linePaint);

    // 2. Draw 4 thick corner brackets
    final Paint cornerPaint = Paint()
      ..color = cornerColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    // Top-Left Corner
    final Path tlPath = Path()
      ..moveTo(0, r + cl)
      ..lineTo(0, r)
      ..arcToPoint(Offset(r, 0), radius: Radius.circular(r))
      ..lineTo(r + cl, 0);
    canvas.drawPath(tlPath, cornerPaint);

    // Top-Right Corner
    final Path trPath = Path()
      ..moveTo(size.width - (r + cl), 0)
      ..lineTo(size.width - r, 0)
      ..arcToPoint(Offset(size.width, r), radius: Radius.circular(r))
      ..lineTo(size.width, r + cl);
    canvas.drawPath(trPath, cornerPaint);

    // Bottom-Right Corner
    final Path brPath = Path()
      ..moveTo(size.width, size.height - (r + cl))
      ..lineTo(size.width, size.height - r)
      ..arcToPoint(
        Offset(size.width - r, size.height),
        radius: Radius.circular(r),
      )
      ..lineTo(size.width - (r + cl), size.height);
    canvas.drawPath(brPath, cornerPaint);

    // Bottom-Left Corner
    final Path blPath = Path()
      ..moveTo(r + cl, size.height)
      ..lineTo(r, size.height)
      ..arcToPoint(Offset(0, size.height - r), radius: Radius.circular(r))
      ..lineTo(0, size.height - (r + cl));
    canvas.drawPath(blPath, cornerPaint);
  }

  @override
  bool shouldRepaint(covariant MealGuideFramePainter old) =>
      old.cornerColor != cornerColor ||
      old.lineColor != lineColor ||
      old.fillColor != fillColor ||
      old.strokeWidth != strokeWidth ||
      old.cornerLength != cornerLength ||
      old.borderRadius != borderRadius;
}

/// A barcode the camera has locked on to: the guide's corners close around
/// [box] (in overlay coordinates) and the line under the guide says what
/// happens with it.
class GuideLock {
  final Rect box;

  /// e.g. "Looking up the product…", or the product's name once found.
  final String title;

  /// The code's digits, shown under [title].
  final String code;

  /// The product was found; the check replaces the spinner.
  final bool found;

  const GuideLock({
    required this.box,
    required this.title,
    required this.code,
    this.found = false,
  });
}

/// Overlay widget displaying the square meal framing guide box and localized
/// instruction text below it. With a [lock], the corners close around the
/// barcode in green and the text becomes the lookup's status.
class MealGuideOverlay extends StatelessWidget {
  final String guideText;
  final GuideLock? lock;

  const MealGuideOverlay({super.key, required this.guideText, this.lock});

  static const _lockColor = AppColors.styrianForestLight;

  /// The square guide box in an overlay of [size] with safe-area [padding].
  /// The barcode scanner uses it too.
  static Rect guideRect(Size size, EdgeInsets padding) {
    // Camera viewport bounds (between top header tools and bottom shutter bar)
    final double topBound = padding.top + 68.0;
    final double bottomBound = size.height - (padding.bottom + 130.0);
    final double availableHeight = math.max(100.0, bottomBound - topBound);

    // Square box size responsive to width and available height
    final double boxSize = math.min(
      size.width * 0.74,
      math.max(180.0, availableHeight * 0.62),
    );

    // Exact 1:1 vertical and horizontal centering in open camera viewport
    return Rect.fromLTWH(
      (size.width - boxSize) / 2.0,
      topBound + (availableHeight - boxSize) / 2.0,
      boxSize,
      boxSize,
    );
  }

  @override
  Widget build(BuildContext context) {
    final lock = this.lock;
    return IgnorePointer(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final guide = guideRect(
            constraints.biggest,
            MediaQuery.paddingOf(context),
          );

          return Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.topCenter,
            children: [
              // The corners close around the code on the held preview and
              // spring back to the guide when it is gone.
              TweenAnimationBuilder<double>(
                tween: Tween(end: lock == null ? 0 : 1),
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                builder: (context, locked, _) => TweenAnimationBuilder<Rect?>(
                  tween: RectTween(end: lock?.box ?? guide),
                  duration: Duration(milliseconds: lock == null ? 260 : 160),
                  curve: Curves.easeOutCubic,
                  builder: (context, box, _) {
                    final rect = box ?? guide;
                    return Positioned.fromRect(
                      rect: rect,
                      child: _LockPulse(
                        active: lock != null && !lock.found,
                        builder: (pulse) => CustomPaint(
                          painter: MealGuideFramePainter(
                            cornerColor: Color.lerp(
                              Colors.white,
                              _lockColor,
                              locked,
                            )!,
                            lineColor: Color.lerp(
                              Colors.white.withValues(alpha: 0.35),
                              _lockColor.withValues(alpha: 0.7),
                              locked,
                            )!,
                            fillColor: _lockColor.withValues(
                              alpha: locked * (0.10 + 0.10 * pulse),
                            ),
                            strokeWidth: 4.0,
                            cornerLength: 34.0 - 12 * locked,
                            borderRadius: 26.0 - 12 * locked,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              // 2. PERFECTLY CENTERED INSTRUCTION TEXT BELOW BOX
              Positioned(
                top: guide.bottom + 18.0,
                left: 20.0,
                right: 20.0,
                child: Center(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    transitionBuilder: (child, animation) => FadeTransition(
                      opacity: animation,
                      child: ScaleTransition(
                        scale: Tween(begin: 0.94, end: 1.0).animate(animation),
                        child: child,
                      ),
                    ),
                    child: lock == null
                        ? _GuidePlate(
                            key: const ValueKey('guide'),
                            child: Text(
                              guideText,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                height: 1.35,
                              ),
                            ),
                          )
                        : _GuidePlate(
                            key: ValueKey('lock-${lock.code}-${lock.found}'),
                            child: _LockStatus(lock: lock),
                          ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// A flat plate keeps the text readable over any camera image without a
/// drop shadow.
class _GuidePlate extends StatelessWidget {
  final Widget child;

  const _GuidePlate({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: child,
      ),
    );
  }
}

class _LockStatus extends StatelessWidget {
  final GuideLock lock;

  const _LockStatus({required this.lock});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox.square(
          dimension: 18,
          child: lock.found
              ? TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.3, end: 1),
                  duration: const Duration(milliseconds: 320),
                  curve: Curves.easeOutBack,
                  builder: (context, scale, child) =>
                      Transform.scale(scale: scale, child: child),
                  child: const Icon(
                    Icons.check_circle_rounded,
                    size: 18,
                    color: MealGuideOverlay._lockColor,
                  ),
                )
              : const CircularProgressIndicator(
                  strokeWidth: 2.2,
                  color: MealGuideOverlay._lockColor,
                ),
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                lock.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                ),
              ),
              Text(
                lock.code,
                maxLines: 1,
                style: AppTypography.number(
                  size: 12,
                  weight: FontWeight.w400,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Breathes 0 → 1 → 0 while [active], so a lookup in progress reads as
/// working; stands still at 0 otherwise.
class _LockPulse extends StatefulWidget {
  final bool active;
  final Widget Function(double pulse) builder;

  const _LockPulse({required this.active, required this.builder});

  @override
  State<_LockPulse> createState() => _LockPulseState();
}

class _LockPulseState extends State<_LockPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  );

  @override
  void initState() {
    super.initState();
    if (widget.active) _controller.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(_LockPulse old) {
    super.didUpdateWidget(old);
    if (widget.active && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!widget.active && _controller.isAnimating) {
      _controller.animateTo(0, duration: const Duration(milliseconds: 150));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) =>
          widget.builder(Curves.easeInOut.transform(_controller.value)),
    );
  }
}
