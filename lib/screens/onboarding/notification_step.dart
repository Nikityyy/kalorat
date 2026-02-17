import 'package:flutter/material.dart';
import '../../theme/app_typography.dart';
import '../../theme/app_colors.dart';
import '../../extensions/l10n_extension.dart';
import '../../widgets/inputs/action_button.dart';
import '../../services/services.dart';

class NotificationStep extends StatefulWidget {
  final Function(bool enabled) onNext;
  final String language;

  const NotificationStep({
    super.key,
    required this.onNext,
    required this.language,
  });

  @override
  State<NotificationStep> createState() => _NotificationStepState();
}

class _NotificationStepState extends State<NotificationStep> {
  bool _isLoading = false;

  Future<void> _enableNotifications() async {
    setState(() => _isLoading = true);

    try {
      // Request permissions
      final granted = await NotificationService().requestPermissions();
      widget.onNext(granted);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
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
          Text(l10n.notifications, style: AppTypography.displayMedium),
          const SizedBox(height: 16),
          Text(
            l10n.mealReminderBody,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.slate.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 48),

          // Illustration or Icon
          Center(
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.notifications_active_outlined,
                size: 72,
                color: AppColors.primary,
              ),
            ),
          ),

          const SizedBox(height: 48),

          // Benefits
          _buildBenefit(
            context,
            Icons.notifications_outlined,
            l10n.mealReminders,
          ),
          const SizedBox(height: 20),
          _buildBenefit(
            context,
            Icons.monitor_weight_outlined,
            l10n.weightReminders,
          ),

          const Spacer(),

          ActionButton(
            text: l10n.continueButton,
            isLoading: _isLoading,
            onPressed: _enableNotifications,
          ),
          const SizedBox(height: 12),
          Center(
            child: TextButton(
              onPressed: () => widget.onNext(false),
              child: Text(
                l10n.laterButton,
                style: AppTypography.labelLarge.copyWith(
                  color: AppColors.slate.withValues(alpha: 0.6),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildBenefit(BuildContext context, IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 24),
        const SizedBox(width: 16),
        Text(text, style: AppTypography.bodyMedium),
      ],
    );
  }
}
