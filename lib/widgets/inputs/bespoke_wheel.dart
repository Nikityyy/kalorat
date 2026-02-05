import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_typography.dart';

class BespokeWheelPicker extends StatefulWidget {
  final List<String> options;
  final int initialIndex;
  final Function(int) onValueChanged;

  const BespokeWheelPicker({
    super.key,
    required this.options,
    required this.initialIndex,
    required this.onValueChanged,
  });

  @override
  State<BespokeWheelPicker> createState() => _BespokeWheelPickerState();
}

class _BespokeWheelPickerState extends State<BespokeWheelPicker> {
  late FixedExtentScrollController _controller;

  @override
  void initState() {
    super.initState();
    _controller = FixedExtentScrollController(initialItem: widget.initialIndex);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 280,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Selection Highlight
          Container(
            height: 70,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.styrianForest.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppTheme.borderRadius),
              border: Border.all(color: AppColors.borderGrey, width: 1),
            ),
          ),
          NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              return false;
            },
            child: ListWheelScrollView.useDelegate(
              controller: _controller,
              itemExtent: 70,
              perspective: 0.003,
              diameterRatio: 1.8,
              useMagnifier: true,
              magnification: 1.3,
              overAndUnderCenterOpacity: 0.2,
              physics: const FixedExtentScrollPhysics(),
              onSelectedItemChanged: (index) {
                HapticFeedback.heavyImpact(); // Mechanical click feel
                widget.onValueChanged(index);
              },
              childDelegate: ListWheelChildBuilderDelegate(
                childCount: widget.options.length,
                builder: (context, index) {
                  return Center(
                    child: Text(
                      widget.options[index],
                      style: AppTypography.displayMedium.copyWith(
                        color: AppColors.frost,
                        fontWeight: FontWeight.w900,
                        fontSize: 32,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
