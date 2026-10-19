import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../theme/app_typography.dart';

enum AppToastKind { info, success, error }

/// A short message that never blocks: it floats at the top, covers no
/// controls (pass [top] to keep it clear of a screen's own top buttons),
/// disappears by itself, and goes away on a tap or an upward swipe. Only one
/// is shown at a time. It lives in the root overlay, so it survives navigation.
class AppToast {
  const AppToast._();

  static OverlayEntry? _entry;
  static Timer? _timer;

  static void show(
    BuildContext context,
    String message, {
    AppToastKind kind = AppToastKind.info,
    Duration? duration,
    String? actionLabel,
    VoidCallback? onAction,
    double? top,
  }) {
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null || message.trim().isEmpty) return;
    dismiss();

    final topOffset = top ?? MediaQuery.paddingOf(context).top + 12;
    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _ToastView(
        message: message,
        kind: kind,
        top: topOffset,
        actionLabel: actionLabel,
        onAction: onAction,
        onDismiss: () => _remove(entry),
      ),
    );
    _entry = entry;
    overlay.insert(entry);
    _timer = Timer(
      duration ??
          (actionLabel == null
              ? const Duration(seconds: 3)
              : const Duration(seconds: 8)),
      () => _remove(entry),
    );
  }

  static void dismiss() {
    final entry = _entry;
    if (entry != null) _remove(entry);
  }

  static void _remove(OverlayEntry entry) {
    if (_entry == entry) {
      _timer?.cancel();
      _timer = null;
      _entry = null;
    }
    if (entry.mounted) entry.remove();
  }
}

class _ToastView extends StatefulWidget {
  final String message;
  final AppToastKind kind;
  final double top;
  final String? actionLabel;
  final VoidCallback? onAction;
  final VoidCallback onDismiss;

  const _ToastView({
    required this.message,
    required this.kind,
    required this.top,
    required this.actionLabel,
    required this.onAction,
    required this.onDismiss,
  });

  @override
  State<_ToastView> createState() => _ToastViewState();
}

class _ToastViewState extends State<_ToastView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
  )..forward();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color get _accent => switch (widget.kind) {
    AppToastKind.success => AppColors.primary,
    AppToastKind.error => AppColors.signalRed,
    AppToastKind.info => AppColors.border,
  };

  IconData? get _icon => switch (widget.kind) {
    AppToastKind.success => Icons.check_circle,
    AppToastKind.error => Icons.error,
    AppToastKind.info => null,
  };

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final curved = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    final icon = _icon;

    Widget toast = Material(
      color: AppColors.canvas,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        side: BorderSide(color: _accent, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 18, color: _accent),
              const SizedBox(width: 10),
            ],
            Flexible(
              child: Text(
                widget.message,
                style: TextStyle(
                  fontFamily: AppTypography.outfit,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.text,
                  height: 1.3,
                ),
              ),
            ),
            if (widget.actionLabel != null) ...[
              const SizedBox(width: 12),
              InkWell(
                onTap: () {
                  widget.onDismiss();
                  widget.onAction?.call();
                },
                borderRadius: BorderRadius.circular(8),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 44),
                  child: Center(
                    widthFactor: 1,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Text(
                        widget.actionLabel!,
                        style: TextStyle(
                          fontFamily: AppTypography.outfit,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );

    toast = GestureDetector(
      onTap: widget.onDismiss,
      onVerticalDragEnd: (details) {
        if ((details.primaryVelocity ?? 0) < 0) widget.onDismiss();
      },
      child: toast,
    );
    toast = Semantics(liveRegion: true, container: true, child: toast);
    toast = reduceMotion
        ? toast
        : FadeTransition(
            opacity: curved,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, -0.4),
                end: Offset.zero,
              ).animate(curved),
              child: toast,
            ),
          );

    return Positioned(
      top: widget.top,
      left: 16,
      right: 16,
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: toast,
        ),
      ),
    );
  }
}
