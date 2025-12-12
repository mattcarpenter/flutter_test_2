import 'dart:io' show Platform;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../mobile/utils/adaptive_sliver_page.dart';
import '../../../providers/auth_provider.dart';
import '../../../widgets/error_dialog.dart';
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

    try {
      await ref.read(authNotifierProvider.notifier).signInWithEmail(email, password);
      if (mounted) {
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

    try {
      await ref.read(authNotifierProvider.notifier).signInWithGoogle();
      if (mounted) {
        context.go('/recipes');
      }
    } catch (e) {
      if (mounted) {
        await ErrorDialog.show(
          context,
          message: 'Failed to sign in with Google. Please try again.',
        );
      }
    }
  }

  void _handleAppleSignIn() async {
    final authState = ref.read(authNotifierProvider);
    if (authState.isSigningInWithApple) return;

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
            message: 'Failed to sign in with Apple. Please try again.',
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
