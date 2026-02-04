import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';

class RulerPicker extends StatefulWidget {
  final double minValue;
  final double maxValue;
  final double initialValue;
  final Function(double) onValueChanged;
  final String unit;
  final bool isHorizontal;

  const RulerPicker({
    super.key,
    required this.minValue,
    required this.maxValue,
    required this.initialValue,
    required this.onValueChanged,
    required this.unit,
    this.isHorizontal = true,
  });

  @override
  State<RulerPicker> createState() => _RulerPickerState();
}

class _RulerPickerState extends State<RulerPicker> {
  late FixedExtentScrollController _controller;
  late double _currentValue;

  @override
  void initState() {
    super.initState();
    _currentValue = widget.initialValue;
    // initialValue (e.g. 70.5) - minValue (30.0) = 40.5
    // 40.5 * 10 = 405 steps
    _controller = FixedExtentScrollController(
      initialItem: ((widget.initialValue - widget.minValue) * 10).round(),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 1 tick = 0.1 unit
    final int totalSteps = ((widget.maxValue - widget.minValue) * 10).round();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Value Display
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              _currentValue.toStringAsFixed(1).replaceAll('.', ','),
              style: AppTypography.bespokeNumber.copyWith(
                fontSize: 64,
                color: AppColors.shamrock,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              widget.unit,
              style: AppTypography.titleLarge.copyWith(
                color: AppColors.carbonBlack.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        // Ruler Area
        SizedBox(
          height: 100,
          width: double.infinity,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // The Center Indicator
              Container(
                width: 4,
                height: 60,
                decoration: BoxDecoration(
                  color: AppColors.shamrock,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // The Scroller
              NotificationListener<ScrollNotification>(
                onNotification: (notification) {
                  if (notification is ScrollUpdateNotification) {
                    HapticFeedback.selectionClick();
                  }
                  return false;
                },
                child: RotatedBox(
                  quarterTurns: widget.isHorizontal ? -1 : 0,
                  child: ListWheelScrollView.useDelegate(
                    controller: _controller,
                    itemExtent: 10, // Denser ticks
                    perspective: 0.0001,
                    diameterRatio: 100,
                    physics: const FixedExtentScrollPhysics(),
                    onSelectedItemChanged: (index) {
                      final val = widget.minValue + (index / 10.0);
                      // Snap to 1 decimal place to avoid floating point errors
                      final newValue = double.parse(val.toStringAsFixed(1));

                      if (newValue != _currentValue) {
                        setState(() => _currentValue = newValue);
                        widget.onValueChanged(newValue);
                      }
                    },
                    childDelegate: ListWheelChildBuilderDelegate(
                      childCount: totalSteps + 1,
                      builder: (context, index) {
                        // index 0 = minValue
                        // index 10 = minValue + 1.0
                        final isMajor = index % 10 == 0;
                        final isMedium = index % 5 == 0;

                        return RotatedBox(
                          quarterTurns: widget.isHorizontal ? 1 : 0,
                          child: Center(
                            child: Container(
                              width: isMajor ? 3 : 2,
                              height: isMajor ? 50 : (isMedium ? 35 : 20),
                              color: AppColors.carbonBlack.withValues(
                                alpha: isMajor ? 0.8 : 0.4,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
