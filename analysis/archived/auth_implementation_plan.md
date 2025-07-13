# Supabase Auth Implementation Plan

## File Structure

```
lib/src/
├── features/auth/
│   ├── models/
│   │   ├── auth_state.dart              # Auth state model (loading, error, etc.)
│   │   └── auth_error.dart              # Custom auth error handling
│   ├── views/
│   │   ├── auth_landing_page.dart       # Main auth entry point
│   │   ├── sign_in_page.dart            # Email/password sign in
│   │   ├── sign_up_page.dart            # Email/password sign up
│   │   ├── forgot_password_page.dart    # Password reset flow
│   │   └── email_verification_page.dart # Email confirmation screen
│   └── widgets/
│       ├── auth_form_field.dart         # Reusable form input
│       ├── social_auth_button.dart      # Google sign-in button
│       ├── auth_loading_overlay.dart    # Loading states
│       └── auth_error_dialog.dart       # Error handling UI
├── providers/
│   └── auth_provider.dart               # Riverpod auth state management
└── services/
    └── auth_service.dart                # Supabase auth service wrapper
```

## Routing Updates

### New Routes in `adaptive_app.dart`
```dart
// Add to nonTabRoutes
GoRoute(
  path: '/auth',
  routes: [
    GoRoute(
      path: 'signin',
      pageBuilder: (context, state) => _platformPage(
        state: state,
        child: const SignInPage(),
      ),
    ),
    GoRoute(
      path: 'signup',
      pageBuilder: (context, state) => _platformPage(
        state: state,
        child: const SignUpPage(),
      ),
    ),
    GoRoute(
      path: 'forgot-password',
      pageBuilder: (context, state) => _platformPage(
        state: state,
        child: const ForgotPasswordPage(),
      ),
    ),
    GoRoute(
      path: 'verify-email',
      pageBuilder: (context, state) => _platformPage(
        state: state,
        child: const EmailVerificationPage(),
      ),
    ),
  ],
  pageBuilder: (context, state) => _platformPage(
    state: state,
    child: AuthLandingPage(
      onMenuPressed: () {
        _mainPageShellKey.currentState?.toggleDrawer();
      },
    ),
  ),
),
```

### Menu Update in `menu.dart`
```dart
MenuItem(
  index: 9,
  title: 'Sign In',
  icon: CupertinoIcons.person_circle,
  isActive: selectedIndex == 9,
  color: primaryColor,
  textColor: textColor,
  activeTextColor: activeTextColor,
  backgroundColor: backgroundColor,
  onTap: (_) {
    onRouteGo('/auth');
  },
),
```

## Implementation Details

### 1. Auth Service (`/lib/src/services/auth_service.dart`)
```dart
class AuthService {
  final SupabaseClient _supabase;
  
  AuthService(this._supabase);
  
  // Email/Password Sign Up
  Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    return await _supabase.auth.signUp(
      email: email,
      password: password,
      emailRedirectTo: _getRedirectUrl(),
    );
  }
  
  // Email/Password Sign In
  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) async {
    return await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }
  
  // Google Sign In
  Future<bool> signInWithGoogle() async {
    return await _supabase.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: _getRedirectUrl(),
    );
  }
  
  // Password Reset
  Future<void> resetPassword(String email) async {
    await _supabase.auth.resetPasswordForEmail(
      email,
      redirectTo: _getPasswordResetUrl(),
    );
  }
  
  // Sign Out
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }
  
  // Get current user
  User? get currentUser => _supabase.auth.currentUser;
  
  // Auth state changes
  Stream<AuthState> get authStateChanges {
    return _supabase.auth.onAuthStateChange.map((data) {
      return AuthState(
        event: data.event,
        session: data.session,
      );
    });
  }
  
  String _getRedirectUrl() {
    if (Platform.isIOS || Platform.isAndroid) {
      return 'io.supabase.flutterrecipeapp://login-callback/';
    }
    return 'http://localhost:3000/auth/callback';
  }
  
  String _getPasswordResetUrl() {
    if (Platform.isIOS || Platform.isAndroid) {
      return 'io.supabase.flutterrecipeapp://reset-callback/';
    }
    return 'http://localhost:3000/auth/reset-password';
  }
}
```

### 2. Auth Provider (`/lib/src/providers/auth_provider.dart`)
```dart
@riverpod
class Auth extends _$Auth {
  late final AuthService _authService;
  
  @override
  FutureOr<AuthState> build() async {
    _authService = AuthService(Supabase.instance.client);
    
    // Listen to auth state changes
    _authService.authStateChanges.listen((authState) {
      state = AsyncData(authState);
    });
    
    // Return initial state
    final user = _authService.currentUser;
    return AuthState(
      user: user,
      isAuthenticated: user != null,
    );
  }
  
  Future<void> signInWithEmail(String email, String password) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final response = await _authService.signInWithEmail(
        email: email,
        password: password,
      );
      return AuthState(
        user: response.user,
        isAuthenticated: true,
      );
    });
  }
  
  Future<void> signUpWithEmail(String email, String password) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final response = await _authService.signUpWithEmail(
        email: email,
        password: password,
      );
      return AuthState(
        user: response.user,
        isAuthenticated: false, // Needs email verification
        needsEmailVerification: true,
      );
    });
  }
  
  Future<void> signInWithGoogle() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await _authService.signInWithGoogle();
      // Auth state will be updated via stream
      return state.value!;
    });
  }
  
  Future<void> signOut() async {
    await _authService.signOut();
    state = const AsyncData(AuthState());
  }
}
```

### 3. Sign In Page (`/lib/src/features/auth/views/sign_in_page.dart`)
```dart
class SignInPage extends ConsumerStatefulWidget {
  const SignInPage({super.key});
  
  @override
  ConsumerState<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends ConsumerState<SignInPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    
    return AdaptiveSliverPage(
      title: 'Sign In',
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            AuthFormField(
              controller: _emailController,
              label: 'Email',
              keyboardType: TextInputType.emailAddress,
              validator: _validateEmail,
            ),
            const SizedBox(height: 16),
            AuthFormField(
              controller: _passwordController,
              label: 'Password',
              obscureText: true,
              validator: _validatePassword,
            ),
            const SizedBox(height: 24),
            CupertinoButton.filled(
              onPressed: authState.isLoading ? null : _handleSignIn,
              child: authState.isLoading
                  ? const CupertinoActivityIndicator()
                  : const Text('Sign In'),
            ),
            const SizedBox(height: 16),
            CupertinoButton(
              onPressed: () => context.go('/auth/forgot-password'),
              child: const Text('Forgot Password?'),
            ),
            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 32),
            SocialAuthButton(
              provider: 'google',
              onPressed: _handleGoogleSignIn,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("Don't have an account?"),
                CupertinoButton(
                  onPressed: () => context.go('/auth/signup'),
                  child: const Text('Sign Up'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Future<void> _handleSignIn() async {
    if (_formKey.currentState!.validate()) {
      await ref.read(authProvider.notifier).signInWithEmail(
        _emailController.text,
        _passwordController.text,
      );
      
      // Handle navigation on success
      if (mounted && ref.read(authProvider).value?.isAuthenticated == true) {
        context.go('/recipes');
      }
    }
  }
  
  Future<void> _handleGoogleSignIn() async {
    await ref.read(authProvider.notifier).signInWithGoogle();
  }
}
```

## Platform-Specific Configuration

### iOS Configuration (`ios/Runner/Info.plist`)
```xml
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>io.supabase.flutterrecipeapp</string>
    </array>
  </dict>
</array>
```

### Android Configuration (`android/app/src/main/AndroidManifest.xml`)
```xml
<intent-filter>
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.DEFAULT" />
    <category android:name="android.intent.category.BROWSABLE" />
    <data
        android:scheme="io.supabase.flutterrecipeapp"
        android:host="login-callback" />
</intent-filter>
```

## Google Sign-In Configuration Steps

### 1. Google Cloud Platform Setup
- Use existing GCP project with Web Client ID
- Add OAuth 2.0 credentials for iOS and Android
- Configure authorized redirect URIs

### 2. Supabase Dashboard Configuration
1. Navigate to Authentication > Providers
2. Enable Google provider
3. Add Client ID and Client Secret from GCP
4. Configure redirect URLs:
   - `io.supabase.flutterrecipeapp://login-callback/`
   - `http://localhost:3000/auth/callback` (for web)

### 3. iOS Additional Setup
- Add `GoogleService-Info.plist` to iOS project
- Configure URL schemes in Xcode

### 4. Android Additional Setup
- Add `google-services.json` to Android project
- Ensure SHA-1 fingerprint is added to GCP

## Testing Strategy

### Unit Tests
- Auth service methods
- Provider state management
- Form validation logic

### Integration Tests
- Complete auth flows
- Error handling scenarios
- Platform-specific behaviors

### Manual Testing Checklist
- [ ] Email sign-up with verification
- [ ] Email sign-in
- [ ] Google sign-in (iOS)
- [ ] Google sign-in (Android)
- [ ] Password reset flow
- [ ] Error states (wrong password, etc.)
- [ ] Loading states
- [ ] Deep link handling
- [ ] Session persistence
- [ ] Sign out

## Migration Plan

1. **Feature Flag**: Add auth v2 behind feature flag
2. **Parallel Development**: Keep existing auth page
3. **Testing Phase**: Internal testing with team
4. **Gradual Rollout**: Enable for % of users
5. **Full Launch**: Remove old auth page
6. **Cleanup**: Remove feature flag code