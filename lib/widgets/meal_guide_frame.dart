import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Painter for the meal framing guide square box with 4 white rounded corner brackets.
class MealGuideFramePainter extends CustomPainter {
  final Color cornerColor;
  final Color lineColor;
  final double strokeWidth;
  final double cornerLength;
  final double borderRadius;

  MealGuideFramePainter({
    this.cornerColor = Colors.white,
    this.lineColor = const Color(0x59FFFFFF),
    this.strokeWidth = 4.0,
    this.cornerLength = 34.0,
    this.borderRadius = 26.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final RRect fullRRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(borderRadius),
    );

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

    final double r = borderRadius;
    final double cl = cornerLength;

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
      ..arcToPoint(Offset(size.width - r, size.height), radius: Radius.circular(r))
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
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Overlay widget displaying the square meal framing guide box and localized instruction text below it.
/// Guarantees 100% vertical and horizontal centering across all screen sizes.
class MealGuideOverlay extends StatelessWidget {
  final String guideText;

  const MealGuideOverlay({
    super.key,
    required this.guideText,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double screenWidth = constraints.maxWidth;
          final double screenHeight = constraints.maxHeight;

          final double topInset = MediaQuery.of(context).padding.top;
          final double bottomInset = MediaQuery.of(context).padding.bottom;

          // Camera viewport bounds (between top header tools and bottom shutter bar)
          final double topBound = topInset + 68.0;
          final double bottomBound = screenHeight - (bottomInset + 130.0);
          final double availableHeight = math.max(100.0, bottomBound - topBound);

          // Square box size responsive to width and available height
          final double boxSize = math.min(
            screenWidth * 0.74,
            math.max(180.0, availableHeight * 0.62),
          );

          // Exact 1:1 vertical and horizontal centering in open camera viewport
          final double boxTop = topBound + (availableHeight - boxSize) / 2.0;
          final double boxLeft = (screenWidth - boxSize) / 2.0;

          return Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.topCenter,
            children: [
              // 1. PERFECTLY CENTERED SQUARE BOX
              Positioned(
                top: boxTop,
                left: boxLeft,
                width: boxSize,
                height: boxSize,
                child: CustomPaint(
                  painter: MealGuideFramePainter(
                    cornerColor: Colors.white,
                    lineColor: Colors.white.withValues(alpha: 0.35),
                    strokeWidth: 4.0,
                    cornerLength: 34.0,
                    borderRadius: 26.0,
                  ),
                ),
              ),

              // 2. PERFECTLY CENTERED INSTRUCTION TEXT BELOW BOX
              Positioned(
                top: boxTop + boxSize + 18.0,
                left: 20.0,
                right: 20.0,
                child: Text(
                  guideText,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                    shadows: [
                      Shadow(
                        blurRadius: 8,
                        color: Colors.black87,
                        offset: Offset(0, 1),
                      ),
                    ],
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
