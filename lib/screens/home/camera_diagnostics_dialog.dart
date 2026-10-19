import 'dart:convert';

import 'package:flutter/material.dart';
import '../../extensions/l10n_extension.dart';
import '../../utils/camera_diagnostics.dart';
import '../../utils/haptics.dart';
import '../../utils/platform_utils.dart';

/// Shows camera layout measurements, with the switch for the canvas preview
/// (a different way to paint the camera that avoids a Safari layout bug).
void showCameraDiagnosticsDialog(BuildContext context, List<String> lines) {
  showDialog<void>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setDialogState) => AlertDialog(
        title: Text(context.l10n.cameraDiagnosticsTitle),
        content: SingleChildScrollView(
          child: SelectableText(
            lines.join('\n'),
            style: const TextStyle(fontFamily: 'JetBrains Mono', fontSize: 10),
          ),
        ),
        actions: [
          if (PlatformUtils.isWeb)
            TextButton(
              onPressed: () {
                final l10n = context.l10n;
                Navigator.pop(ctx);
                Haptics.openTest(
                  jsonEncode({
                    'title': l10n.hapticsTest,
                    'intro': l10n.hapticsTestIntro,
                    'native': l10n.hapticsTestNative,
                    'felt': l10n.hapticsTestFelt,
                    'close': l10n.close,
                  }),
                );
              },
              child: Text(context.l10n.hapticsTest),
            ),
          if (PlatformUtils.isWeb)
            TextButton(
              onPressed: () {
                setCameraCanvasPreview(!cameraCanvasPreviewEnabled());
                setDialogState(() {});
              },
              child: Text(
                cameraCanvasPreviewEnabled()
                    ? context.l10n.cameraCanvasPreviewOn
                    : context.l10n.cameraCanvasPreviewOff,
              ),
            ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(context.l10n.close),
          ),
        ],
      ),
    ),
  );
}
