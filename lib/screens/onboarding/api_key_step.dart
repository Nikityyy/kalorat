import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../theme/app_typography.dart';
import '../../theme/app_colors.dart';
import '../../widgets/inputs/action_button.dart';
import '../../services/services.dart';

class ApiKeyStep extends StatefulWidget {
  final Function(String) onNext;
  final String language;

  const ApiKeyStep({super.key, required this.onNext, required this.language});

  @override
  State<ApiKeyStep> createState() => _ApiKeyStepState();
}

class _ApiKeyStepState extends State<ApiKeyStep> {
  final TextEditingController _controller = TextEditingController();
  bool _isValidating = false;
  String? _errorMessage;

  Future<void> _validateAndProceed() async {
    final key = _controller.text.trim();
    if (key.isEmpty) {
      setState(
        () => _errorMessage = widget.language == 'de'
            ? 'Bitte gib einen API-Key ein'
            : 'Please enter an API Key',
      );
      return;
    }

    setState(() {
      _isValidating = true;
      _errorMessage = null;
    });

    final isValid = await GeminiService(apiKey: key).validateApiKey(key);

    if (mounted) {
      setState(() => _isValidating = false);
      if (isValid) {
        widget.onNext(key);
      } else {
        setState(
          () => _errorMessage = widget.language == 'de'
              ? 'Ungültiger API-Key. Bitte überprüfe deine Eingabe.'
              : 'Invalid API Key. Please check your input.',
        );
      }
    }
  }

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
            isDe ? 'AI Konfigurieren' : 'Configure AI',
            style: AppTypography.displayMedium,
          ),
          const SizedBox(height: 16),

          RichText(
            text: TextSpan(
              style: AppTypography.bodyMedium,
              children: [
                TextSpan(text: isDe ? 'Gehe zu ' : 'Go to '),
                TextSpan(
                  text: 'ai.dev/api-keys',
                  style: const TextStyle(
                    color: AppColors.shamrock,
                    fontWeight: FontWeight.bold,
                    decoration: TextDecoration.underline,
                  ),
                  recognizer: TapGestureRecognizer()
                    ..onTap = () => launchUrl(
                      Uri.parse('https://aistudio.google.com/app/apikey'),
                    ),
                ),
                TextSpan(
                  text: isDe
                      ? ' und erstelle einen kostenlosen Key. Kopiere ihn, füge ihn hier ein und tracke deine Kalorien.'
                      : ' and create a free key. Copy it, paste it here, and start tracking.',
                ),
              ],
            ),
          ),

          const SizedBox(height: 48),

          TextField(
            controller: _controller,
            style: AppTypography.displayMedium.copyWith(fontSize: 18),
            obscureText: true,
            decoration: InputDecoration(
              hintText: 'API Key',
              hintStyle: AppTypography.displayMedium.copyWith(
                fontSize: 18,
                color: AppColors.carbonBlack.withValues(alpha: 0.3),
              ),
              errorText: _errorMessage,
              border: UnderlineInputBorder(
                borderSide: BorderSide(color: AppColors.celadon, width: 2),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: AppColors.shamrock, width: 2),
              ),
            ),
          ),

          const Spacer(),
          ActionButton(
            text: isDe ? 'Validieren & Weiter' : 'Validate & Continue',
            isLoading: _isValidating,
            onPressed: _validateAndProceed,
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
