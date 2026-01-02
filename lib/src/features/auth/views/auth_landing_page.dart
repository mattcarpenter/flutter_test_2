import 'dart:io' show Platform;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../mobile/utils/adaptive_sliver_page.dart';
import '../../../providers/auth_provider.dart';
import '../../../theme/colors.dart';
import '../../../theme/typography.dart';
import '../../../localization/l10n_extension.dart';
import '../../../widgets/error_dialog.dart';
import '../widgets/auth_button.dart';
import '../widgets/social_auth_button.dart';

class AuthLandingPage extends ConsumerStatefulWidget {
  final VoidCallback? onMenuPressed;

  const AuthLandingPage({
    super.key,
    this.onMenuPressed,
  });

  @override
  ConsumerState<AuthLandingPage> createState() => _AuthLandingPageState();
}

class _AuthLandingPageState extends ConsumerState<AuthLandingPage> {
  bool _isGoogleLoading = false;
  bool _isAppleLoading = false;

  // Max width for buttons on larger screens (iPad landscape)
  static const double _maxButtonWidth = 400.0;

  void _handleGoogleSignIn() async {
    if (_isGoogleLoading) return;

    setState(() {
      _isGoogleLoading = true;
    });

    try {
      await ref.read(authNotifierProvider.notifier).signInWithGoogle();
      if (mounted) {
        context.go('/recipes');
      }
    } catch (e) {
      if (mounted) {
        await ErrorDialog.show(
          context,
          message: context.l10n.authFailedGoogle,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGoogleLoading = false;
        });
      }
    }
  }

  void _handleAppleSignIn() async {
    if (_isAppleLoading) return;

    setState(() {
      _isAppleLoading = true;
    });

    try {
      await ref.read(authNotifierProvider.notifier).signInWithApple();
      if (mounted) {
        context.go('/recipes');
      }
    } catch (e) {
      if (mounted) {
        // Don't show error for user cancellation
        final errorMessage = e.toString().toLowerCase();
        if (!errorMessage.contains('cancel')) {
          await ErrorDialog.show(
            context,
            message: context.l10n.authFailedApple,
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isAppleLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return AdaptiveSliverPage(
      title: context.l10n.authSignUp,
      leading: widget.onMenuPressed != null
          ? GestureDetector(
              onTap: widget.onMenuPressed,
              child: const HugeIcon(icon: HugeIcons.strokeRoundedMenu01),
            )
          : null,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _maxButtonWidth),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Auth buttons
                AuthButton.primary(
                  text: context.l10n.authContinueWithEmail,
                  onPressed: () => context.go('/auth/signup'),
                ),
                const SizedBox(height: 16),
                GoogleSignInButton(
                  onPressed: _handleGoogleSignIn,
                  isLoading: _isGoogleLoading,
                ),

                // Apple sign in button (iOS only)
                if (Platform.isIOS) ...[
                  const SizedBox(height: 16),
                  AppleSignInButton(
                    onPressed: _handleAppleSignIn,
                    isLoading: _isAppleLoading,
                  ),
                ],
                const SizedBox(height: 32),

                // Sign in link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      context.l10n.authAlreadyHaveAccount,
                      style: AppTypography.body.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => context.go('/auth/signin'),
                      child: Text(
                        context.l10n.authSignIn,
                        style: AppTypography.body.copyWith(
                          color: colors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}