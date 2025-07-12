import 'dart:io' show Platform;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../mobile/utils/adaptive_sliver_page.dart';
import '../../../providers/auth_provider.dart';
import '../../../widgets/error_dialog.dart';
import '../../../widgets/success_dialog.dart';
import '../widgets/auth_button.dart';

class EmailVerificationPage extends ConsumerStatefulWidget {
  const EmailVerificationPage({super.key});

  @override
  ConsumerState<EmailVerificationPage> createState() => _EmailVerificationPageState();
}

class _EmailVerificationPageState extends ConsumerState<EmailVerificationPage> {
  bool _isResendLoading = false;

  void _handleResendEmail() async {
    if (_isResendLoading) return;

    final currentUser = ref.read(currentUserProvider);
    if (currentUser?.email == null) {
      await ErrorDialog.show(
        context,
        message: 'Unable to resend verification email. Please try signing up again.',
      );
      return;
    }

    setState(() {
      _isResendLoading = true;
    });

    try {
      await ref.read(authNotifierProvider.notifier).resendEmailVerification(
        currentUser!.email!,
      );
      
      if (mounted) {
        await SuccessDialog.show(
          context,
          message: 'Verification email sent! Check your inbox.',
        );
      }
    } catch (e) {
      if (mounted) {
        await ErrorDialog.show(
          context,
          message: 'Failed to resend verification email. Please try again.',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isResendLoading = false;
        });
      }
    }
  }

  void _handleOpenEmailApp() async {
    try {
      Uri emailUri;
      
      if (Platform.isIOS) {
        // Try iOS Mail app first
        emailUri = Uri.parse('message://');
        if (await canLaunchUrl(emailUri)) {
          await launchUrl(emailUri);
          return;
        }
        
        // Fall back to Gmail if available
        emailUri = Uri.parse('googlegmail://');
        if (await canLaunchUrl(emailUri)) {
          await launchUrl(emailUri);
          return;
        }
      } else if (Platform.isAndroid) {
        // Try Gmail app first
        emailUri = Uri.parse('googlegmail://');
        if (await canLaunchUrl(emailUri)) {
          await launchUrl(emailUri);
          return;
        }
        
        // Fall back to generic email intent
        emailUri = Uri.parse('mailto:');
        if (await canLaunchUrl(emailUri)) {
          await launchUrl(emailUri);
          return;
        }
      }
      
      // Fall back to generic mailto
      emailUri = Uri.parse('mailto:');
      await launchUrl(emailUri);
    } catch (e) {
      if (mounted) {
        await ErrorDialog.show(
          context,
          message: 'Unable to open email app. Please check your email manually.',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    final userEmail = currentUser?.email ?? 'your email';

    return AdaptiveSliverPage(
      title: 'Verify Your Email',
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Email icon
            const Icon(
              Icons.email_outlined,
              size: 80,
              color: Colors.blue,
            ),
            const SizedBox(height: 24),

            // Title
            Text(
              'Check Your Email',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),

            // Instructions
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.grey[700],
                ),
                children: [
                  const TextSpan(
                    text: 'We sent a verification link to\n',
                  ),
                  TextSpan(
                    text: userEmail,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const TextSpan(
                    text: '\n\nClick the link in the email to verify your account.',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 48),

            // Resend email button
            AuthButton.secondary(
              text: 'Resend Email',
              onPressed: _handleResendEmail,
              isLoading: _isResendLoading,
            ),
            const SizedBox(height: 16),

            // Open email app button
            AuthButton.primary(
              text: 'Open Email App',
              onPressed: _handleOpenEmailApp,
              enabled: !_isResendLoading,
            ),
            const SizedBox(height: 32),

            // Change email link
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Wrong email address? '),
                GestureDetector(
                  onTap: () => context.go('/auth/signup'),
                  child: Text(
                    'Change Email Address',
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}