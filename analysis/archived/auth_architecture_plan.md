# Supabase Auth Architecture Plan

## Overview

This document outlines the comprehensive plan for implementing production-ready Supabase authentication in the Flutter Recipe App. The implementation will support both email/password and Google Sign-In authentication methods while keeping the existing auth sub page intact for testing purposes.

## Current State Analysis

### Existing Auth Implementation
- **Location**: `/lib/src/features/labs/views/auth_sub_page.dart`
- **Route**: `/labs/auth`
- **Features**: Basic email/password sign-in only
- **Missing**: Sign-up, Google Sign-In, password reset, proper error handling, loading states

### Existing Infrastructure
- **Supabase Client**: Already initialized in `powersync.dart` and `supabase.dart`
- **User Provider**: Exists in `/lib/src/providers/user_provider.dart`
- **Routing**: GoRouter with shell routing for navigation
- **Adaptive UI**: Platform-specific UI components already in use

## Authentication Methods

### 1. Email/Password Authentication
- **Sign Up**: New user registration with email verification
- **Sign In**: Existing user authentication
- **Password Reset**: Forgot password flow
- **Email Verification**: Confirm email address for new accounts

### 2. Google Sign-In
- **OAuth Flow**: Using Supabase's built-in Google OAuth provider
- **Single Tap**: One-tap sign-in/sign-up experience
- **Account Linking**: Handle existing accounts with same email

## UX Flow Design

### Authentication Flow States
1. **Unauthenticated State**
   - Landing screen with sign-in/sign-up options
   - Clear CTAs for email or Google authentication
   
2. **Sign-In Flow**
   - Email/password form
   - "Forgot Password?" link
   - "Sign in with Google" button
   - "Don't have an account? Sign up" link
   
3. **Sign-Up Flow**
   - Email/password form with confirmation
   - Terms of Service acceptance
   - "Sign up with Google" button
   - "Already have an account? Sign in" link
   
4. **Password Reset Flow**
   - Email input for reset link
   - Success state with instructions
   - Link to return to sign-in

### Screen Transitions
```
AuthLandingPage
├── SignInPage
│   ├── ForgotPasswordPage
│   └── (Success → App)
├── SignUpPage
│   ├── EmailVerificationPage
│   └── (Success → App)
└── GoogleAuth
    └── (Success → App)
```

## Supabase Integration

### Auth Methods Available
```dart
// Email/Password Sign Up
await supabase.auth.signUp(
  email: email,
  password: password,
  emailRedirectTo: 'io.supabase.flutterrecipeapp://login-callback/',
);

// Email/Password Sign In
await supabase.auth.signInWithPassword(
  email: email,
  password: password,
);

// Google Sign In
await supabase.auth.signInWithOAuth(
  OAuthProvider.google,
  redirectTo: 'io.supabase.flutterrecipeapp://login-callback/',
);

// Password Reset
await supabase.auth.resetPasswordForEmail(
  email,
  redirectTo: 'io.supabase.flutterrecipeapp://reset-callback/',
);

// Sign Out
await supabase.auth.signOut();
```

### Auth State Management
```dart
// Listen to auth state changes
supabase.auth.onAuthStateChange.listen((data) {
  final AuthChangeEvent event = data.event;
  final Session? session = data.session;
  
  switch (event) {
    case AuthChangeEvent.signedIn:
      // Handle sign in
    case AuthChangeEvent.signedOut:
      // Handle sign out
    case AuthChangeEvent.userUpdated:
      // Handle user updates
    case AuthChangeEvent.passwordRecovery:
      // Handle password recovery
  }
});
```

## Google Sign-In Setup Requirements

### Flutter Configuration
1. **Dependencies**: 
   - `google_sign_in` package (if needed for native implementation)
   - Already have `supabase_flutter` which includes OAuth support

2. **Platform Configuration**:
   - **iOS**: Update `Info.plist` with URL scheme
   - **Android**: Add intent filter to `AndroidManifest.xml`
   - **Web**: Configure redirect URLs

### Supabase Configuration
1. Configure Google OAuth provider in Supabase dashboard
2. Add GCP Web Client ID and Secret
3. Configure redirect URLs for mobile deep linking
4. Set up email templates for verification and password reset

## Security Considerations

### Best Practices
1. **Password Requirements**:
   - Minimum 8 characters
   - Mix of letters and numbers recommended
   - Real-time validation feedback

2. **Email Verification**:
   - Required for new sign-ups
   - Resend capability
   - Clear instructions

3. **Session Management**:
   - Secure token storage using Supabase's built-in handling
   - Automatic refresh token rotation
   - Logout clears all local data

4. **Error Handling**:
   - User-friendly error messages
   - No sensitive information exposure
   - Rate limiting awareness

## Future Paywall Integration Considerations

### Pre-Authentication Flow
```
App Launch → Auth Check → 
  ├── Authenticated → Home
  └── Unauthenticated → Auth Flow → 
      └── Post-Auth → Paywall (if applicable) → Home
```

### Post-Authentication Hooks
1. **User Metadata**: Store subscription status in user metadata
2. **Entitlements Check**: Verify user access level after auth
3. **Paywall Trigger**: Show paywall based on user status
4. **Graceful Degradation**: Allow limited access for non-subscribers

### Integration Points
- Auth completion callback for paywall presentation
- User profile enrichment with subscription data
- Deep linking support for purchase flow return

## Implementation Phases

### Phase 1: Core Auth Screens
- Create new auth feature directory structure
- Implement auth landing page
- Build sign-in and sign-up screens
- Add form validation and error handling

### Phase 2: Email Authentication
- Implement email/password sign-up
- Add email verification flow
- Build password reset functionality
- Handle auth state changes

### Phase 3: Google Sign-In
- Configure OAuth in Supabase
- Implement Google sign-in button
- Handle OAuth redirects
- Test on all platforms

### Phase 4: Polish & Edge Cases
- Add loading states and animations
- Implement proper error handling
- Add analytics events
- Handle edge cases (existing accounts, etc.)

### Phase 5: Testing & Launch
- Comprehensive testing on all platforms
- Update menu navigation
- Document the feature
- Deploy with feature flag if needed

## Success Metrics

1. **Conversion Rate**: Sign-up completion rate > 80%
2. **Error Rate**: Auth errors < 5% of attempts
3. **Time to Auth**: Average < 30 seconds
4. **Platform Parity**: Consistent experience across iOS/Android/Web