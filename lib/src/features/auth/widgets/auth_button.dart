import 'dart:io' show Platform;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';


enum AuthButtonType {
  primary,
  secondary,
  text,
}

class AuthButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final AuthButtonType type;
  final bool enabled;
  final Widget? icon;

  const AuthButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.type = AuthButtonType.primary,
    this.enabled = true,
    this.icon,
  });

  const AuthButton.primary({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.enabled = true,
    this.icon,
  }) : type = AuthButtonType.primary;

  const AuthButton.secondary({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.enabled = true,
    this.icon,
  }) : type = AuthButtonType.secondary;

  const AuthButton.text({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.enabled = true,
    this.icon,
  }) : type = AuthButtonType.text;

  bool get _canPress => enabled && !isLoading && onPressed != null;

  @override
  Widget build(BuildContext context) {
    if (Platform.isIOS) {
      return _buildCupertinoButton(context);
    } else {
      return _buildMaterialButton(context);
    }
  }

  Widget _buildCupertinoButton(BuildContext context) {
    Widget child = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLoading)
          const CupertinoActivityIndicator(color: CupertinoColors.white)
        else if (icon != null)
          icon!,
        if ((isLoading || icon != null) && text.isNotEmpty) const SizedBox(width: 8),
        if (text.isNotEmpty)
          Text(
            text,
            style: _getCupertinoTextStyle(context),
          ),
      ],
    );

    switch (type) {
      case AuthButtonType.primary:
        return CupertinoButton.filled(
          onPressed: _canPress ? onPressed : null,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          borderRadius: BorderRadius.circular(8),
          child: child,
        );

      case AuthButtonType.secondary:
        return CupertinoButton(
          onPressed: _canPress ? onPressed : null,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          color: CupertinoColors.systemGrey6.resolveFrom(context),
          borderRadius: BorderRadius.circular(8),
          child: child,
        );

      case AuthButtonType.text:
        return CupertinoButton(
          onPressed: _canPress ? onPressed : null,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: child,
        );
    }
  }

  Widget _buildMaterialButton(BuildContext context) {
    Widget child = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLoading)
          const SizedBox(
            height: 16,
            width: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white,
            ),
          )
        else if (icon != null)
          icon!,
        if ((isLoading || icon != null) && text.isNotEmpty) const SizedBox(width: 8),
        if (text.isNotEmpty)
          Text(
            text,
            style: _getMaterialTextStyle(context),
          ),
      ],
    );

    switch (type) {
      case AuthButtonType.primary:
        return ElevatedButton(
          onPressed: _canPress ? onPressed : null,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: child,
        );

      case AuthButtonType.secondary:
        return OutlinedButton(
          onPressed: _canPress ? onPressed : null,
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: child,
        );

      case AuthButtonType.text:
        return TextButton(
          onPressed: _canPress ? onPressed : null,
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
          child: child,
        );
    }
  }

  TextStyle? _getCupertinoTextStyle(BuildContext context) {
    switch (type) {
      case AuthButtonType.primary:
        return const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: CupertinoColors.white,
        );
      case AuthButtonType.secondary:
        return TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: _canPress
              ? CupertinoColors.systemBlue.resolveFrom(context)
              : CupertinoColors.inactiveGray.resolveFrom(context),
        );
      case AuthButtonType.text:
        return TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: _canPress
              ? CupertinoColors.systemBlue.resolveFrom(context)
              : CupertinoColors.inactiveGray.resolveFrom(context),
        );
    }
  }

  TextStyle? _getMaterialTextStyle(BuildContext context) {
    switch (type) {
      case AuthButtonType.primary:
        return const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        );
      case AuthButtonType.secondary:
        return const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        );
      case AuthButtonType.text:
        return const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
        );
    }
  }
}

// Pre-configured auth buttons for common use cases
class SignInButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isLoading;

  const SignInButton({
    super.key,
    this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: AuthButton.primary(
        text: 'Sign In',
        onPressed: onPressed,
        isLoading: isLoading,
      ),
    );
  }
}

class SignUpButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isLoading;

  const SignUpButton({
    super.key,
    this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: AuthButton.primary(
        text: 'Create Account',
        onPressed: onPressed,
        isLoading: isLoading,
      ),
    );
  }
}

class ResetPasswordButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isLoading;

  const ResetPasswordButton({
    super.key,
    this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: AuthButton.primary(
        text: 'Send Reset Link',
        onPressed: onPressed,
        isLoading: isLoading,
      ),
    );
  }
}