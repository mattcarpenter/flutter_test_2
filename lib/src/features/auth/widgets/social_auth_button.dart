import 'dart:io' show Platform;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:sign_in_button/sign_in_button.dart';

class SocialAuthButton extends StatelessWidget {
  final String provider;
  final String? label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool enabled;

  const SocialAuthButton({
    super.key,
    required this.provider,
    this.label,
    this.onPressed,
    this.isLoading = false,
    this.enabled = true,
  });

  Widget _buildGoogleIcon() {
    // Using a simple icon for now - in production you'd use the actual Google logo
    return Icon(
      Icons.account_circle,
      size: 20,
      color: enabled ? Colors.red : Colors.grey,
    );
  }

  Widget _buildIcon() {
    switch (provider.toLowerCase()) {
      case 'google':
        return _buildGoogleIcon();
      default:
        return Icon(
          Icons.login,
          size: 20,
          color: enabled ? Colors.blue : Colors.grey,
        );
    }
  }

  String _getDefaultLabel() {
    switch (provider.toLowerCase()) {
      case 'google':
        return 'Continue with Google';
      default:
        return 'Continue with $provider';
    }
  }

  @override
  Widget build(BuildContext context) {
    final buttonLabel = label ?? _getDefaultLabel();
    final canPress = enabled && !isLoading && onPressed != null;

    if (Platform.isIOS) {
      return _buildCupertinoButton(buttonLabel, canPress);
    } else {
      return _buildMaterialButton(buttonLabel, canPress);
    }
  }

  Widget _buildCupertinoButton(String buttonLabel, bool canPress) {
    return CupertinoButton(
      onPressed: canPress ? onPressed : null,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      color: CupertinoColors.white,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: CupertinoColors.systemGrey3),
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isLoading)
              const CupertinoActivityIndicator()
            else
              _buildIcon(),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                buttonLabel,
                style: TextStyle(
                  color: enabled
                      ? CupertinoColors.black
                      : CupertinoColors.inactiveGray,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMaterialButton(String buttonLabel, bool canPress) {
    return OutlinedButton(
      onPressed: canPress ? onPressed : null,
      style: OutlinedButton.styleFrom(
        backgroundColor: Colors.white,
        side: BorderSide(
          color: enabled ? Colors.grey[300]! : Colors.grey[200]!,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (isLoading)
            const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            _buildIcon(),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              buttonLabel,
              style: TextStyle(
                color: enabled ? Colors.black87 : Colors.grey,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

// Specific Google Sign-In button with official Google styling
class GoogleSignInButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isLoading;
  final String? customLabel;

  const GoogleSignInButton({
    super.key,
    this.onPressed,
    this.isLoading = false,
    this.customLabel,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !isLoading;
    
    if (isLoading) {
      return Container(
        height: 50,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Center(
          child: SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    return SizedBox(
      height: 50,
      width: double.infinity,
      child: SignInButton(
        Buttons.google,
        text: customLabel ?? "Sign in with Google",
        onPressed: enabled && onPressed != null ? onPressed! as dynamic : null,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }
}

// Apple Sign-In button for iOS
class AppleSignInButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isLoading;
  final String? customLabel;

  const AppleSignInButton({
    super.key,
    this.onPressed,
    this.isLoading = false,
    this.customLabel,
  });

  @override
  Widget build(BuildContext context) {
    // Only show on iOS
    if (!Platform.isIOS) {
      return const SizedBox.shrink();
    }

    final enabled = onPressed != null && !isLoading;
    
    if (isLoading) {
      return Container(
        height: 50,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Center(
          child: SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: 50,
      width: double.infinity,
      child: SignInButton(
        Buttons.apple,
        text: customLabel ?? "Sign in with Apple",
        onPressed: enabled && onPressed != null ? onPressed! as dynamic : null,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }
}