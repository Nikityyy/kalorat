import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../extensions/l10n_extension.dart';
import '../../widgets/inputs/action_button.dart';
import '../../widgets/inputs/ruler_picker.dart';

double weightScaleFractionForPoint(Offset point, Size size) {
  final center = Offset(size.width / 2, size.height - 24);
  if (point.dy >= center.dy) return point.dx < center.dx ? 0 : 1;
  var angle = math.atan2(point.dy - center.dy, point.dx - center.dx);
  if (angle <= 0) angle += math.pi * 2;
  return ((angle - math.pi) / math.pi).clamp(0.0, 1.0).toDouble();
}

class MetricsStep extends StatefulWidget {
  final double initialHeight;
  final double initialWeight;
  final Function(double height, double weight) onNext;
  final String language;

  const MetricsStep({
    super.key,
    required this.initialHeight,
    required this.initialWeight,
    required this.onNext,
    required this.language,
  });

  @override
  State<MetricsStep> createState() => _MetricsStepState();
}

class _MetricsStepState extends State<MetricsStep> {
  late double _currentHeight;
  late double _currentWeight;

  @override
  void initState() {
    super.initState();
    _currentHeight = widget.initialHeight;
    _currentWeight = widget.initialWeight;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),
                Text(l10n.yourMeasurements, style: AppTypography.displayMedium),
                const SizedBox(height: 32),
                
                Text(l10n.height, style: AppTypography.labelLarge.copyWith(color: AppColors.slate)),
                const SizedBox(height: 16),
                SizedBox(
                  height: 220, // Increased height for ruler to fix overflow
                  child: RulerPicker(
                    minValue: 100,
                    maxValue: 250,
                    initialValue: _currentHeight,
                    unit: l10n.cm,
                    onValueChanged: (val) => _currentHeight = val,
                  ),
                ),
                
                const SizedBox(height: 48),
                Text(l10n.weight, style: AppTypography.labelLarge.copyWith(color: AppColors.slate)),
                const SizedBox(height: 16),
                WeightScalePicker(
                  minValue: 20,
                  maxValue: 200,
                  value: _currentWeight,
                  unit: l10n.kg,
                  onValueChanged: (value) => setState(() => _currentWeight = value),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
          SliverFillRemaining(
            hasScrollBody: false,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ActionButton(
                  text: l10n.continueButton,
                  onPressed: () => widget.onNext(_currentHeight, _currentWeight),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class WeightScalePicker extends StatelessWidget {
  final double minValue;
  final double maxValue;
  final double value;
  final String unit;
  final ValueChanged<double> onValueChanged;

  const WeightScalePicker({
    super.key,
    required this.minValue,
    required this.maxValue,
    required this.value,
    required this.unit,
    required this.onValueChanged,
  });

  void _setValue(double next) {
    final snapped = (next.clamp(minValue, maxValue) * 10).round() / 10;
    if (snapped == value) return;
    HapticFeedback.selectionClick();
    onValueChanged(snapped);
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      slider: true,
      value: '${value.toStringAsFixed(1)} $unit',
      increasedValue: '${(value + 0.1).clamp(minValue, maxValue).toStringAsFixed(1)} $unit',
      decreasedValue: '${(value - 0.1).clamp(minValue, maxValue).toStringAsFixed(1)} $unit',
      onIncrease: () => _setValue(value + 0.1),
      onDecrease: () => _setValue(value - 0.1),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          LayoutBuilder(
            builder: (context, constraints) => Listener(
              onPointerDown: (event) {
                final fraction = weightScaleFractionForPoint(
                  event.localPosition,
                  Size(constraints.maxWidth, 200),
                );
                _setValue(minValue + fraction * (maxValue - minValue));
              },
              onPointerMove: (event) {
                final fraction = weightScaleFractionForPoint(
                  event.localPosition,
                  Size(constraints.maxWidth, 200),
                );
                _setValue(minValue + fraction * (maxValue - minValue));
              },
              child: Container(
                color: Colors.transparent, // Ensures the entire area receives hit events
                height: 200,
                width: double.infinity,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Positioned.fill(
                      child: CustomPaint(
                        painter: ScalePainter(
                          fraction: (value - minValue) / (maxValue - minValue),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 24,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            value.toStringAsFixed(1),
                            style: AppTypography.heroNumber.copyWith(
                              fontSize: 48,
                              color: AppColors.styrianForest,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            unit,
                            style: AppTypography.titleLarge.copyWith(
                              color: AppColors.slate.withValues(alpha: 0.55),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton.filled(
                onPressed: () => _setValue(value - 0.1),
                icon: const Icon(Icons.remove),
              ),
              const SizedBox(width: 48),
              IconButton.filled(
                onPressed: () => _setValue(value + 0.1),
                icon: const Icon(Icons.add),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class ScalePainter extends CustomPainter {
  final double fraction;

  const ScalePainter({required this.fraction});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height - 24);
    final radius = math.min(size.width * 0.43, size.height - 42);
    final arc = Rect.fromCircle(center: center, radius: radius);
    final background = Paint()
      ..color = AppColors.borderGrey.withValues(alpha: 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;
    final active = Paint()
      ..color = AppColors.styrianForest
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(arc, math.pi, math.pi, false, background);
    canvas.drawArc(arc, math.pi, math.pi * fraction, false, active);

    final tickPaint = Paint()
      ..color = AppColors.slate.withValues(alpha: 0.55)
      ..strokeCap = StrokeCap.round;
    for (var index = 0; index <= 20; index++) {
      final angle = math.pi + math.pi * index / 20;
      final major = index % 5 == 0;
      tickPaint.strokeWidth = major ? 3 : 1.5;
      final outer = Offset(
        center.dx + math.cos(angle) * (radius - 12),
        center.dy + math.sin(angle) * (radius - 12),
      );
      final inner = Offset(
        center.dx + math.cos(angle) * (radius - (major ? 30 : 22)),
        center.dy + math.sin(angle) * (radius - (major ? 30 : 22)),
      );
      canvas.drawLine(inner, outer, tickPaint);
    }

    final needleAngle = math.pi + math.pi * fraction;
    final needleEnd = Offset(
      center.dx + math.cos(needleAngle) * (radius - 40),
      center.dy + math.sin(needleAngle) * (radius - 40),
    );
    canvas.drawLine(
      center,
      needleEnd,
      Paint()
        ..color = AppColors.slate
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(center, 8, Paint()..color = AppColors.styrianForest);
  }

  @override
  bool shouldRepaint(covariant ScalePainter oldDelegate) =>
      oldDelegate.fraction != fraction;
}
