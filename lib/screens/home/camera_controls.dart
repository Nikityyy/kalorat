import 'package:flutter/material.dart';
import '../../extensions/l10n_extension.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../theme/app_typography.dart';
import '../../utils/haptics.dart';
import '../../widgets/common/mono_digits.dart';

/// What is left of today's calories, at the top of the camera: the number
/// that decides what goes on the plate. Five quick taps show camera layout
/// measurements; a long press would drift into the tab swipe, so it is taps.
class CameraLogo extends StatelessWidget {
  final VoidCallback onTap;

  const CameraLogo({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final user = provider.user;
    final l10n = context.l10n;
    final String label;
    if (user == null) {
      label = l10n.appTitle;
    } else {
      final left =
          user.dailyCalorieTarget - (provider.getTodayStats()['calories'] ?? 0);
      label = left >= 0
          ? l10n.kcalLeftToday(left.round())
          : l10n.kcalOverToday((-left).round());
    }
    return Positioned(
      top: MediaQuery.of(context).padding.top + 20,
      left: 84,
      right: 84,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: onTap,
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(AppTheme.borderRadius),
            ),
            child: MonoDigits(
              label,
              maxLines: 1,
              style: AppTypography.secondary.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Round 52px button over the camera preview (switch camera, torch).
class _CameraCircleButton extends StatelessWidget {
  final String tooltip;
  final IconData icon;
  final bool enabled;
  final bool active;
  final VoidCallback onTap;
  final double? iconSize;

  const _CameraCircleButton({
    required this.tooltip,
    required this.icon,
    required this.enabled,
    required this.onTap,
    this.active = false,
    this.iconSize,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 160),
          opacity: enabled ? 1 : 0.45,
          child: Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: active
                  ? AppColors.styrianForest
                  : Colors.black.withValues(alpha: 0.45),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.75),
                width: 1,
              ),
            ),
            child: Icon(icon, color: Colors.white, size: iconSize),
          ),
        ),
      ),
    );
  }
}

class CameraSwitchButton extends StatelessWidget {
  final bool enabled;
  final VoidCallback onTap;

  const CameraSwitchButton({
    super.key,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 16,
      left: 20,
      child: _CameraCircleButton(
        tooltip: context.l10n.switchCamera,
        icon: Icons.cameraswitch_outlined,
        enabled: enabled,
        onTap: onTap,
      ),
    );
  }
}

class CameraTorchButton extends StatelessWidget {
  final bool available;
  final bool isOn;
  final VoidCallback onTap;

  const CameraTorchButton({
    super.key,
    required this.available,
    required this.isOn,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Positioned(
      top: MediaQuery.of(context).padding.top + 16,
      right: 20,
      child: _CameraCircleButton(
        tooltip: available ? l10n.flash : l10n.flashUnavailable,
        icon: isOn ? Icons.flash_on : Icons.flash_off,
        enabled: available,
        active: isOn,
        iconSize: 24,
        onTap: onTap,
      ),
    );
  }
}

/// Leaves the camera and goes back to the photo review.
class BackToSelectionButton extends StatelessWidget {
  final VoidCallback onTap;

  const BackToSelectionButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 80,
      left: 20,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(AppTheme.borderRadius),
          ),
          child: Row(
            children: [
              Icon(Icons.arrow_back, color: Colors.white, size: 16),
              const SizedBox(width: 8),
              Text(
                context.l10n.backToSelection,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Gallery, shutter and, on the right, the stack of taken photos or, before
/// the first photo, the quick log button.
class CameraBottomBar extends StatelessWidget {
  final int photoCount;
  final ImageProvider? lastPhoto;
  final bool isCapturing;
  final VoidCallback onGallery;
  final VoidCallback onCapture;
  final VoidCallback onReview;
  final VoidCallback onQuickLog;

  const CameraBottomBar({
    super.key,
    required this.photoCount,
    required this.lastPhoto,
    required this.isCapturing,
    required this.onGallery,
    required this.onCapture,
    required this.onReview,
    required this.onQuickLog,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final lastPhoto = this.lastPhoto;

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).padding.bottom + 24,
          top: 40,
        ),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0x00000000), Color(0x99000000)],
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Left: Gallery
            Positioned(
              left: 40,
              child: Semantics(
                button: true,
                label: l10n.gallery,
                child: GestureDetector(
                  onTap: () {
                    Haptics.tick();
                    onGallery();
                  },
                  child: _SideButton(
                    icon: Icons.photo_library,
                    label: l10n.gallery,
                  ),
                ),
              ),
            ),

            // Center: Capture
            Semantics(
              button: true,
              label: l10n.takePhoto,
              child: GestureDetector(
                onTap: () {
                  Haptics.confirm();
                  onCapture();
                },
                child: Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 4),
                  ),
                  child: Center(
                    child: Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: isCapturing
                          ? Center(
                              child: CircularProgressIndicator(
                                color: AppColors.styrianForest,
                              ),
                            )
                          : null,
                    ),
                  ),
                ),
              ),
            ),

            // Right: log without a photo until there is a photo to review
            if (lastPhoto == null)
              Positioned(
                right: 40,
                child: Semantics(
                  button: true,
                  label: l10n.quickLogTitle,
                  child: GestureDetector(
                    onTap: () {
                      Haptics.tick();
                      onQuickLog();
                    },
                    child: _SideButton(
                      icon: Icons.edit_note,
                      label: l10n.quickLogShort,
                    ),
                  ),
                ),
              )
            else
              Positioned(
                right: 40,
                child: GestureDetector(
                  onTap: onReview,
                  child: Stack(
                    alignment: Alignment.topRight,
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white, width: 2),
                          image: DecorationImage(
                            image: lastPhoto,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppColors.styrianForestColor,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '$photoCount',
                          style: AppTypography.number(
                            size: 13,
                            weight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// A square 12px-radius button with its label under it, beside the shutter.
class _SideButton extends StatelessWidget {
  final IconData icon;
  final String label;

  const _SideButton({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(AppTheme.borderRadius),
            border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
          ),
          child: Icon(icon, color: Colors.white, size: 26),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: AppTypography.meta.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
