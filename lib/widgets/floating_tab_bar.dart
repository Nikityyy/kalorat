import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../theme/app_typography.dart';

/// The app's three tabs on a bar that floats above the page: the canvas at
/// 94% with a 1px border. Over the camera it turns dark so the feed shows
/// through. There is no backdrop blur: it costs a full-screen pass per frame
/// on the web build.
class FloatingTabBar extends StatelessWidget {
  final int currentIndex;
  final bool onCamera;
  final List<String> labels;
  final ValueChanged<int> onTap;

  const FloatingTabBar({
    super.key,
    required this.currentIndex,
    required this.onCamera,
    required this.labels,
    required this.onTap,
  });

  static const height = 62.0;

  static const _icons = [Icons.landscape, Icons.photo_camera, Icons.bar_chart];

  @override
  Widget build(BuildContext context) {
    final background = onCamera
        ? Colors.black.withValues(alpha: 0.55)
        : AppColors.canvas;
    final border = onCamera
        ? Colors.white.withValues(alpha: 0.14)
        : AppColors.border;
    final active = onCamera ? Colors.white : AppColors.primary;
    final inactive = onCamera
        ? Colors.white.withValues(alpha: 0.72)
        : AppColors.ink3;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      height: height,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++)
            Expanded(
              child: Semantics(
                button: true,
                selected: i == currentIndex,
                label: labels[i],
                excludeSemantics: true,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onTap(i),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(end: i == currentIndex ? 1 : 0),
                    duration: const Duration(milliseconds: 200),
                    builder: (context, t, _) {
                      final color = Color.lerp(inactive, active, t)!;
                      return Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Transform.scale(
                            scale: 1 + 0.06 * t,
                            child: Icon(_icons[i], color: color, size: 26),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            labels[i],
                            style: AppTypography.meta.copyWith(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: color,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
