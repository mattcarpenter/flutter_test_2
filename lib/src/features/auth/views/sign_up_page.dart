import 'dart:io' show Platform;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../mobile/utils/adaptive_sliver_page.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/auth_service.dart';
import '../../../theme/colors.dart';
import '../../../widgets/error_dialog.dart';
import '../models/auth_error.dart';
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

    try {
      await ref.read(authNotifierProvider.notifier).signInWithGoogle();
      // Small delay to let any pending deep link processing complete
      // This prevents GlobalKey collisions during the page transition
      await Future.delayed(const Duration(milliseconds: 100));
      if (mounted) {
        context.go('/recipes');
      }
    } catch (e) {
      if (mounted) {
        // Don't show error for user cancellation
        if (e is AuthApiException && e.type == AuthErrorType.cancelled) return;
        final errorMessage = e.toString().toLowerCase();
        if (errorMessage.contains('cancel')) return;

        // Check for "identity already linked" error
        if (e is AuthApiException && e.type == AuthErrorType.identityAlreadyLinked) {
          await _showIdentityAlreadyLinkedError('Google');
        } else {
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

    try {
      await ref.read(authNotifierProvider.notifier).signInWithApple();
      // Small delay to let any pending deep link processing complete
      // This prevents GlobalKey collisions during the page transition
      await Future.delayed(const Duration(milliseconds: 100));
      if (mounted) {
        context.go('/recipes');
      }
    } catch (e) {
      if (mounted) {
        // Don't show error for user cancellation
        if (e is AuthApiException && e.type == AuthErrorType.cancelled) return;
        final errorMessage = e.toString().toLowerCase();
        if (errorMessage.contains('cancel')) return;

        // Check for "identity already linked" error
        if (e is AuthApiException && e.type == AuthErrorType.identityAlreadyLinked) {
          await _showIdentityAlreadyLinkedError('Apple');
        } else {
          await ErrorDialog.show(
            context,
            message: 'Failed to sign up with Apple. Please try again.',
          );
        }
      }
    }
  }

  /// Show error when the OAuth identity is already linked to another account
  Future<void> _showIdentityAlreadyLinkedError(String provider) async {
    await showCupertinoDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Account Already Exists'),
        content: Text(
          'This $provider account is already linked to another user. '
          'Please go to Sign In to access that account.',
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            child: const Text('Go to Sign In'),
            onPressed: () {
              Navigator.of(context).pop();
              context.go('/auth/signin');
            },
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
