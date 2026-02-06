import 'dart:io';
import 'package:flutter/material.dart';
import '../../theme/app_typography.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../extensions/l10n_extension.dart';
import '../../widgets/inputs/action_button.dart';
import '../../services/health_service.dart';

class HealthStep extends StatefulWidget {
  final Function(bool connected) onNext;
  final String language;

  const HealthStep({super.key, required this.onNext, required this.language});

  @override
  State<HealthStep> createState() => _HealthStepState();
}

class _HealthStepState extends State<HealthStep> {
  bool _isConnecting = false;
  bool _isConnected = false;
  String? _errorMessage;

  Future<void> _connectHealth() async {
    setState(() {
      _isConnecting = true;
      _errorMessage = null;
    });

    try {
      final healthService = HealthService();

      // Check if Health Connect is available on Android
      if (Platform.isAndroid) {
        final available = await healthService.isHealthConnectAvailable();
        if (!available) {
          setState(() {
            _isConnecting = false;
            _errorMessage = context.l10n.healthConnectNotInstalled;
          });
          return;
        }
      }

      // Request permissions
      final granted = await healthService.requestPermissions();

      setState(() {
        _isConnecting = false;
        _isConnected = granted;
        if (!granted) {
          _errorMessage = context.l10n.healthPermissionDenied;
        }
      });

      if (granted) {
        // Short delay to show success before moving on
        await Future.delayed(const Duration(milliseconds: 500));
        widget.onNext(true);
      }
    } catch (e) {
      setState(() {
        _isConnecting = false;
        _errorMessage = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final healthAppName = Platform.isIOS ? 'Apple Health' : 'Health Connect';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          Text(l10n.healthOnboardingTitle, style: AppTypography.displayMedium),
          const SizedBox(height: 16),
          Text(
            l10n.healthOnboardingDescription,
            style: AppTypography.bodyLarge.copyWith(
              color: AppColors.slate.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 32),

          // Health app icon
          Center(
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Platform.isIOS
                    ? const Color(0xFFFF2D55) // Apple Health red
                    : AppColors.primary, // Health Connect green
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color:
                        (Platform.isIOS
                                ? const Color(0xFFFF2D55)
                                : AppColors.primary)
                            .withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(Icons.favorite, color: Colors.white, size: 48),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              healthAppName,
              style: AppTypography.titleLarge.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          const SizedBox(height: 32),

          // Benefits list
          _buildBenefitRow(Icons.restaurant, l10n.healthOnboardingBenefit1),
          const SizedBox(height: 12),
          _buildBenefitRow(Icons.sync, l10n.healthOnboardingBenefit2),
          const SizedBox(height: 12),
          _buildBenefitRow(Icons.dashboard, l10n.healthOnboardingBenefit3),

          if (_errorMessage != null) ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                border: Border.all(
                  color: AppColors.error.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: AppColors.error, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(color: AppColors.error, fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
          ],

          if (_isConnected) ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                border: Border.all(
                  color: AppColors.success.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: AppColors.success, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    l10n.healthConnected,
                    style: TextStyle(
                      color: AppColors.success,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],

          const Spacer(),

          // Connect button
          ActionButton(
            text: _isConnecting
                ? '...'
                : (_isConnected ? l10n.healthConnected : l10n.connectNow),
            onPressed: _isConnecting || _isConnected ? null : _connectHealth,
          ),

          const SizedBox(height: 12),

          // Skip button
          Center(
            child: TextButton(
              onPressed: () => widget.onNext(false),
              child: Text(
                l10n.skipForNow,
                style: TextStyle(
                  color: AppColors.slate.withValues(alpha: 0.6),
                  fontSize: 16,
                ),
              ),
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildBenefitRow(IconData icon, String text) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: AppTypography.bodyMedium.copyWith(color: AppColors.slate),
          ),
        ),
      ],
    );
  }
}
