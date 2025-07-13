# Account-Based Subscription Implementation Checklist

## Implementation Overview
Simple PowerSync-driven subscription system with RevenueCat webhooks updating Supabase user metadata.

## Server-Side Tasks

### 1. RevenueCat Webhook Handler
- [ ] Create `/users/matt/repos/recipe_app_server/src/controllers/webhookController.ts`
- [ ] Create `/users/matt/repos/recipe_app_server/src/routes/webhookRoutes.ts`
- [ ] Add webhook routes to `/users/matt/repos/recipe_app_server/src/index.ts`
- [ ] Implement webhook signature verification
- [ ] Process subscription events (purchase, renewal, cancellation, expiration)
- [ ] Update Supabase auth.users metadata with subscription status
- [ ] Handle all RevenueCat event types properly
- [ ] Add error handling and logging

### 2. Optional: Subscription Events Audit Table
- [ ] Run the DDL from `/Users/matt/repos/flutter_test_2/ddls/postgres_powersync.sql` (subscription_events table already added)
- [ ] Implement event logging in webhook handler

### 3. Environment Configuration
- [ ] Add REVENUECAT_WEBHOOK_SECRET to recipe_app_server environment
- [ ] Configure RevenueCat webhook URL in dashboard
- [ ] Set up webhook event types in RevenueCat

## Client-Side Tasks

### 4. Subscription Service Updates
- [ ] Update `lib/src/services/subscription_service.dart`:
  - [ ] Simplify hasPlus() to read from user metadata
  - [ ] Add getSubscriptionMetadata() method
  - [ ] Remove complex API client logic
  - [ ] Keep existing RevenueCat methods (presentPaywall, restore, etc.)

### 5. Subscription Provider Updates  
- [ ] Update `lib/src/providers/subscription_provider.dart`:
  - [ ] Simplify to read from local user metadata
  - [ ] Listen to auth state changes to update subscription
  - [ ] Remove complex API calls and caching
  - [ ] Keep UI state management (loading, errors)

### 6. Subscription State Model
- [ ] Update `lib/src/models/subscription_state.dart`:
  - [ ] Add subscriptionMetadata field
  - [ ] Add computed properties for status, entitlements, expiry
  - [ ] Add trial and cancellation helper methods

### 7. Feature Flags Updates
- [ ] Update `lib/src/utils/feature_flags.dart`:
  - [ ] Ensure FeatureFlags.hasFeatureSync works with new state
  - [ ] Update PremiumBadge to use new subscription state
  - [ ] Keep existing feature gate logic

## Testing Tasks

### 8. Webhook Testing
- [ ] Create webhook test script
- [ ] Test all subscription event types
- [ ] Verify user metadata updates correctly
- [ ] Test webhook signature verification

### 9. Client Integration Testing
- [ ] Test subscription status reads correctly from metadata
- [ ] Test paywall flow updates metadata via webhook
- [ ] Test restore purchases functionality
- [ ] Test offline subscription status access
- [ ] Verify PowerSync syncs user metadata changes

### 10. Edge Case Testing
- [ ] Test user sign out/sign in maintains subscription
- [ ] Test multiple devices with same account
- [ ] Test subscription expiration scenarios
- [ ] Test webhook retry/failure scenarios

## Configuration Tasks

### 11. RevenueCat Dashboard Configuration
- [ ] Set webhook URL to recipe_app_server endpoint: `/v1/webhooks/revenuecat`
- [ ] Configure webhook events (purchase, renewal, cancellation, etc.)
- [ ] Set webhook authentication secret
- [ ] Test webhook delivery

### 12. Server Configuration
- [ ] Deploy recipe_app_server with webhook endpoints
- [ ] Set environment variables (REVENUECAT_WEBHOOK_SECRET, SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY)
- [ ] Test webhook endpoint accessibility
- [ ] Verify PowerSync has access to user metadata

## Verification Tasks

### 13. End-to-End Flow Testing
- [ ] User purchases subscription → webhook updates metadata → client shows access
- [ ] User cancels subscription → webhook updates metadata → client respects cancellation
- [ ] User restores purchases → subscription status updates correctly
- [ ] Offline mode works with cached user metadata

### 14. Cross-Platform Preparation
- [ ] Verify user metadata syncs work identically on iOS/Android
- [ ] Test that same Supabase user ID works across platforms
- [ ] Confirm RevenueCat user ID sync works for cross-platform

### 15. Household Integration Preparation
- [ ] Plan household subscription triggers
- [ ] Design household subscription inheritance from existing system

## Success Criteria

- ✅ Purchase on iOS updates Supabase user metadata within 30 seconds
- ✅ Client subscription status updates automatically via PowerSync
- ✅ Subscription status available offline from local data
- ✅ Cross-platform: same account works on multiple platforms
- ✅ Webhook handles all subscription lifecycle events correctly
- ✅ No client-side subscription API calls needed
- ✅ Household subscription integration ready

## Implementation Order

1. **Server webhook** (tasks 1-3)
2. **Client updates** (tasks 4-7) 
3. **Integration testing** (tasks 8-10)
4. **Configuration** (tasks 11-12)
5. **End-to-end verification** (tasks 13-15)

This checklist focuses on implementable technical tasks without human coordination or timeline dependencies.