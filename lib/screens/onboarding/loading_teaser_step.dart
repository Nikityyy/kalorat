import 'package:flutter/material.dart';
import '../../theme/app_typography.dart';
import '../../theme/app_colors.dart';
import '../../extensions/l10n_extension.dart';

class LoadingTeaserStep extends StatefulWidget {
  final VoidCallback onNext;

  const LoadingTeaserStep({super.key, required this.onNext});

  @override
  State<LoadingTeaserStep> createState() => _LoadingTeaserStepState();
}

class _LoadingTeaserStepState extends State<LoadingTeaserStep> {
  int _currentMessageIndex = 0;
  @override
  void initState() {
    super.initState();
    _startSequence();
  }

  void _startSequence() async {
    for (int i = 0; i < 4; i++) {
      if (!mounted) return;
      setState(() => _currentMessageIndex = i);
      await Future.delayed(const Duration(milliseconds: 1200));
    }
    if (mounted) {
      widget.onNext();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final List<String> messages = [
      l10n.analyzingBiometrics,
      l10n.calculatingMetabolicRate,
      l10n.personalizingPlan,
      l10n.almostReady
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            color: AppColors.primary,
            strokeWidth: 4,
          ),
          const SizedBox(height: 32),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            child: Text(
              messages[_currentMessageIndex],
              key: ValueKey<int>(_currentMessageIndex),
              style: AppTypography.titleLarge.copyWith(color: AppColors.slate),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
