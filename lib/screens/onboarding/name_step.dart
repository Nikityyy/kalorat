import 'package:flutter/material.dart';
import '../../theme/app_typography.dart';
import '../../theme/app_colors.dart';
import '../../widgets/inputs/action_button.dart';

class NameStep extends StatefulWidget {
  final Function(String) onNext;
  final String language;

  const NameStep({super.key, required this.onNext, required this.language});

  @override
  State<NameStep> createState() => _NameStepState();
}

class _NameStepState extends State<NameStep> {
  final TextEditingController _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final isDe = widget.language == 'de';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          Text(
            isDe ? 'Wie heißt du?' : 'What\'s your name?',
            style: AppTypography.displayMedium,
          ),
          const SizedBox(height: 8),
          Text(
            isDe
                ? 'Wir möchten dich persönlich ansprechen.'
                : 'We\'d like to know how to call you.',
            style: AppTypography.bodyMedium,
          ),
          const SizedBox(height: 48),

          TextField(
            controller: _controller,
            style: AppTypography.displayMedium,
            decoration: InputDecoration(
              hintText: isDe ? 'Dein Name' : 'Your Name',
              hintStyle: AppTypography.displayMedium.copyWith(
                color: AppColors.slate.withValues(alpha: 0.3),
              ),
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
            text: isDe ? 'Weiter' : 'Continue',
            onPressed: () {
              if (_controller.text.isNotEmpty) {
                widget.onNext(_controller.text);
              }
            },
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
