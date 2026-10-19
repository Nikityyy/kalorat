import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../../extensions/l10n_extension.dart';
import '../../theme/app_colors.dart';

/// Dialogs and pickers. They are Material on every platform: a web app
/// cannot show the system's own iOS alerts and pickers, and drawn copies of
/// them never match the iOS version on the phone.
/// The magnifier for text fields. On the web the browser shows its own
/// handles and loupe over Flutter's hidden input, so Flutter's loupe would
/// draw the selected text a second time.
const TextMagnifierConfiguration? fieldMagnifier = kIsWeb
    ? TextMagnifierConfiguration.disabled
    : null;

/// Asks a yes/no question. True only when [confirmLabel] was chosen.
Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  String? message,
  required String confirmLabel,
  bool destructive = false,
}) async {
  final cancel = context.l10n.cancel;
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: message == null ? null : Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(cancel),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(
            confirmLabel,
            style: destructive ? TextStyle(color: AppColors.negative) : null,
          ),
        ),
      ],
    ),
  );
  return result == true;
}

/// One text field of [showPromptDialog].
class PromptField {
  final String initial;
  final String? label;
  final String? suffix;
  final TextInputType keyboardType;

  const PromptField({
    this.initial = '',
    this.label,
    this.suffix,
    this.keyboardType = TextInputType.text,
  });

  static const number = TextInputType.numberWithOptions(decimal: true);
}

/// Asks for one or more values, like an iOS alert with text fields or a
/// Material dialog. Returns the texts in field order, or null when cancelled.
Future<List<String>?> showPromptDialog(
  BuildContext context, {
  required String title,
  required List<PromptField> fields,
  String? saveLabel,
}) => showDialog<List<String>>(
  context: context,
  builder: (_) =>
      _PromptDialog(title: title, fields: fields, saveLabel: saveLabel),
);

class _PromptDialog extends StatefulWidget {
  final String title;
  final List<PromptField> fields;
  final String? saveLabel;

  const _PromptDialog({
    required this.title,
    required this.fields,
    this.saveLabel,
  });

  @override
  State<_PromptDialog> createState() => _PromptDialogState();
}

class _PromptDialogState extends State<_PromptDialog> {
  late final List<TextEditingController> controllers = [
    for (final f in widget.fields) TextEditingController(text: f.initial),
  ];

  List<String> values() => [for (final c in controllers) c.text.trim()];

  @override
  void dispose() {
    for (final c in controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final title = widget.title;
    final fields = widget.fields;
    final saveLabel = widget.saveLabel;
    void save() => Navigator.pop(context, values());
    return AlertDialog(
      title: Text(title),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < fields.length; i++) ...[
              if (i > 0) const SizedBox(height: 12),
              TextField(
                controller: controllers[i],
                magnifierConfiguration: fieldMagnifier,
                autofocus: i == 0,
                keyboardType: fields[i].keyboardType,
                textInputAction: i == fields.length - 1
                    ? TextInputAction.done
                    : TextInputAction.next,
                onSubmitted: i == fields.length - 1 ? (_) => save() : null,
                decoration: InputDecoration(
                  labelText: fields[i].label,
                  suffixText: fields[i].suffix,
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        TextButton(onPressed: save, child: Text(saveLabel ?? l10n.save)),
      ],
    );
  }
}

/// Picks a date, or a date and time with [withTime]: the calendar, then the
/// clock.
Future<DateTime?> pickDate(
  BuildContext context, {
  required DateTime initial,
  required DateTime first,
  required DateTime last,
  bool withTime = false,
}) async {
  final start = initial.isBefore(first)
      ? first
      : initial.isAfter(last)
      ? last
      : initial;
  final date = await showDatePicker(
    context: context,
    initialDate: start,
    firstDate: first,
    lastDate: last,
  );
  if (date == null || !withTime || !context.mounted) return date;
  final time = await showTimePicker(
    context: context,
    initialTime: TimeOfDay.fromDateTime(start),
  );
  if (time == null) return null;
  return DateTime(date.year, date.month, date.day, time.hour, time.minute);
}
