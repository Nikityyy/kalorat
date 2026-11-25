import 'package:flutter/widgets.dart';

import '../../theme/app_colors.dart';

/// A thin bar filled to [share] in ink (or [color]) on [trackColor].
class ThinBar extends StatelessWidget {
  final double share;
  final Color? color;
  final Color? trackColor;
  final double height;

  const ThinBar({
    super.key,
    required this.share,
    this.color,
    this.trackColor,
    this.height = 3,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: Container(
        height: height,
        width: double.infinity,
        alignment: AlignmentDirectional.centerStart,
        color: trackColor ?? AppColors.border,
        child: FractionallySizedBox(
          widthFactor: share.clamp(0.0, 1.0),
          heightFactor: 1,
          child: ColoredBox(color: color ?? AppColors.text),
        ),
      ),
    );
  }
}
