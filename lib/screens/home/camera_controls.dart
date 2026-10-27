import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';
import '../../extensions/l10n_extension.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_typography.dart';
import '../../utils/frame_luma.dart';
import '../../utils/haptics.dart';

/// The text logo at the top of the camera. Five quick taps show camera layout
/// measurements; a long press would drift into the tab swipe, so it is taps.
///
/// It is white over a dark picture and black over a bright one, following
/// [backdrop] (how bright the picture is behind it, null when unknown, which
/// keeps it white).
class CameraLogo extends StatefulWidget {
  final VoidCallback onTap;
  final ValueListenable<double?>? backdrop;

  const CameraLogo({super.key, required this.onTap, this.backdrop});

  /// The part of the preview the logo sits over, as fractions of the preview
  /// ([view] is its size, [top] the safe-area inset): the letters, not the
  /// empty space beside them.
  static Rect backdropRegion(Size view, double top) => Rect.fromLTRB(
    .5 - 72 / view.width,
    (top + 16 + 13) / view.height,
    .5 + 72 / view.width,
    (top + 16 + 39) / view.height,
  );

  @override
  State<CameraLogo> createState() => _CameraLogoState();
}

class _CameraLogoState extends State<CameraLogo> {
  final _tone = BackdropTone();
  bool _dark = false;

  @override
  void initState() {
    super.initState();
    widget.backdrop?.addListener(_read);
  }

  @override
  void didUpdateWidget(CameraLogo old) {
    super.didUpdateWidget(old);
    if (old.backdrop != widget.backdrop) {
      old.backdrop?.removeListener(_read);
      widget.backdrop?.addListener(_read);
    }
  }

  @override
  void dispose() {
    widget.backdrop?.removeListener(_read);
    super.dispose();
  }

  void _read() {
    final luma = widget.backdrop?.value;
    if (luma == null) {
      // No picture to judge: back to the plain white logo.
      _tone.reset();
      if (_dark) setState(() => _dark = false);
      return;
    }
    final dark = _tone.update(luma);
    if (dark != _dark) setState(() => _dark = dark);
  }

  @override
  Widget build(BuildContext context) {
    final color = _dark ? const Color(0xFF111513) : Colors.white;
    return Positioned(
      top: MediaQuery.of(context).padding.top + 16,
      left: 80,
      right: 80,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: widget.onTap,
        child: SizedBox(
          height: 52,
          child: Center(
            child: TweenAnimationBuilder<Color?>(
              tween: ColorTween(end: color),
              duration: const Duration(milliseconds: 320),
              curve: Curves.easeOutCubic,
              builder: (context, tint, _) => Image.asset(
                'assets/kalorat-textlogo.webp',
                color: tint,
                colorBlendMode: BlendMode.srcIn,
                height: 26,
                fit: BoxFit.contain,
                semanticLabel: context.l10n.appTitle,
                errorBuilder: (context, error, stackTrace) => Text(
                  context.l10n.appTitle,
                  style: AppTypography.secondary.copyWith(
                    color: tint,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
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
                  ? AppColors.primary
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
                // The button's own caption would be read a second time.
                excludeSemantics: true,
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
                                color: AppColors.primary,
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
                  excludeSemantics: true,
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
