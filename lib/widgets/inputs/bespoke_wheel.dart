import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_colors.dart';
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
      height: 280, // Slightly taller
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Selection Highlight
          Container(
            height: 70, // Matches itemExtent
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.shamrock.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              if (notification is ScrollUpdateNotification) {
                // HapticFeedback.selectionClick();
              }
              return false;
            },
            child: ListWheelScrollView.useDelegate(
              controller: _controller,
              itemExtent: 70, // Increased from 60
              perspective: 0.003, // Flatter
              diameterRatio: 1.8, // Better curve
              useMagnifier: true,
              magnification:
                  1.3, // Slightly less aggressive zoom to stay within itemExtent
              overAndUnderCenterOpacity: 0.2, // More focus on center
              physics: const FixedExtentScrollPhysics(),
              onSelectedItemChanged: (index) {
                HapticFeedback.lightImpact();
                widget.onValueChanged(index);
              },
              childDelegate: ListWheelChildBuilderDelegate(
                childCount: widget.options.length,
                builder: (context, index) {
                  // We can't know the exact selected index in builder easily without tracking scroll position continuously,
                  // but ListWheelScrollView handles opacity/size with 'magnification'. The user said "seeing what age is selected is quite hard".
                  // I will increase magnification and opacity contrast.

                  return Center(
                    child: Text(
                      widget.options[index],
                      style: AppTypography.displayMedium.copyWith(
                        color: AppColors.carbonBlack,
                        fontWeight: FontWeight.w900, // Bolder
                        fontSize: 32, // Larger base size
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
