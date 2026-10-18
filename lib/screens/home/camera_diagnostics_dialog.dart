import 'package:flutter/material.dart';
import '../../extensions/l10n_extension.dart';
import '../../utils/camera_diagnostics.dart';
import '../../utils/platform_utils.dart';

/// Shows camera layout measurements, with the switch for the canvas preview
/// (a different way to paint the camera that avoids a Safari layout bug).
void showCameraDiagnosticsDialog(BuildContext context, List<String> lines) {
  showDialog<void>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setDialogState) => AlertDialog(
        title: const Text('Camera diagnostics'),
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
                setCameraCanvasPreview(!cameraCanvasPreviewEnabled());
                setDialogState(() {});
              },
              child: Text(
                cameraCanvasPreviewEnabled()
                    ? 'Canvas preview: on'
                    : 'Canvas preview: off',
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
