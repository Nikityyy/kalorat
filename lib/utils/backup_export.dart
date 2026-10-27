import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../extensions/l10n_extension.dart';
import '../providers/app_provider.dart';
import '../widgets/app_toast.dart';

/// Exports all data as a backup file and says what became of it: Settings
/// and the backup reminder on Today both use it.
Future<void> exportBackup(BuildContext context) async {
  final provider = context.read<AppProvider>();
  final l10n = context.l10n;
  final path = await provider.exportData();
  if (!context.mounted) return;
  if (path == null) {
    AppToast.show(context, l10n.backupFailed, kind: AppToastKind.error);
    return;
  }
  if (path.startsWith('web_')) {
    // Web: the browser share sheet or download took the file. Only a plain
    // download needs a confirmation.
    if (path == 'web_downloaded') {
      AppToast.show(context, l10n.downloadStarted, kind: AppToastKind.info);
    }
    return;
  }
  await SharePlus.instance.share(
    ShareParams(files: [XFile(path)], text: l10n.backupShareText),
  );
}
