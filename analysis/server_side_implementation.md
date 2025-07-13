# Server-Side Subscription Implementation Guide

## Overview
This document details the complete server-side infrastructure needed to support account-based subscriptions with RevenueCat webhooks.

## 1. Database Schema Implementation

### 1.1 PowerSync-Driven Approach

With the PowerSync-driven approach, subscription data is stored directly in Supabase `auth.users` user metadata. An optional audit table has been added to `/Users/matt/repos/flutter_test_2/ddls/postgres_powersync.sql` for subscription events.

### 1.2 User Metadata Structure

Subscription data is stored in `auth.users.user_metadata` with this structure:

```json
{
  "subscription": {
    "status": "active",           // active, cancelled, expired, trial, none
    "entitlements": ["plus"],     // array of entitlement IDs
    "expires_at": "2024-02-15T10:30:00Z",
    "trial_ends_at": null,
    "product_id": "stockpot_plus_monthly",
    "store": "app_store",         // app_store, play_store, stripe
    "revenuecat_customer_id": "customer_123",
    "last_updated": "2024-01-15T10:30:00Z"
  }
}
```

### 1.3 Benefits of PowerSync Approach

- **No separate subscription tables needed**: Data stored in auth.users metadata
- **Automatic sync**: PowerSync handles all client synchronization
- **Offline access**: Subscription status available offline via PowerSync
- **Real-time updates**: Changes propagate automatically to all client devices
- **Simple architecture**: Single source of truth in user metadata
- **Household integration ready**: Existing household system can be enhanced with subscription triggers

## 2. Recipe App Server Implementation

### 2.1 RevenueCat Webhook Controller

**File**: `/users/matt/repos/recipe_app_server/src/controllers/webhookController.ts`

```typescript
import { Request, Response } from 'express'
import { createClient } from '@supabase/supabase-js'

interface RevenueCatWebhookEvent {
  api_version: string;
  event: {
    id: string;
    event_timestamp_ms: number;
    product_id: string;
    period_type: 'TRIAL' | 'INTRO' | 'NORMAL';
    purchased_at_ms: number;
    expiration_at_ms?: number;
    environment: 'SANDBOX' | 'PRODUCTION';
    entitlement_id: string;
    entitlement_ids: string[];
    presented_offering_identifier?: string;
    transaction_id: string;
    original_transaction_id: string;
    is_family_share: boolean;
    country_code: string;
    app_user_id: string;
    aliases: string[];
    original_app_user_id: string;
    type: 'INITIAL_PURCHASE' | 'RENEWAL' | 'PRODUCT_CHANGE' | 'CANCELLATION' | 'BILLING_ISSUE' | 'SUBSCRIBER_ALIAS' | 'SUBSCRIPTION_PAUSED' | 'TRANSFER' | 'EXPIRATION' | 'UNCANCELLATION';
    takehome_percentage: number;
    offer_code?: string;
    store: 'APP_STORE' | 'MAC_APP_STORE' | 'PLAY_STORE' | 'STRIPE' | 'PROMOTIONAL';
    price_in_purchased_currency?: number;
    subscriber_attributes?: Record<string, any>;
    currency?: string;
  };
}

const supabase = createClient(
  process.env.SUPABASE_URL!,
  process.env.SUPABASE_SERVICE_ROLE_KEY!
)

export class WebhookController {
  async revenueCatWebhook(req: Request, res: Response) {
    try {
      // Verify webhook signature
      const signature = req.headers.authorization
      if (!signature || !await verifyWebhookSignature(req, signature)) {
        return res.status(401).json({ error: 'Unauthorized' })
      }

      const payload: RevenueCatWebhookEvent = req.body
      console.log('Processing RevenueCat webhook:', payload.event.type, payload.event.app_user_id)

      // Process the webhook event
      await processSubscriptionEvent(payload)

      return res.json({ success: true })
    } catch (error) {
      console.error('Webhook processing error:', error)
      return res.status(500).json({ error: error.message })
    }
  }
}

async function verifyWebhookSignature(req: Request, signature: string): Promise<boolean> {
  // Implement webhook signature verification
  // RevenueCat sends Authorization header with Bearer token
  const expectedToken = process.env.REVENUECAT_WEBHOOK_SECRET
  return signature === `Bearer ${expectedToken}`
}

async function processSubscriptionEvent(payload: RevenueCatWebhookEvent) {
  const { event } = payload
  
  // Log the raw event first
  await logSubscriptionEvent(event)

  // Process based on event type
  switch (event.type) {
    case 'INITIAL_PURCHASE':
    case 'RENEWAL':
    case 'UNCANCELLATION':
      await handleSubscriptionActivation(event)
      break
      
    case 'CANCELLATION':
      await handleSubscriptionCancellation(event)
      break
      
    case 'EXPIRATION':
      await handleSubscriptionExpiration(event)
      break
      
    case 'BILLING_ISSUE':
      await handleBillingIssue(event)
      break
      
    case 'PRODUCT_CHANGE':
      await handleProductChange(event)
      break
      
    default:
      console.log(`Unhandled event type: ${event.type}`)
  }
}

async function handleSubscriptionActivation(event: any) {
  const subscriptionData = {
    status: 'active',
    entitlements: event.entitlement_ids,
    expires_at: event.expiration_at_ms ? new Date(event.expiration_at_ms).toISOString() : null,
    trial_ends_at: event.period_type === 'TRIAL' && event.expiration_at_ms 
      ? new Date(event.expiration_at_ms).toISOString() 
      : null,
    product_id: event.product_id,
    store: mapStoreString(event.store),
    revenuecat_customer_id: event.aliases?.[0] || event.app_user_id,
    last_updated: new Date().toISOString()
  }

  // Update user metadata in Supabase auth.users
  const { error } = await supabase.auth.admin.updateUserById(event.app_user_id, {
    user_metadata: {
      subscription: subscriptionData
    }
  })

  if (error) {
    throw new Error(`Failed to update user metadata: ${error.message}`)
  }

  console.log(`Activated subscription for user ${event.app_user_id}`)
}

async function handleSubscriptionCancellation(event: any) {
  const subscriptionData = {
    status: 'cancelled',
    entitlements: event.entitlement_ids || [],
    expires_at: event.expiration_at_ms ? new Date(event.expiration_at_ms).toISOString() : null,
    cancelled_at: new Date().toISOString(),
    product_id: event.product_id,
    store: mapStoreString(event.store),
    revenuecat_customer_id: event.aliases?.[0] || event.app_user_id,
    last_updated: new Date().toISOString()
  }

  // Update user metadata in Supabase auth.users
  const { error } = await supabase.auth.admin.updateUserById(event.app_user_id, {
    user_metadata: {
      subscription: subscriptionData
    }
  })

  if (error) {
    throw new Error(`Failed to update user metadata: ${error.message}`)
  }

  console.log(`Cancelled subscription for user ${event.app_user_id}`)
}

async function handleSubscriptionExpiration(event: any) {
  const subscriptionData = {
    status: 'expired',
    entitlements: [],
    expires_at: event.expiration_at_ms ? new Date(event.expiration_at_ms).toISOString() : null,
    product_id: event.product_id,
    store: mapStoreString(event.store),
    revenuecat_customer_id: event.aliases?.[0] || event.app_user_id,
    last_updated: new Date().toISOString()
  }

  // Update user metadata in Supabase auth.users
  const { error } = await supabase.auth.admin.updateUserById(event.app_user_id, {
    user_metadata: {
      subscription: subscriptionData
    }
  })

  if (error) {
    throw new Error(`Failed to update user metadata: ${error.message}`)
  }

  console.log(`Expired subscription for user ${event.app_user_id}`)
}

async function handleBillingIssue(event: any) {
  const subscriptionData = {
    status: 'billing_retry',
    entitlements: event.entitlement_ids || [],
    expires_at: event.expiration_at_ms ? new Date(event.expiration_at_ms).toISOString() : null,
    product_id: event.product_id,
    store: mapStoreString(event.store),
    revenuecat_customer_id: event.aliases?.[0] || event.app_user_id,
    last_updated: new Date().toISOString()
  }

  // Update user metadata in Supabase auth.users
  const { error } = await supabase.auth.admin.updateUserById(event.app_user_id, {
    user_metadata: {
      subscription: subscriptionData
    }
  })

  if (error) {
    throw new Error(`Failed to update user metadata: ${error.message}`)
  }

  console.log(`Billing issue for user ${event.app_user_id}`)
}

async function handleProductChange(event: any) {
  const subscriptionData = {
    status: 'active',
    entitlements: event.entitlement_ids,
    expires_at: event.expiration_at_ms ? new Date(event.expiration_at_ms).toISOString() : null,
    product_id: event.product_id,
    store: mapStoreString(event.store),
    revenuecat_customer_id: event.aliases?.[0] || event.app_user_id,
    last_updated: new Date().toISOString()
  }

  // Update user metadata in Supabase auth.users
  const { error } = await supabase.auth.admin.updateUserById(event.app_user_id, {
    user_metadata: {
      subscription: subscriptionData
    }
  })

  if (error) {
    throw new Error(`Failed to update user metadata: ${error.message}`)
  }

  console.log(`Product changed for user ${event.app_user_id}`)
}

async function logSubscriptionEvent(event: any) {
  const eventData = {
    user_id: event.app_user_id,
    event_type: event.type.toLowerCase(),
    event_source: 'revenuecat_webhook',
    revenuecat_event_id: event.id,
    product_id: event.product_id,
    transaction_id: event.transaction_id,
    original_transaction_id: event.original_transaction_id,
    price_in_cents: event.price_in_purchased_currency ? Math.round(event.price_in_purchased_currency * 100) : null,
    currency: event.currency,
    platform: mapPlatformString(event.store),
    store: mapStoreString(event.store),
    expires_at: event.expiration_at_ms ? new Date(event.expiration_at_ms) : null,
    purchased_at: new Date(event.purchased_at_ms),
    raw_webhook_data: event
  }

  const { error } = await supabase
    .from('subscription_events')
    .insert(eventData)

  if (error) {
    console.error('Failed to log subscription event:', error)
    // Don't throw - logging failure shouldn't break webhook processing
  }
}

function mapStoreString(store: string): string {
  switch (store) {
    case 'APP_STORE':
    case 'MAC_APP_STORE':
      return 'app_store'
    case 'PLAY_STORE':
      return 'play_store'
    case 'STRIPE':
      return 'stripe'
    default:
      return store.toLowerCase()
  }
}

function mapPlatformString(store: string): string {
  switch (store) {
    case 'APP_STORE':
    case 'MAC_APP_STORE':
      return 'ios'
    case 'PLAY_STORE':
      return 'android'
    case 'STRIPE':
      return 'web'
    default:
      return 'unknown'
  }
}
```

### 2.2 Webhook Routes Setup

**File**: `/users/matt/repos/recipe_app_server/src/routes/webhookRoutes.ts`

```typescript
import express from 'express'
import { WebhookController } from '../controllers/webhookController'

const router = express.Router()
const webhookController = new WebhookController()

// RevenueCat webhook endpoint
router.post('/revenuecat', webhookController.revenueCatWebhook.bind(webhookController))

export default router
```

**Update main app** (in `/users/matt/repos/recipe_app_server/src/index.ts`):

```typescript
import webhookRoutes from './routes/webhookRoutes'

// Add webhook routes (no auth required for webhooks)
app.use('/v1/webhooks', webhookRoutes)
```

### 2.3 PowerSync Integration

With the PowerSync-driven approach, **no additional subscription status API is needed**. PowerSync automatically syncs user metadata changes to the client, eliminating the need for custom subscription APIs.

The RevenueCat webhook updates Supabase `auth.users` metadata, and PowerSync handles the rest automatically.

## 3. Environment Configuration

### 3.1 Required Environment Variables

**Add to recipe_app_server environment:**

```bash
# RevenueCat webhook secret
REVENUECAT_WEBHOOK_SECRET=your_webhook_secret_here

# Supabase (auto-provided)
SUPABASE_URL=your_project_url
SUPABASE_ANON_KEY=your_anon_key
SUPABASE_SERVICE_ROLE_KEY=your_service_role_key
```

### 3.2 RevenueCat Webhook Configuration

In RevenueCat dashboard:
1. Go to Integrations → Webhooks
2. Add webhook URL: `https://your-recipe-app-server.com/v1/webhooks/revenuecat`
3. Set webhook secret (save in environment variables)
4. Enable all relevant events:
   - Initial Purchase
   - Renewal
   - Cancellation
   - Billing Issue
   - Product Change
   - Expiration

## 4. Testing Strategy

### 4.1 Webhook Testing

```typescript
// Test script for webhook endpoint
const testWebhook = async () => {
  const testEvent = {
    api_version: "1.0",
    event: {
      id: "test-event-id",
      event_timestamp_ms: Date.now(),
      product_id: "stockpot_plus_monthly",
      period_type: "NORMAL",
      purchased_at_ms: Date.now(),
      expiration_at_ms: Date.now() + (30 * 24 * 60 * 60 * 1000), // 30 days
      environment: "SANDBOX",
      entitlement_id: "plus",
      entitlement_ids: ["plus"],
      transaction_id: "test-transaction",
      original_transaction_id: "test-original-transaction",
      is_family_share: false,
      country_code: "US",
      app_user_id: "test-user-id",
      aliases: ["test-customer-id"],
      original_app_user_id: "test-user-id",
      type: "INITIAL_PURCHASE",
      takehome_percentage: 0.7,
      store: "APP_STORE",
      price_in_purchased_currency: 9.99,
      currency: "USD"
    }
  }

  const response = await fetch('http://localhost:3000/v1/webhooks/revenuecat', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${process.env.REVENUECAT_WEBHOOK_SECRET}`,
      'Content-Type': 'application/json'
    },
    body: JSON.stringify(testEvent)
  })

  console.log('Webhook test response:', await response.json())
}
```

### 4.2 Database Testing

```sql
-- Test queries for PowerSync-driven subscription system
-- Check user metadata (subscription stored here)
select 
  id, 
  email,
  user_metadata->'subscription' as subscription_data
from auth.users 
where id = 'test-user-id';

-- Check subscription events
select * from subscription_events 
where user_id = 'test-user-id' 
order by processed_at desc;

-- Check if user has active subscription from metadata
select 
  id,
  email,
  (user_metadata->'subscription'->>'status') as subscription_status,
  (user_metadata->'subscription'->'entitlements') as entitlements,
  (user_metadata->'subscription'->>'expires_at') as expires_at
from auth.users 
where id = 'test-user-id';
```

This server-side implementation provides a robust foundation for account-based subscriptions with proper audit trails, webhook processing, and cross-platform support.