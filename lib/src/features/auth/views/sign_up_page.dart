import 'dart:io' show Platform;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../mobile/utils/adaptive_sliver_page.dart';
import '../../../providers/auth_provider.dart';
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
  
  bool _isEmailSignUpLoading = false;
  bool _isGoogleLoading = false;
  bool _isAppleLoading = false;
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
    if (_isEmailSignUpLoading) return;

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

    setState(() {
      _isEmailSignUpLoading = true;
    });

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
    } finally {
      if (mounted) {
        setState(() {
          _isEmailSignUpLoading = false;
        });
      }
    }
  }

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
          message: 'Failed to sign in with Google. Please try again.',
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
            message: 'Failed to sign in with Apple. Please try again.',
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
                enabled: !_isEmailSignUpLoading && !_isGoogleLoading && !_isAppleLoading,
                onSubmitted: (_) => _passwordFocusNode.requestFocus(),
              ),
              const SizedBox(height: 16),

              // Password field with validation
              PasswordFormField(
                controller: _passwordController,
                focusNode: _passwordFocusNode,
                enabled: !_isEmailSignUpLoading && !_isGoogleLoading && !_isAppleLoading,
                textInputAction: TextInputAction.next,
                onSubmitted: (_) => _confirmPasswordFocusNode.requestFocus(),
              ),
              const SizedBox(height: 16),

              // Confirm password field with validation
              ConfirmPasswordFormField(
                controller: _confirmPasswordController,
                passwordController: _passwordController,
                focusNode: _confirmPasswordFocusNode,
                enabled: !_isEmailSignUpLoading && !_isGoogleLoading && !_isAppleLoading,
                onSubmitted: (_) => _handleEmailSignUp(),
              ),
              const SizedBox(height: 24),

              // Terms checkbox
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Checkbox(
                    value: _acceptTerms,
                    onChanged: _isEmailSignUpLoading || _isGoogleLoading || _isAppleLoading
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
                isLoading: _isEmailSignUpLoading,
                enabled: !_isGoogleLoading && !_isAppleLoading,
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