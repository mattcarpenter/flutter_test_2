# RevenueCat Implementation Checklist

## Configuration Requirements

### RevenueCat Setup
- **API Key**: `appl_SPuDBCvjoalGuumyxdYEfRZKEXt`
- **Entitlement ID**: `plus`
- **Subscription**: Stockpot Plus (monthly)

### Key Implementation Notes
- Using RevenueCat built-in paywalls exclusively
- Family Sharing handled automatically by RevenueCat
- No custom paywall UI components needed

## Core Implementation

### Dependencies & Configuration
- [ ] Add `purchases_flutter: ^9.0.0-beta.1` to pubspec.yaml
- [ ] Add `purchases_ui_flutter: ^9.0.0-beta.1` to pubspec.yaml
- [ ] Add RevenueCat API key `appl_SPuDBCvjoalGuumyxdYEfRZKEXt` to iOS Info.plist
- [ ] Add RevenueCat API key to Android manifest

### Core Service Implementation
- [ ] Create `lib/src/services/subscription_service.dart`
- [ ] Implement RevenueCat initialization with API key
- [ ] Add `hasPlus()` entitlement checking method
- [ ] Add `presentPaywall()` and `presentPaywallIfNeeded()` methods
- [ ] Add error handling and user ID synchronization

### Data Models
- [ ] Create `lib/src/models/subscription_state.dart`
- [ ] Define SubscriptionState with `hasPlus` field
- [ ] Add freezed annotations for immutability

### Riverpod Integration
- [ ] Create `lib/src/providers/subscription_provider.dart`
- [ ] Implement SubscriptionNotifier with auth integration
- [ ] Add convenience providers (`hasPlusProvider`)
- [ ] Add subscription state listeners

### Route Guard Implementation
- [ ] Update `lib/src/mobile/adaptive_app.dart`
- [ ] Add subscription check to `/labs` route redirect
- [ ] Use direct `RevenueCatUI.presentPaywallIfNeeded('plus')` calls
- [ ] Remove custom paywall routes (not needed)
- [ ] Test route protection works correctly

### Menu Integration
- [ ] Update `lib/src/widgets/menu/menu.dart`
- [ ] Add Stockpot Plus status indicator to Labs menu item
- [ ] Show lock/unlock icons based on `plus` subscription
- [ ] Add premium badge or visual indicator

### Feature Flag System
- [ ] Create `lib/src/utils/feature_flags.dart`
- [ ] Implement simple entitlement checking utilities
- [ ] Add `hasFeature()` method for easy gating
- [ ] Create reusable feature gate widgets

### Testing & Validation
- [ ] Create unit tests for SubscriptionService
- [ ] Test direct RevenueCat paywall presentation
- [ ] Test sandbox purchase flows
- [ ] Test Family Sharing scenarios
- [ ] Test offline entitlement caching
- [ ] Validate error handling scenarios

## Testing Scenarios

### Core Testing
- [ ] User purchases Stockpot Plus successfully via RevenueCat paywall
- [ ] User gets immediate access to Labs features
- [ ] Family Sharing works automatically
- [ ] Subscription state updates in real-time
- [ ] Offline entitlement checking works properly

### Edge Cases
- [ ] Network failure during entitlement check
- [ ] RevenueCat paywall cancellation handling
- [ ] Multiple device subscription sync
- [ ] Auth state changes with active subscription

## Key Files to Create/Modify

### New Files
- `lib/src/services/subscription_service.dart`
- `lib/src/providers/subscription_provider.dart`
- `lib/src/models/subscription_state.dart`
- `lib/src/utils/feature_flags.dart`
- `lib/src/widgets/subscription_gate.dart`
- `test/unit/subscription_service_test.dart`

### Modified Files
- `pubspec.yaml` (dependencies)
- `lib/src/mobile/adaptive_app.dart` (route guards)
- `lib/src/widgets/menu/menu.dart` (menu integration)
- `ios/Runner/Info.plist` (iOS configuration)
- `android/app/src/main/AndroidManifest.xml` (Android configuration)

## Success Criteria

- [ ] Labs features are properly protected behind `plus` subscription
- [ ] RevenueCat paywall presents smoothly via direct calls
- [ ] Family Sharing works automatically without additional code
- [ ] Subscription state updates immediately after purchase
- [ ] Feature flag system provides easy gating for future premium features
- [ ] App performance is not impacted by subscription checks
- [ ] User experience feels natural with RevenueCat's proven UI

This simplified checklist focuses on the core RevenueCat integration using built-in paywall functionality.