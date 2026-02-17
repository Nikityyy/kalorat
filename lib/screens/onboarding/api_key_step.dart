import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../theme/app_typography.dart';
import '../../theme/app_colors.dart';
import '../../extensions/l10n_extension.dart';
import '../../widgets/inputs/action_button.dart';
import '../../services/services.dart';

class ApiKeyStep extends StatefulWidget {
  final Function(String) onNext;
  final String language;
  final String? initialValue;

  const ApiKeyStep({
    super.key,
    required this.onNext,
    required this.language,
    this.initialValue,
  });

  @override
  State<ApiKeyStep> createState() => _ApiKeyStepState();
}

class _ApiKeyStepState extends State<ApiKeyStep> {
  late TextEditingController _controller;
  bool _isValidating = false;
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

  Future<void> _validateAndProceed() async {
    final key = _controller.text.trim();
    if (key.isEmpty) {
      setState(() => _errorMessage = context.l10n.enterApiKeyError);
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
        setState(() => _errorMessage = context.l10n.invalidApiKeyError);
      }
    }
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
          Text(l10n.aiConfigure, style: AppTypography.displayMedium),
          const SizedBox(height: 16),

          RichText(
            text: TextSpan(
              style: AppTypography.bodyMedium,
              children: [
                TextSpan(text: l10n.goTo),
                TextSpan(
                  text: 'Google AI Studio',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    decoration: TextDecoration.underline,
                  ),
                  recognizer: TapGestureRecognizer()
                    ..onTap = () => launchUrl(
                      Uri.parse('https://ai.dev/apikey/'),
                      mode: LaunchMode.externalApplication,
                    ),
                ),
                TextSpan(text: l10n.createKeyInstruction),
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
            text: l10n.validateAndContinue,
            isLoading: _isValidating,
            onPressed: _validateAndProceed,
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
