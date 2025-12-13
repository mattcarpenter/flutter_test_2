import 'dart:io' show Platform;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../mobile/utils/adaptive_sliver_page.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/subscription_provider.dart';
import '../../../services/auth_service.dart';
import '../../../widgets/error_dialog.dart';
import '../models/auth_error.dart';
import '../widgets/auth_form_field.dart';
import '../widgets/auth_button.dart';
import '../widgets/social_auth_button.dart';

class SignInPage extends ConsumerStatefulWidget {
  const SignInPage({super.key});

  @override
  ConsumerState<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends ConsumerState<SignInPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  void _handleEmailSignIn() async {
    final authState = ref.read(authNotifierProvider);
    if (authState.isSigningIn) return;

    // No form validation required for sign-in as per requirements
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      await ErrorDialog.show(
        context,
        message: 'Please enter both email and password.',
      );
      return;
    }

    // Check if anonymous user with subscription - warn about data loss
    final isAnonymous = ref.read(isAnonymousUserProvider);
    final hasPlus = ref.read(hasPlusProvider);

    if (isAnonymous) {
      final shouldContinue = hasPlus
          ? await _showAnonymousSubscriptionWarning()
          : await _showDataLossWarning();
      if (!shouldContinue) return;
    }

    try {
      await ref.read(authNotifierProvider.notifier).signInWithEmail(email, password);
      if (mounted) {
        // If user was anonymous with subscription, set flag for restore prompt
        if (isAnonymous && hasPlus) {
          ref.read(authNotifierProvider.notifier).setShouldPromptRestore(true);
        }
        context.go('/recipes');
      }
    } catch (e) {
      if (mounted) {
        await ErrorDialog.show(
          context,
          message: 'Failed to sign in. Please check your credentials and try again.',
        );
      }
    }
  }

  void _handleGoogleSignIn() async {
    final authState = ref.read(authNotifierProvider);
    if (authState.isSigningInWithGoogle) return;

    // Capture state before attempting sign-in
    final isAnonymous = ref.read(isAnonymousUserProvider);
    final hasPlus = ref.read(hasPlusProvider);

    try {
      // For anonymous users, this will try linkIdentity first (upgrades account)
      await ref.read(authNotifierProvider.notifier).signInWithGoogle();
      // Small delay to let any pending deep link processing complete
      // This prevents GlobalKey collisions during the page transition
      await Future.delayed(const Duration(milliseconds: 100));
      if (mounted) {
        context.go('/recipes');
      }
    } catch (e) {
      if (mounted) {
        // Check for "identity already linked" error - means Google account exists elsewhere
        if (e is AuthApiException && e.type == AuthErrorType.identityAlreadyLinked) {
          // This Google account is linked to another user - offer to sign in to that account
          await _handleIdentityAlreadyLinkedOnSignIn(
            provider: 'Google',
            isAnonymous: isAnonymous,
            hasPlus: hasPlus,
            signInWithForce: () => ref.read(authNotifierProvider.notifier).signInWithGoogle(
              forceNativeOAuth: true,
            ),
          );
        } else {
          await ErrorDialog.show(
            context,
            message: 'Failed to sign in with Google. Please try again.',
          );
        }
      }
    }
  }

  void _handleAppleSignIn() async {
    final authState = ref.read(authNotifierProvider);
    if (authState.isSigningInWithApple) return;

    // Capture state before attempting sign-in
    final isAnonymous = ref.read(isAnonymousUserProvider);
    final hasPlus = ref.read(hasPlusProvider);

    try {
      // For anonymous users, this will try linkIdentity first (upgrades account)
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
        final errorMessage = e.toString().toLowerCase();
        if (errorMessage.contains('cancel')) return;

        // Check for "identity already linked" error - means Apple account exists elsewhere
        if (e is AuthApiException && e.type == AuthErrorType.identityAlreadyLinked) {
          // This Apple account is linked to another user - offer to sign in to that account
          await _handleIdentityAlreadyLinkedOnSignIn(
            provider: 'Apple',
            isAnonymous: isAnonymous,
            hasPlus: hasPlus,
            signInWithForce: () => ref.read(authNotifierProvider.notifier).signInWithApple(
              forceNativeOAuth: true,
            ),
          );
        } else {
          await ErrorDialog.show(
            context,
            message: 'Failed to sign in with Apple. Please try again.',
          );
        }
      }
    }
  }

  /// Show warning dialog for anonymous user with subscription signing into existing account
  Future<bool> _showAnonymousSubscriptionWarning() async {
    return await showCupertinoDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('Sign In Warning'),
            content: const Text(
              'You currently have a Stockpot Plus subscription tied to this device. '
              'If you sign in to an existing account:\n\n'
              '\u2022 Your local recipes will be replaced with the account\'s data\n'
              '\u2022 You\'ll need to restore your purchase after signing in\n\n'
              'We recommend exporting your recipes first.',
            ),
            actions: [
              CupertinoDialogAction(
                child: const Text('Cancel'),
                onPressed: () => Navigator.of(context).pop(false),
              ),
              CupertinoDialogAction(
                isDestructiveAction: true,
                child: const Text('Sign In Anyway'),
                onPressed: () => Navigator.of(context).pop(true),
              ),
            ],
          ),
        ) ??
        false;
  }

  /// Show warning dialog for anonymous user about data loss
  Future<bool> _showDataLossWarning() async {
    return await showCupertinoDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('Replace Local Data?'),
            content: const Text(
              'Signing in will replace your local recipes with the account\'s data. '
              'We recommend exporting your recipes first.',
            ),
            actions: [
              CupertinoDialogAction(
                child: const Text('Cancel'),
                onPressed: () => Navigator.of(context).pop(false),
              ),
              CupertinoDialogAction(
                isDestructiveAction: true,
                child: const Text('Sign In'),
                onPressed: () => Navigator.of(context).pop(true),
              ),
            ],
          ),
        ) ??
        false;
  }

  /// Handle the case where linkIdentity fails because the OAuth identity
  /// is already linked to another account. Show warning and offer to sign in.
  Future<void> _handleIdentityAlreadyLinkedOnSignIn({
    required String provider,
    required bool isAnonymous,
    required bool hasPlus,
    required Future<void> Function() signInWithForce,
  }) async {
    // Show appropriate warning dialog
    final shouldContinue = isAnonymous
        ? (hasPlus
            ? await _showAnonymousSubscriptionWarning()
            : await _showDataLossWarning())
        : true; // Non-anonymous users don't need warning

    if (!shouldContinue) return;

    try {
      // Sign in using native OAuth (this will switch to the other account)
      await signInWithForce();
      // Small delay to let any pending auth processing complete
      await Future.delayed(const Duration(milliseconds: 100));
      if (mounted) {
        // If user was anonymous with subscription, prompt restore
        if (isAnonymous && hasPlus) {
          ref.read(authNotifierProvider.notifier).setShouldPromptRestore(true);
        }
        context.go('/recipes');
      }
    } catch (e) {
      if (mounted) {
        // Don't show error for cancellation
        final errorMessage = e.toString().toLowerCase();
        if (!errorMessage.contains('cancel')) {
          await ErrorDialog.show(
            context,
            message: 'Failed to sign in with $provider. Please try again.',
          );
        }
      }
    }
  }

  // Max width for form on larger screens (iPad landscape)
  static const double _maxFormWidth = 400.0;

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);

    return AdaptiveSliverPage(
      title: 'Sign In',
      automaticallyImplyLeading: true,
      previousPageTitle: 'Sign Up',
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _maxFormWidth),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 24),

                  // Email field (no validation for sign-in)
                  AuthFormField(
                    controller: _emailController,
                    label: 'Email',
                    placeholder: 'your@email.com',
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    autocorrect: false,
                    enableSuggestions: false,
                    focusNode: _emailFocusNode,
                    enabled: !authState.isPerformingAction && !authState.isLoading,
                    onSubmitted: (_) => _passwordFocusNode.requestFocus(),
                  ),
                  const SizedBox(height: 16),

                  // Password field (no validation for sign-in)
                  AuthFormField(
                    controller: _passwordController,
                    label: 'Password',
                    obscureText: true,
                    textInputAction: TextInputAction.done,
                    focusNode: _passwordFocusNode,
                    enabled: !authState.isPerformingAction && !authState.isLoading,
                    onSubmitted: (_) => _handleEmailSignIn(),
                  ),
                  const SizedBox(height: 24),

                  // Sign in button
                  AuthButton.primary(
                    text: 'Sign In',
                    onPressed: _handleEmailSignIn,
                    isLoading: authState.isSigningIn,
                    enabled: !authState.isSigningInWithGoogle && !authState.isSigningInWithApple,
                  ),
                  const SizedBox(height: 16),

                  // Forgot password link
                  Center(
                    child: GestureDetector(
                      onTap: () => context.go('/auth/forgot-password'),
                      child: Text(
                        'Forgot Password?',
                        style: TextStyle(
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
