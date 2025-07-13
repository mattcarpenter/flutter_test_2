// auth_page.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../mobile/utils/adaptive_sliver_page.dart';
import '../../../utils/feature_flags.dart';

class AuthSubPage extends StatefulWidget {
  const AuthSubPage({super.key});

  @override
  _AuthSubPageState createState() => _AuthSubPageState();
}

class _AuthSubPageState extends State<AuthSubPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _signIn() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await Supabase.instance.client.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      //final userRepository = ProviderScope.containerOf(context).read(userRepositoryProvider);
      //await userRepository.getUser(Supabase.instance.client.auth.currentUser!.id);

      setState(() {
        _isLoading = false;
      });

      _showAlert('Sign in successful'); // ✅ Show success alert
    } on AuthException catch (e) {
      _showAlert(e.message); // ✅ Show error alert
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// ✅ Helper method to show an alert dialog
  void _showAlert(String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) {
        return CupertinoAlertDialog(
          title: const Text('Authentication'),
          content: Text(message),
          actions: [
            CupertinoDialogAction(
              isDefaultAction: true,
              child: const Text('OK'),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AdaptiveSliverPage(
      title: 'Auth',
      body: FeatureGate(
        feature: 'labs',
        customUpgradeText: 'Upgrade to access Labs',
        child: Center(
          child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                CupertinoTextField(
                  controller: _emailController,
                  placeholder: 'Email', // ✅ Acts as the labelText
                  padding: const EdgeInsets.all(12.0), // ✅ Adds padding like Material
                ),

                const SizedBox(height: 12),
                CupertinoTextField(
                  controller: _passwordController,
                  placeholder: 'Email', // ✅ Acts as the labelText
                  padding: const EdgeInsets.all(12.0), // ✅ Adds padding like Material
                  obscureText: true,
                ),
                const SizedBox(height: 20),
                CupertinoButton(
                  onPressed: _isLoading ? null : _signIn,
                  child: _isLoading
                      ? const CircularProgressIndicator()
                      : const Text('Sign In'),
                ),
              ],
            ),
          ),
        ),
      trailing: const Icon(CupertinoIcons.add_circled),
      previousPageTitle: 'Labs',
      automaticallyImplyLeading: true,
    );

  }
}
