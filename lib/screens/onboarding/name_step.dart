import 'package:flutter/material.dart';
import '../../theme/app_typography.dart';
import '../../theme/app_colors.dart';
import '../../extensions/l10n_extension.dart';
import '../../widgets/inputs/action_button.dart';

class NameStep extends StatefulWidget {
  final Function(String) onNext;
  final String language;
  final String? initialValue;

  const NameStep({
    super.key,
    required this.onNext,
    required this.language,
    this.initialValue,
  });

  @override
  State<NameStep> createState() => _NameStepState();
}

class _NameStepState extends State<NameStep> {
  late TextEditingController _controller;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          Text(l10n.onboardingName, style: AppTypography.displayMedium),
          const SizedBox(height: 8),
          Text(l10n.nameSubtitle, style: AppTypography.bodyMedium),
          const SizedBox(height: 48),

          TextField(
            controller: _controller,
            style: AppTypography.displayMedium,
            onChanged: (_) {
              if (_errorMessage != null) {
                setState(() => _errorMessage = null);
              }
            },
            decoration: InputDecoration(
              hintText: l10n.onboardingNameHint,
              hintStyle: AppTypography.displayMedium.copyWith(
                color: AppColors.slate.withValues(alpha: 0.3),
              ),
              errorText: _errorMessage,
              border: UnderlineInputBorder(
                borderSide: BorderSide(color: AppColors.pebble, width: 2),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: AppColors.primary, width: 2),
              ),
            ),
          ),

          const Spacer(),
          ActionButton(
            text: l10n.continueButton,
            onPressed: () {
              final name = _controller.text.trim();
              if (name.isEmpty) {
                setState(() => _errorMessage = l10n.nameValidationError);
                return;
              }
              widget.onNext(name);
            },
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
