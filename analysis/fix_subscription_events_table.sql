-- Add missing columns to subscription_events table
-- Run this in Supabase SQL editor

ALTER TABLE public.subscription_events 
ADD COLUMN IF NOT EXISTS revenuecat_event_id text,
ADD COLUMN IF NOT EXISTS product_id text,
ADD COLUMN IF NOT EXISTS transaction_id text,
ADD COLUMN IF NOT EXISTS original_transaction_id text,
ADD COLUMN IF NOT EXISTS price_in_cents integer,
ADD COLUMN IF NOT EXISTS currency text,
ADD COLUMN IF NOT EXISTS platform text,
ADD COLUMN IF NOT EXISTS store text,
ADD COLUMN IF NOT EXISTS expires_at timestamp with time zone,
ADD COLUMN IF NOT EXISTS purchased_at timestamp with time zone,
ADD COLUMN IF NOT EXISTS raw_webhook_data jsonb;

-- Add indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_subscription_events_revenuecat_event_id ON public.subscription_events(revenuecat_event_id);
CREATE INDEX IF NOT EXISTS idx_subscription_events_transaction_id ON public.subscription_events(transaction_id);
CREATE INDEX IF NOT EXISTS idx_subscription_events_product_id ON public.subscription_events(product_id);
CREATE INDEX IF NOT EXISTS idx_subscription_events_store ON public.subscription_events(store);
CREATE INDEX IF NOT EXISTS idx_subscription_events_purchased_at ON public.subscription_events(purchased_at);