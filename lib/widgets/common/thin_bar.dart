import 'package:flutter/widgets.dart';

import '../../theme/app_colors.dart';

/// A 3px bar filled to [share] in ink (or [color]) on a rule-coloured track.
class ThinBar extends StatelessWidget {
  final double share;
  final Color? color;

  const ThinBar({super.key, required this.share, this.color});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(2),
      child: Container(
        height: 3,
        width: double.infinity,
        alignment: AlignmentDirectional.centerStart,
        color: AppColors.border,
        child: FractionallySizedBox(
          widthFactor: share.clamp(0.0, 1.0),
          heightFactor: 1,
          child: ColoredBox(color: color ?? AppColors.text),
        ),
      ),
    );
  }
}
