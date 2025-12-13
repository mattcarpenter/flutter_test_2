import 'dart:io' show Platform;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../mobile/utils/adaptive_sliver_page.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/subscription_provider.dart';
import '../../../theme/colors.dart';
import '../../../widgets/error_dialog.dart';
import '../widgets/auth_form_field.dart';
import '../widgets/auth_button.dart';
import '../widgets/social_auth_button.dart';

class SignUpPage extends ConsumerStatefulWidget {
  const SignUpPage({super.key});

  @override
  ConsumerState<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends ConsumerState<SignUpPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  final _confirmPasswordFocusNode = FocusNode();

  bool _acceptTerms = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
    super.dispose();
  }

  void _handleEmailSignUp() async {
    final authState = ref.read(authNotifierProvider);
    if (authState.isSigningUp) return;

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_acceptTerms) {
      await ErrorDialog.show(
        context,
        message: 'Please accept the Terms of Service and Privacy Policy to continue.',
      );
      return;
    }

    try {
      await ref.read(authNotifierProvider.notifier).signUpWithEmail(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (mounted) {
        context.go('/recipes');
      }
    } catch (e) {
      if (mounted) {
        await ErrorDialog.show(
          context,
          message: 'Failed to create account. Please try again.',
        );
      }
    }
  }

  void _handleGoogleSignIn() async {
    final authState = ref.read(authNotifierProvider);
    if (authState.isSigningInWithGoogle) return;

    // Capture anonymous state BEFORE OAuth (native OAuth can't link to anonymous user)
    final wasAnonymous = ref.read(isAnonymousUserProvider);
    final hadPlus = ref.read(hasPlusProvider);

    try {
      await ref.read(authNotifierProvider.notifier).signInWithGoogle();
      if (mounted) {
        // If user was anonymous, show post-OAuth notification
        // Native OAuth always creates/signs into separate account (can't upgrade anonymous)
        if (wasAnonymous) {
          if (hadPlus) {
            // Had subscription - prompt to restore
            ref.read(authNotifierProvider.notifier).setShouldPromptRestore(true);
            await _showPostOAuthSubscriptionNotice();
          } else {
            // No subscription - just inform about data replacement
            await _showPostOAuthDataNotice();
          }
        }
        context.go('/recipes');
      }
    } catch (e) {
      if (mounted) {
        // Don't show error for user cancellation
        final errorMessage = e.toString().toLowerCase();
        if (!errorMessage.contains('cancel')) {
          await ErrorDialog.show(
            context,
            message: 'Failed to sign up with Google. Please try again.',
          );
        }
      }
    }
  }

  void _handleAppleSignIn() async {
    final authState = ref.read(authNotifierProvider);
    if (authState.isSigningInWithApple) return;

    // Capture anonymous state BEFORE OAuth (native OAuth can't link to anonymous user)
    final wasAnonymous = ref.read(isAnonymousUserProvider);
    final hadPlus = ref.read(hasPlusProvider);

    try {
      await ref.read(authNotifierProvider.notifier).signInWithApple();
      if (mounted) {
        // If user was anonymous, show post-OAuth notification
        // Native OAuth always creates/signs into separate account (can't upgrade anonymous)
        if (wasAnonymous) {
          if (hadPlus) {
            // Had subscription - prompt to restore
            ref.read(authNotifierProvider.notifier).setShouldPromptRestore(true);
            await _showPostOAuthSubscriptionNotice();
          } else {
            // No subscription - just inform about data replacement
            await _showPostOAuthDataNotice();
          }
        }
        context.go('/recipes');
      }
    } catch (e) {
      if (mounted) {
        // Don't show error for user cancellation
        final errorMessage = e.toString().toLowerCase();
        if (!errorMessage.contains('cancel')) {
          await ErrorDialog.show(
            context,
            message: 'Failed to sign up with Apple. Please try again.',
          );
        }
      }
    }
  }

  /// Show post-OAuth notice for anonymous user who had a subscription
  /// Informs them they need to restore their purchase
  Future<void> _showPostOAuthSubscriptionNotice() async {
    await showCupertinoDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Account Created'),
        content: const Text(
          'Your new account has been created successfully.\n\n'
          'Your previous Stockpot Plus subscription was tied to your device. '
          'You\'ll be prompted to restore your purchase shortly.',
        ),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            child: const Text('OK'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  /// Show post-OAuth notice for anonymous user without subscription
  /// Just informs them about the new account
  Future<void> _showPostOAuthDataNotice() async {
    await showCupertinoDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Account Created'),
        content: const Text(
          'Your new account has been created successfully.\n\n'
          'Your recipes and data are now synced to this account.',
        ),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            child: const Text('OK'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final isAnyActionInProgress = authState.isPerformingAction || authState.isLoading;

    return AdaptiveSliverPage(
      title: 'Create Account',
      automaticallyImplyLeading: true,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),

              // Email field with validation
              EmailFormField(
                controller: _emailController,
                focusNode: _emailFocusNode,
                enabled: !isAnyActionInProgress,
                onSubmitted: (_) => _passwordFocusNode.requestFocus(),
              ),
              const SizedBox(height: 16),

              // Password field with validation
              PasswordFormField(
                controller: _passwordController,
                focusNode: _passwordFocusNode,
                enabled: !isAnyActionInProgress,
                textInputAction: TextInputAction.next,
                onSubmitted: (_) => _confirmPasswordFocusNode.requestFocus(),
              ),
              const SizedBox(height: 16),

              // Confirm password field with validation
              ConfirmPasswordFormField(
                controller: _confirmPasswordController,
                passwordController: _passwordController,
                focusNode: _confirmPasswordFocusNode,
                enabled: !isAnyActionInProgress,
                onSubmitted: (_) => _handleEmailSignUp(),
              ),
              const SizedBox(height: 24),

              // Terms checkbox
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Checkbox(
                    value: _acceptTerms,
                    onChanged: isAnyActionInProgress
                        ? null
                        : (value) {
                            setState(() {
                              _acceptTerms = value ?? false;
                            });
                          },
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 12.0),
                      child: RichText(
                        text: TextSpan(
                          style: Theme.of(context).textTheme.bodyMedium,
                          children: [
                            const TextSpan(text: 'I agree to the '),
                            TextSpan(
                              text: 'Terms of Service',
                              style: TextStyle(
                                color: Theme.of(context).primaryColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const TextSpan(text: ' and '),
                            TextSpan(
                              text: 'Privacy Policy',
                              style: TextStyle(
                                color: Theme.of(context).primaryColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Create account button
              AuthButton.primary(
                text: 'Create Account',
                onPressed: _handleEmailSignUp,
                isLoading: authState.isSigningUp,
                enabled: !authState.isSigningInWithGoogle && !authState.isSigningInWithApple,
              ),
              const SizedBox(height: 32),

              // Divider
              Row(
                children: [
                  const Expanded(child: Divider()),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'OR',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: 32),

              // Google sign in button
              GoogleSignInButton(
                onPressed: _handleGoogleSignIn,
                isLoading: authState.isSigningInWithGoogle,
              ),

              // Apple sign in button (iOS only)
              if (Platform.isIOS) ...[
                const SizedBox(height: 16),
                AppleSignInButton(
                  onPressed: _handleAppleSignIn,
                  isLoading: authState.isSigningInWithApple,
                ),
              ],
              const SizedBox(height: 32),

              // Sign in link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Already have an account? ',
                    style: TextStyle(color: AppColors.of(context).textSecondary),
                  ),
                  GestureDetector(
                    onTap: () => context.go('/auth/signin'),
                    child: Text(
                      'Sign In',
                      style: TextStyle(
                        color: AppColors.of(context).primary,
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
    );
  }
}
