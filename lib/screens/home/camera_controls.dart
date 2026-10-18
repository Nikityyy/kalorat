import 'package:flutter/material.dart';
import '../../extensions/l10n_extension.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../utils/haptics.dart';

/// The text logo at the top of the camera. Five quick taps show camera layout
/// measurements; a long press would drift into the tab swipe, so it is taps.
class CameraLogo extends StatelessWidget {
  final VoidCallback onTap;

  const CameraLogo({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 16,
      left: 80,
      right: 80,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: onTap,
        child: SizedBox(
          height: 52,
          child: Center(
            child: Image.asset(
              'assets/kalorat-textlogo.webp',
              color: Colors.white,
              colorBlendMode: BlendMode.srcIn,
              height: 26,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => const Text(
                'kalorat',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
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
                color: AppColors.pebble.withValues(alpha: 0.75),
                width: 1,
              ),
            ),
            child: Icon(icon, color: AppColors.pebble, size: iconSize),
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
              const Icon(Icons.arrow_back, color: AppColors.pebble, size: 16),
              const SizedBox(width: 8),
              Text(
                context.l10n.backToSelection,
                style: const TextStyle(
                  color: AppColors.pebble,
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
        decoration: const BoxDecoration(color: Colors.black45),
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
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.pebble.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.photo_library_outlined,
                      color: AppColors.pebble,
                      size: 28,
                    ),
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
                    border: Border.all(color: AppColors.pebble, width: 4),
                  ),
                  child: Center(
                    child: Container(
                      width: 70,
                      height: 70,
                      decoration: const BoxDecoration(
                        color: AppColors.pebble,
                        shape: BoxShape.circle,
                      ),
                      child: isCapturing
                          ? const Center(
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
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.pebble.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.edit_note_outlined,
                        color: AppColors.pebble,
                        size: 28,
                      ),
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
                          border: Border.all(color: AppColors.pebble, width: 2),
                          image: DecorationImage(
                            image: lastPhoto,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: AppColors.styrianForest,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '$photoCount',
                          style: const TextStyle(
                            color: AppColors.pebble,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
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
