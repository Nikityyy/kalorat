import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../extensions/l10n_extension.dart';
import '../../providers/app_provider.dart';
import '../../services/auth_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_typography.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Login step in onboarding flow after API key entry.
/// Shows Google Sign-In on both platforms, Apple Sign-In on iOS only.
/// "Continue as guest" option available but discouraged.
class LoginStep extends StatefulWidget {
  final VoidCallback onNext;
  final VoidCallback? onLoginSuccess;
  final String language;

  const LoginStep({
    super.key,
    required this.onNext,
    this.onLoginSuccess,
    required this.language,
  });

  @override
  State<LoginStep> createState() => _LoginStepState();
}

class _LoginStepState extends State<LoginStep> {
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Check if user is already signed in (e.g. returning from OAuth redirect)
    // We use postFrameCallback to avoid build-phase modifications if we wanted to auto-navigate,
    // but here we just want to update UI state if needed.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = _authService.currentUser;
      if (user != null && mounted) {
        // User is authenticated. We can either auto-advance OR show a "Continue" button.
        // Given the instructions said "show a Continue button", let's handle that UI logic.
        // For now, if we are already logged in, we can also just auto-update the provider.
        _handleExistingSession(user);
      }
    });
  }

  Future<void> _handleExistingSession(User user) async {
    setState(() => _isLoading = true);
    try {
      final provider = context.read<AppProvider>();
      // Sync Supabase user to AppProvider and fetch cloud data
      await provider.loginWithSupabase(
        userId: user.id,
        email: user.email ?? '',
        photoUrl: user.userMetadata?['avatar_url'] as String?,
      );
      // Wait a tick to ensure UI updates before moving on
      if (mounted) {
        setState(() => _isLoading = false);

        // Notify parent that login succeeded (to refresh data)
        widget.onLoginSuccess?.call();

        // Optional: Auto-advance
        widget.onNext();
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final (response, photoUrl) = await _authService.signInWithGoogle();
      if (response.user != null && mounted) {
        // Update provider with auth info
        final provider = context.read<AppProvider>();
        await provider.loginWithSupabase(
          userId: response.user!.id,
          email: response.user!.email ?? '',
          photoUrl: photoUrl,
        );

        // Notify parent that login succeeded (to refresh data)
        widget.onLoginSuccess?.call();

        widget.onNext();
      }
    } catch (e) {
      // Don't show error if user just cancelled or if it's the expected Web Redirect
      final errorStr = e.toString();
      // "302" is the status code we manually threw for redirect
      if (errorStr.contains('302') ||
          errorStr.contains('Redirecting') ||
          errorStr.toLowerCase().contains('cancel')) {
        // Do nothing, browser is handling it or user cancelled
      } else if (mounted) {
        setState(() => _error = e.toString());
      }
    } finally {
      // If we are redirecting, we might not want to stop loading to keep UI stable until unload
      if (mounted && _error != null) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _continueAsGuest() {
    final provider = context.read<AppProvider>();
    provider.updateUser(isGuest: true);
    widget.onNext();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    // Check current auth status for "Continue as..." button
    final currentUser = _authService.currentUser;
    final isAlreadyLoggedIn = currentUser != null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          Text(l10n.loginTitle, style: AppTypography.displayMedium),
          const SizedBox(height: 16),
          Text(
            l10n.loginSubtitle,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.slate.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 48),

          // Google Sign-In Button (Official Branding)
          if (isAlreadyLoggedIn)
            _ContinueButton(
              email: currentUser.email ?? 'User',
              onPressed: _isLoading ? null : () => widget.onNext(),
              isLoading: _isLoading,
            )
          else
            _GoogleSignInButton(
              onPressed: _isLoading ? null : _signInWithGoogle,
              isLoading: _isLoading,
            ),

          if (_error != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                border: Border.all(color: AppColors.error),
              ),
              child: Text(
                _error!,
                style: AppTypography.bodySmall.copyWith(color: AppColors.error),
              ),
            ),
          ],

          const Spacer(),

          // Guest warning
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.pebble.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(AppTheme.borderRadius),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: AppColors.slate.withValues(alpha: 0.6),
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    l10n.guestWarning,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.slate.withValues(alpha: 0.7),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Continue as guest (subtle text button)
          Center(
            child: TextButton(
              onPressed: _isLoading ? null : _continueAsGuest,
              child: Text(
                l10n.continueAsGuest,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.slate.withValues(alpha: 0.5),
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

/// Google Sign-In Button following Google's branding guidelines.
/// White background, Google "G" logo, "Sign in with Google" text.
/// https://developers.google.com/identity/branding-guidelines
/// Google Sign-In Button following Kalorat brand identity.
/// "Digital Alpinism": Sharp (12px), White Background, Gray Border.
class _GoogleSignInButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isLoading;

  const _GoogleSignInButton({required this.onPressed, this.isLoading = false});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56, // Standard height for touch targets
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: AppColors.slate,
          elevation: 0, // No shadow (flat, clean)
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12), // 12px radius
            side: const BorderSide(
              color: Color(0xFFD1D5DB),
              width: 1,
            ), // 1px gray border
          ),
          // Add haptic feedback on press
          enableFeedback: true,
        ),
        child: isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primary,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Google "G" logo - SVG asset
                  SvgPicture.asset(
                    'assets/google_logo.svg',
                    width: 24,
                    height: 24,
                  ),
                  const SizedBox(width: 12),
                  const Flexible(
                    child: Text(
                      'Sign in with Google',
                      style: TextStyle(
                        fontFamily: 'Outfit', // Brand font
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: AppColors.slate,
                        letterSpacing: -0.5, // Slightly tighter tracking
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _ContinueButton extends StatelessWidget {
  final String email;
  final VoidCallback? onPressed;
  final bool isLoading;

  const _ContinueButton({
    required this.email,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          enableFeedback: true,
        ),
        child: isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_circle_outline, size: 24),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Text(
                      'Continue as $email',
                      style: const TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
