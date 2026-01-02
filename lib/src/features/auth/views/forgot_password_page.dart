import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../mobile/utils/adaptive_sliver_page.dart';
import '../../../theme/colors.dart';
import '../../../theme/typography.dart';
import '../../../providers/auth_provider.dart';
import '../../../widgets/error_dialog.dart';
import '../../../widgets/success_dialog.dart';
import '../../../localization/l10n_extension.dart';
import '../widgets/auth_form_field.dart';
import '../widgets/auth_button.dart';

class ForgotPasswordPage extends ConsumerStatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  ConsumerState<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends ConsumerState<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _emailFocusNode = FocusNode();

  @override
  void dispose() {
    _emailController.dispose();
    _emailFocusNode.dispose();
    super.dispose();
  }

  void _handleResetPassword() async {
    final authState = ref.read(authNotifierProvider);
    if (authState.isResettingPassword) return;

    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      await ref.read(authNotifierProvider.notifier).resetPassword(
        _emailController.text.trim(),
      );

      if (mounted) {
        await SuccessDialog.show(
          context,
          message: context.l10n.authPasswordResetSuccess,
        );
        if (mounted) {
          context.go('/auth/signin');
        }
      }
    } catch (e) {
      if (mounted) {
        await ErrorDialog.show(
          context,
          message: context.l10n.authPasswordResetFailed,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);

    return AdaptiveSliverPage(
      title: context.l10n.authResetPassword,
      automaticallyImplyLeading: true,
      previousPageTitle: context.l10n.authSignIn,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),

              // Instructions
              Text(
                context.l10n.authResetPasswordInstructions,
                style: AppTypography.body.copyWith(
                  color: AppColors.of(context).textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Email field with validation
              EmailFormField(
                controller: _emailController,
                focusNode: _emailFocusNode,
                enabled: !authState.isResettingPassword,
                autofocus: true,
                onSubmitted: (_) => _handleResetPassword(),
              ),
              const SizedBox(height: 24),

              // Send reset link button
              ResetPasswordButton(
                onPressed: _handleResetPassword,
                isLoading: authState.isResettingPassword,
              ),
              const SizedBox(height: 32),

              // Back to sign in link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    context.l10n.authRememberPassword,
                    style: AppTypography.body.copyWith(
                      color: AppColors.of(context).textSecondary,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => context.go('/auth/signin'),
                    child: Text(
                      context.l10n.authSignIn,
                      style: AppTypography.body.copyWith(
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
