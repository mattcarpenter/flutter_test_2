# Webhook Testing Setup Guide

This guide covers the steps needed to test the RevenueCat webhook implementation with the PowerSync-driven subscription system.

## 1. Database Setup

### Create Subscription Events Table
Run this SQL in your Supabase SQL editor:

```sql
-- Create subscription_events table for webhook logging
CREATE TABLE public.subscription_events (
    id uuid NOT NULL DEFAULT extensions.uuid_generate_v4(),
    user_id uuid NULL,
    event_type text NOT NULL,
    event_source text NOT NULL DEFAULT 'revenuecat_webhook',
    event_data jsonb NOT NULL,
    revenuecat_event_id text NULL,
    product_id text NULL,
    transaction_id text NULL,
    original_transaction_id text NULL,
    price_in_cents integer NULL,
    currency text NULL,
    platform text NULL,
    store text NULL,
    expires_at timestamp with time zone NULL,
    purchased_at timestamp with time zone NULL,
    raw_webhook_data jsonb NULL,
    processed_at timestamp with time zone NULL,
    created_at timestamp with time zone NOT NULL DEFAULT now(),
    CONSTRAINT subscription_events_pkey PRIMARY KEY (id)
);

-- Add foreign key constraint to auth.users
ALTER TABLE public.subscription_events 
ADD CONSTRAINT subscription_events_user_id_fkey 
FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;

-- Add index for efficient querying
CREATE INDEX idx_subscription_events_user_id ON public.subscription_events(user_id);
CREATE INDEX idx_subscription_events_event_type ON public.subscription_events(event_type);
CREATE INDEX idx_subscription_events_created_at ON public.subscription_events(created_at);

-- Add RLS policies
ALTER TABLE public.subscription_events ENABLE ROW LEVEL SECURITY;

-- Policy: Users can view their own subscription events
CREATE POLICY "Users can view own subscription events" ON public.subscription_events
    FOR SELECT USING (auth.uid() = user_id);

-- Policy: Service role can insert/update subscription events (for webhooks)
CREATE POLICY "Service role can manage subscription events" ON public.subscription_events
    FOR ALL USING (auth.role() = 'service_role');
```

## 2. Local Development Setup

### Set up ngrok for webhook testing
1. Install ngrok: `brew install ngrok` (macOS) or download from https://ngrok.com/
2. Sign up for ngrok account and get auth token
3. Configure ngrok: `ngrok config add-authtoken YOUR_AUTH_TOKEN`
4. Start local recipe_app_server: `npm run dev` (default port 3000)
5. In separate terminal, expose local server: `ngrok http 3000`
6. Note the public HTTPS URL (e.g., `https://abc123.ngrok.io`)

### Configure Environment Variables
Update your recipe_app_server `.env` file:
```bash
# Add RevenueCat webhook secret (get from RevenueCat dashboard)
REVENUECAT_WEBHOOK_SECRET=your_webhook_secret_here

# Ensure Supabase config is correct
SUPABASE_URL=your_supabase_url
SUPABASE_SERVICE_ROLE_KEY=your_service_role_key
```

## 3. RevenueCat Dashboard Configuration

### Configure Webhook URL
1. Go to RevenueCat dashboard → Project Settings → Webhooks
2. Add new webhook with URL: `https://YOUR_NGROK_URL.ngrok.io/v1/webhooks/revenuecat`
3. Select events to send:
   - `INITIAL_PURCHASE`
   - `RENEWAL`
   - `CANCELLATION`
   - `EXPIRATION`
   - `BILLING_ISSUE`
   - `PRODUCT_CHANGE`
   - `TRANSFER`
4. Save the webhook configuration
5. Copy the webhook secret and add to your `.env` file

### Test Configuration
1. Use RevenueCat's "Test Webhook" feature to send a sample event
2. Check your server logs to confirm webhook is received
3. Check Supabase `subscription_events` table for logged events

## 4. Flutter App Testing

### Configure RevenueCat in Flutter
Ensure your app is using the correct API keys:
```dart
// In subscription_service.dart, verify:
static const String _apiKey = 'appl_SPuDBCvjoalGuumyxdYEfRZKEXt';
static const String _entitlementId = 'plus';
```

### Test Purchase Flow
1. Run app on iOS Simulator with StoreKit Configuration file
2. Create test user account in app
3. Navigate to Labs (should show paywall)
4. Complete test purchase
5. Check that webhook is triggered
6. Verify user metadata is updated in Supabase
7. Verify PowerSync syncs the updated metadata
8. Confirm Labs access is granted

## 5. Debugging Steps

### Server-Side Debugging
1. Check server logs for webhook reception
2. Verify webhook signature validation
3. Check Supabase user metadata updates
4. Review `subscription_events` table entries

### Client-Side Debugging
1. Check PowerSync sync status
2. Verify user metadata in `_subscriptionService.getSubscriptionMetadata()`
3. Test `hasPlus()` method returns correct value
4. Check subscription provider state updates

### Common Issues
- **Webhook not received**: Check ngrok URL and RevenueCat configuration
- **Signature validation fails**: Verify webhook secret matches
- **User not found**: Ensure RevenueCat app_user_id matches Supabase user ID
- **PowerSync not syncing**: Check PowerSync connection and sync rules

## 6. Production Deployment

### Before Production
1. Replace ngrok URL with production webhook endpoint
2. Update RevenueCat webhook configuration
3. Ensure production environment variables are set
4. Test with RevenueCat production API keys
5. Monitor webhook delivery and processing

### Monitoring
- Set up logging for webhook events
- Monitor `subscription_events` table growth
- Track PowerSync sync performance
- Monitor subscription state accuracy across devices

## 7. Additional Testing Scenarios

### Edge Cases to Test
1. Purchase while offline → sync when online
2. Multiple device subscription sync
3. Subscription cancellation flow
4. Billing issue handling
5. Product upgrade/downgrade
6. Restore purchases functionality

### Load Testing
1. Multiple concurrent webhook deliveries
2. Large user base subscription updates
3. PowerSync sync performance under load