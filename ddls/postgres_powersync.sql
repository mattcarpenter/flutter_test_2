-- 1. HOUSEHOLDS (Referenced by several tables)
CREATE TABLE public.households (
                                   id uuid NOT NULL DEFAULT extensions.uuid_generate_v4(),
                                   name text NOT NULL,
                                   user_id uuid NOT NULL,
                                   CONSTRAINT households_pkey PRIMARY KEY (id),
                                   CONSTRAINT households_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users (id) ON DELETE CASCADE
) TABLESPACE pg_default;

-- 2. HOUSEHOLD MEMBERS (Depends on households)
CREATE TABLE public.household_members (
                                          id uuid NOT NULL DEFAULT extensions.uuid_generate_v4(),
                                          household_id uuid NOT NULL,
                                          user_id uuid NOT NULL,
                                          is_active integer NOT NULL DEFAULT 1,
                                          role text NOT NULL DEFAULT 'member',
                                          joined_at bigint NOT NULL,
                                          updated_at bigint NULL,
                                          CONSTRAINT household_members_pkey PRIMARY KEY (household_id, user_id),
                                          CONSTRAINT household_members_household_id_fkey FOREIGN KEY (household_id) REFERENCES public.households (id) ON DELETE CASCADE,
                                          CONSTRAINT household_members_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users (id) ON DELETE CASCADE,
                                          CONSTRAINT household_members_role_check CHECK (role IN ('owner', 'member'))
) TABLESPACE pg_default;

CREATE INDEX IF NOT EXISTS household_members_household_idx
    ON public.household_members USING btree (household_id) TABLESPACE pg_default;
CREATE INDEX IF NOT EXISTS household_members_user_idx
    ON public.household_members USING btree (user_id) TABLESPACE pg_default;

-- 3. HOUSEHOLD INVITES (Depends on households and auth.users)
CREATE TABLE public.household_invites (
    id uuid NOT NULL DEFAULT extensions.uuid_generate_v4(),
    household_id uuid NOT NULL,
    invited_by_user_id uuid NOT NULL,
    invite_code uuid NOT NULL DEFAULT extensions.uuid_generate_v4(),
    email text NULL,
    display_name text NOT NULL,
    invite_type text NOT NULL,
    status text NOT NULL DEFAULT 'pending',
    created_at bigint NOT NULL,
    updated_at bigint NOT NULL,
    last_sent_at bigint NULL,
    expires_at bigint NOT NULL,
    accepted_at bigint NULL,
    accepted_by_user_id uuid NULL,
    CONSTRAINT household_invites_pkey PRIMARY KEY (id),
    CONSTRAINT household_invites_household_id_fkey FOREIGN KEY (household_id) REFERENCES public.households (id) ON DELETE CASCADE,
    CONSTRAINT household_invites_invited_by_user_id_fkey FOREIGN KEY (invited_by_user_id) REFERENCES auth.users (id) ON DELETE CASCADE,
    CONSTRAINT household_invites_accepted_by_user_id_fkey FOREIGN KEY (accepted_by_user_id) REFERENCES auth.users (id) ON DELETE CASCADE,
    CONSTRAINT household_invites_invite_type_check CHECK (invite_type IN ('email', 'code')),
    CONSTRAINT household_invites_status_check CHECK (status IN ('pending', 'accepted', 'declined', 'revoked'))
) TABLESPACE pg_default;

CREATE INDEX IF NOT EXISTS household_invites_household_id_idx
    ON public.household_invites USING btree (household_id) TABLESPACE pg_default;
CREATE INDEX IF NOT EXISTS household_invites_email_idx
    ON public.household_invites USING btree (email) TABLESPACE pg_default;
CREATE INDEX IF NOT EXISTS household_invites_code_idx
    ON public.household_invites USING btree (invite_code) TABLESPACE pg_default;
CREATE INDEX IF NOT EXISTS household_invites_status_idx
    ON public.household_invites USING btree (status) TABLESPACE pg_default;

-- 4. RECIPE FOLDERS (Depends on households and auth.users)
CREATE TABLE public.recipe_folders (
                                       id uuid NOT NULL DEFAULT extensions.uuid_generate_v4(),
                                       name text NOT NULL,
                                       user_id uuid NULL,
                                       household_id uuid NULL,
                                       deleted_at bigint NULL,
                                       -- Smart folder columns
                                       folder_type integer NOT NULL DEFAULT 0,      -- 0=normal, 1=smartTag, 2=smartIngredient
                                       filter_logic integer NOT NULL DEFAULT 0,     -- 0=OR, 1=AND
                                       smart_filter_tags text NULL,                 -- JSON array of tag names
                                       smart_filter_terms text NULL,                -- JSON array of ingredient terms
                                       CONSTRAINT recipe_folders_pkey PRIMARY KEY (id),
                                       CONSTRAINT recipe_folders_household_id_fkey FOREIGN KEY (household_id) REFERENCES public.households (id) ON DELETE CASCADE,
                                       CONSTRAINT recipe_folders_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users (id) ON DELETE CASCADE
) TABLESPACE pg_default;

-- Note: For manual migration if needed later:
-- ALTER TABLE public.recipe_folders
--   ADD COLUMN IF NOT EXISTS folder_type integer NOT NULL DEFAULT 0,
--   ADD COLUMN IF NOT EXISTS filter_logic integer NOT NULL DEFAULT 0,
--   ADD COLUMN IF NOT EXISTS smart_filter_tags text NULL,
--   ADD COLUMN IF NOT EXISTS smart_filter_terms text NULL;

CREATE INDEX IF NOT EXISTS recipe_folders_user_idx
    ON public.recipe_folders USING btree (user_id) TABLESPACE pg_default;
CREATE INDEX IF NOT EXISTS recipe_folders_household_idx
    ON public.recipe_folders USING btree (household_id) TABLESPACE pg_default;

-- 4a. RECIPE TAGS (Depends on households and auth.users)
CREATE TABLE public.recipe_tags (
    id uuid NOT NULL DEFAULT extensions.uuid_generate_v4(),
    name text NOT NULL,
    color text NOT NULL DEFAULT '#4285F4',
    user_id uuid NULL,
    household_id uuid NULL,
    created_at bigint NULL,
    updated_at bigint NULL,
    deleted_at bigint NULL,
    CONSTRAINT recipe_tags_pkey PRIMARY KEY (id),
    CONSTRAINT recipe_tags_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users (id) ON DELETE CASCADE,
    CONSTRAINT recipe_tags_household_id_fkey FOREIGN KEY (household_id) REFERENCES public.households (id) ON DELETE CASCADE
) TABLESPACE pg_default;

CREATE INDEX IF NOT EXISTS recipe_tags_user_id_idx ON public.recipe_tags(user_id);
CREATE INDEX IF NOT EXISTS recipe_tags_household_id_idx ON public.recipe_tags(household_id);
CREATE INDEX IF NOT EXISTS recipe_tags_deleted_at_idx ON public.recipe_tags(deleted_at);

-- 4b. RECIPES (Depends on recipe_folders, households, and auth.users)
CREATE TABLE public.recipes (
                                id uuid NOT NULL DEFAULT extensions.uuid_generate_v4(),
                                title text NOT NULL,
                                description text NULL,
                                rating integer NULL,
                                language text NULL,
                                steps text NULL,
                                ingredients text NULL,
                                servings integer NULL,
                                prep_time integer NULL,
                                cook_time integer NULL,
                                total_time integer NULL,
                                source text NULL,
                                nutrition text NULL,
                                general_notes text NULL,
                                user_id uuid NOT NULL,
                                household_id uuid NULL,
                                created_at bigint NULL,
                                updated_at bigint NULL,
                                deleted_at bigint NULL,
                                pinned integer NOT NULL DEFAULT 0,
                                pinned_at bigint NULL,
                                folder_ids text null,
                                tag_ids text null,
                                images text null,
                                CONSTRAINT recipes_pkey PRIMARY KEY (id),
                                CONSTRAINT recipes_household_id_fkey FOREIGN KEY (household_id) REFERENCES public.households (id) ON DELETE CASCADE,
                                CONSTRAINT recipes_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users (id) ON DELETE CASCADE
) TABLESPACE pg_default;

CREATE INDEX IF NOT EXISTS recipes_user_idx
    ON public.recipes USING btree (user_id) TABLESPACE pg_default;
CREATE INDEX IF NOT EXISTS recipes_household_idx
    ON public.recipes USING btree (household_id) TABLESPACE pg_default;

-- 6. RECIPE SHARES (Depends on recipes, households, auth.users)
CREATE TABLE public.recipe_shares (
                                      id uuid NOT NULL DEFAULT extensions.uuid_generate_v4(),
                                      recipe_id uuid NOT NULL,
                                      household_id uuid NULL,
                                      user_id uuid NULL,
                                      can_edit integer NOT NULL DEFAULT 0,
                                      CONSTRAINT recipe_shares_pkey PRIMARY KEY (id),
                                      CONSTRAINT recipe_shares_recipe_id_fkey FOREIGN KEY (recipe_id) REFERENCES public.recipes (id) ON DELETE CASCADE,
                                      CONSTRAINT recipe_shares_household_id_fkey FOREIGN KEY (household_id) REFERENCES public.households (id) ON DELETE CASCADE,
                                      CONSTRAINT recipe_shares_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users (id) ON DELETE CASCADE
) TABLESPACE pg_default;

CREATE INDEX IF NOT EXISTS recipe_shares_recipe_idx
    ON public.recipe_shares (recipe_id);
CREATE INDEX IF NOT EXISTS recipe_shares_household_idx
    ON public.recipe_shares (household_id);
CREATE INDEX IF NOT EXISTS recipe_shares_user_idx
    ON public.recipe_shares (user_id);

-- 7. RECIPE FOLDER SHARES (Depends on recipe_folders, households, auth.users)
CREATE TABLE public.recipe_folder_shares (
                                             id uuid NOT NULL DEFAULT extensions.uuid_generate_v4(),
                                             folder_id uuid NOT NULL,
                                             sharer_id uuid NOT NULL,
                                             target_user_id uuid NULL,
                                             target_household_id uuid NULL,
                                             can_edit integer NOT NULL DEFAULT 0,
                                             created_at bigint NULL,
                                             CONSTRAINT recipe_folder_shares_pkey PRIMARY KEY (id),
                                             CONSTRAINT recipe_folder_shares_folder_id_fkey FOREIGN KEY (folder_id)
                                                 REFERENCES public.recipe_folders (id) ON DELETE CASCADE,
                                             CONSTRAINT recipe_folder_shares_sharer_id_fkey FOREIGN KEY (sharer_id)
                                                 REFERENCES auth.users (id) ON DELETE CASCADE,
                                             CONSTRAINT recipe_folder_shares_target_user_id_fkey FOREIGN KEY (target_user_id)
                                                 REFERENCES auth.users (id) ON DELETE CASCADE,
                                             CONSTRAINT recipe_folder_shares_target_household_id_fkey FOREIGN KEY (target_household_id)
                                                 REFERENCES public.households (id) ON DELETE CASCADE
) TABLESPACE pg_default;

CREATE INDEX IF NOT EXISTS recipe_folder_shares_target_user_idx
    ON public.recipe_folder_shares (target_user_id) TABLESPACE pg_default;
CREATE INDEX IF NOT EXISTS recipe_folder_shares_target_household_idx
    ON public.recipe_folder_shares (target_household_id) TABLESPACE pg_default;
CREATE INDEX IF NOT EXISTS recipe_folder_shares_folder_idx
    ON public.recipe_folder_shares (folder_id) TABLESPACE pg_default;

-- 8. USER HOUSEHOLD SHARES (Depends on recipe_folders, households, auth.users)
CREATE TABLE public.user_household_shares (
                                              user_id uuid NOT NULL,
                                              household_id uuid NOT NULL,
                                              folder_id uuid NOT NULL,
                                              PRIMARY KEY (user_id, household_id, folder_id),
                                              CONSTRAINT uhs_user_fkey FOREIGN KEY (user_id) REFERENCES auth.users (id) ON DELETE CASCADE,
                                              CONSTRAINT uhs_folder_fkey FOREIGN KEY (folder_id) REFERENCES public.recipe_folders (id) ON DELETE CASCADE,
                                              CONSTRAINT uhs_household_fkey FOREIGN KEY (household_id) REFERENCES public.households (id) ON DELETE CASCADE
);

-- 9. COOKS (Depends on recipes, households, and auth.users)
CREATE TABLE public.cooks (
                              id uuid NOT NULL DEFAULT extensions.uuid_generate_v4(),
                              recipe_id uuid NOT NULL,
                              user_id uuid NULL,
                              household_id uuid NULL,
                              recipe_name text NOT NULL,
                              current_step_index integer NOT NULL DEFAULT 0,
                              status text NOT NULL DEFAULT 'in_progress',  -- values: 'in_progress', 'finished', 'discarded'
                              started_at bigint NULL,
                              finished_at bigint NULL,
                              updated_at bigint NULL,
                              rating integer NULL,
                              notes text NULL,
                              CONSTRAINT cooks_pkey PRIMARY KEY (id),
                              CONSTRAINT cooks_recipe_id_fkey FOREIGN KEY (recipe_id)
                                  REFERENCES public.recipes (id) ON DELETE CASCADE,
                              CONSTRAINT cooks_user_id_fkey FOREIGN KEY (user_id)
                                  REFERENCES auth.users (id) ON DELETE CASCADE,
                              CONSTRAINT cooks_household_id_fkey FOREIGN KEY (household_id)
                                  REFERENCES public.households (id) ON DELETE CASCADE
) TABLESPACE pg_default;

CREATE INDEX IF NOT EXISTS cooks_user_idx
    ON public.cooks USING btree (user_id) TABLESPACE pg_default;

CREATE INDEX IF NOT EXISTS cooks_household_idx
    ON public.cooks USING btree (household_id) TABLESPACE pg_default;

-- pantry and shopping list

CREATE TABLE public.pantry_items (
                                     id uuid NOT NULL DEFAULT extensions.uuid_generate_v4(),
                                     name text NOT NULL,
                                     stock_status integer NOT NULL DEFAULT 2, -- 0=out_of_stock, 1=low_stock, 2=in_stock
                                     is_staple integer NOT NULL DEFAULT 0, -- 0=false, 1=true
                                     is_canonicalised integer NOT NULL DEFAULT 0, -- 0=false, 1=true
                                     user_id uuid NOT NULL,
                                     household_id uuid NULL,
                                     unit text NULL,
                                     quantity double precision NULL,
                                     base_unit text NULL,
                                     base_quantity double precision NULL,
                                     price double precision NULL,
                                     created_at bigint NULL,
                                     updated_at bigint NULL,
                                     deleted_at bigint NULL,
                                     terms text NULL,
                                     category text NULL,
                                     CONSTRAINT pantry_items_pkey PRIMARY KEY (id),
                                     CONSTRAINT pantry_items_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users (id) ON DELETE CASCADE,
                                     CONSTRAINT pantry_items_household_id_fkey FOREIGN KEY (household_id) REFERENCES public.households (id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS pantry_items_user_idx ON public.pantry_items (user_id);
CREATE INDEX IF NOT EXISTS pantry_items_household_idx ON public.pantry_items (household_id);

CREATE TABLE public.recipe_ingredient_term_overrides (
                                                         id uuid NOT NULL DEFAULT extensions.uuid_generate_v4(),
                                                         recipe_id uuid NOT NULL,
                                                         term text NOT NULL,
                                                         pantry_item_id uuid NOT NULL,
                                                         user_id uuid NOT NULL,
                                                         household_id uuid NULL,
                                                         created_at bigint NULL,
                                                         deleted_at bigint NULL,
                                                         CONSTRAINT recipe_ingredient_term_overrides_pkey PRIMARY KEY (id),
                                                         CONSTRAINT recipe_ingredient_term_overrides_recipe_id_fkey FOREIGN KEY (recipe_id) REFERENCES public.recipes (id) ON DELETE CASCADE,
                                                         CONSTRAINT recipe_ingredient_term_overrides_pantry_item_id_fkey FOREIGN KEY (pantry_item_id) REFERENCES public.pantry_items (id) ON DELETE CASCADE,
                                                         CONSTRAINT recipe_ingredient_term_overrides_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users (id) ON DELETE CASCADE,
                                                         CONSTRAINT recipe_ingredient_term_overrides_household_id_fkey FOREIGN KEY (household_id) REFERENCES public.households (id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS recipe_ingredient_term_overrides_recipe_idx ON public.recipe_ingredient_term_overrides (recipe_id);
CREATE INDEX IF NOT EXISTS recipe_ingredient_term_overrides_pantry_idx ON public.recipe_ingredient_term_overrides (pantry_item_id);
CREATE INDEX IF NOT EXISTS recipe_ingredient_term_overrides_user_idx ON public.recipe_ingredient_term_overrides (user_id);
CREATE INDEX IF NOT EXISTS recipe_ingredient_term_overrides_household_idx ON public.recipe_ingredient_term_overrides (household_id);

CREATE TABLE public.shopping_lists (
                                       id uuid NOT NULL DEFAULT extensions.uuid_generate_v4(),
                                       name text NULL,
                                       user_id uuid NOT NULL,
                                       household_id uuid NULL,
                                       created_at bigint NULL,
                                       updated_at bigint NULL,
                                       deleted_at bigint NULL,
                                       CONSTRAINT shopping_lists_pkey PRIMARY KEY (id),
                                       CONSTRAINT shopping_lists_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users (id) ON DELETE CASCADE,
                                       CONSTRAINT shopping_lists_household_id_fkey FOREIGN KEY (household_id) REFERENCES public.households (id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS shopping_lists_user_idx ON public.shopping_lists (user_id);
CREATE INDEX IF NOT EXISTS shopping_lists_household_idx ON public.shopping_lists (household_id);

CREATE TABLE public.shopping_list_items (
                                            id uuid NOT NULL DEFAULT extensions.uuid_generate_v4(),
                                            shopping_list_id uuid NULL,
                                            name text NOT NULL,
                                            terms text NULL,
                                            category text NULL,
                                            source_recipe_id uuid NULL,
                                            amount double precision NULL,
                                            unit text NULL,
                                            bought integer NOT NULL DEFAULT 0,
                                            user_id uuid NOT NULL,
                                            household_id uuid NULL,
                                            created_at bigint NULL,
                                            updated_at bigint NULL,
                                            deleted_at bigint NULL,
                                            CONSTRAINT shopping_list_items_pkey PRIMARY KEY (id),
                                            CONSTRAINT shopping_list_items_list_id_fkey FOREIGN KEY (shopping_list_id) REFERENCES public.shopping_lists (id) ON DELETE CASCADE,
                                            CONSTRAINT shopping_list_items_source_recipe_id_fkey FOREIGN KEY (source_recipe_id) REFERENCES public.recipes (id) ON DELETE CASCADE,
                                            CONSTRAINT shopping_list_items_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users (id) ON DELETE CASCADE,
                                            CONSTRAINT shopping_list_items_household_id_fkey FOREIGN KEY (household_id) REFERENCES public.households (id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS shopping_list_items_list_idx ON public.shopping_list_items (shopping_list_id);
CREATE INDEX IF NOT EXISTS shopping_list_items_recipe_idx ON public.shopping_list_items (source_recipe_id);
CREATE INDEX IF NOT EXISTS shopping_list_items_user_idx ON public.shopping_list_items (user_id);
CREATE INDEX IF NOT EXISTS shopping_list_items_household_idx ON public.shopping_list_items (household_id);

CREATE TABLE public.converters (
                                   id uuid NOT NULL DEFAULT extensions.uuid_generate_v4(),
                                   term text NOT NULL,
                                   from_unit text NOT NULL,
                                   to_base_unit text NOT NULL,
                                   conversion_factor double precision NOT NULL,
                                   is_approximate integer NOT NULL DEFAULT 0,
                                   notes text NULL,
                                   user_id uuid NOT NULL,
                                   household_id uuid NULL,
                                   created_at bigint NULL,
                                   updated_at bigint NULL,
                                   deleted_at bigint NULL,
                                   CONSTRAINT converters_pkey PRIMARY KEY (id),
                                   CONSTRAINT converters_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users (id) ON DELETE CASCADE,
                                   CONSTRAINT converters_household_id_fkey FOREIGN KEY (household_id) REFERENCES public.households (id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS converters_term_idx ON public.converters (term);
CREATE INDEX IF NOT EXISTS converters_user_idx ON public.converters (user_id);
CREATE INDEX IF NOT EXISTS converters_household_idx ON public.converters (household_id);

-- MEAL PLANS
CREATE TABLE public.meal_plans (
                                   id uuid NOT NULL DEFAULT extensions.uuid_generate_v4(),
                                   date text NOT NULL,
                                   user_id uuid NOT NULL,
                                   household_id uuid NULL,
                                   items text NULL,
                                   created_at bigint NULL,
                                   updated_at bigint NULL,
                                   deleted_at bigint NULL,
                                   CONSTRAINT meal_plans_pkey PRIMARY KEY (id),
                                   CONSTRAINT meal_plans_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users (id) ON DELETE CASCADE,
                                   CONSTRAINT meal_plans_household_id_fkey FOREIGN KEY (household_id) REFERENCES public.households (id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS meal_plans_date_idx ON public.meal_plans (date);
CREATE INDEX IF NOT EXISTS meal_plans_user_idx ON public.meal_plans (user_id);
CREATE INDEX IF NOT EXISTS meal_plans_household_idx ON public.meal_plans (household_id);

-- SUBSCRIPTION EVENTS (Optional audit table for subscription events)
CREATE TABLE public.subscription_events (
    id uuid NOT NULL DEFAULT extensions.uuid_generate_v4(),
    user_id uuid NULL,

    -- Event details
    event_type text NOT NULL, -- 'purchase', 'renewal', 'cancellation', 'expiration', etc.
    event_source text NOT NULL DEFAULT 'revenuecat_webhook',
    event_data jsonb NOT NULL DEFAULT '{}', -- Structured event data

    -- RevenueCat data
    revenuecat_event_id text NULL,
    product_id text NULL,
    transaction_id text NULL,
    original_transaction_id text NULL,

    -- Financial
    price_in_cents integer NULL,
    currency text NULL,

    -- Platform
    platform text NULL, -- 'ios', 'android', 'web'
    store text NULL,

    -- Timing
    expires_at timestamp with time zone NULL,
    purchased_at timestamp with time zone NULL,

    -- Raw data for debugging
    raw_webhook_data jsonb NULL,

    -- Metadata
    processed_at timestamp with time zone NULL,
    created_at timestamp with time zone NOT NULL DEFAULT now(),

    CONSTRAINT subscription_events_pkey PRIMARY KEY (id),
    CONSTRAINT subscription_events_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users (id) ON DELETE CASCADE
) TABLESPACE pg_default;

-- Indexes for performance
CREATE INDEX IF NOT EXISTS subscription_events_user_id_idx ON public.subscription_events (user_id);
CREATE INDEX IF NOT EXISTS subscription_events_event_type_idx ON public.subscription_events (event_type);
CREATE INDEX IF NOT EXISTS subscription_events_revenuecat_event_id_idx ON public.subscription_events (revenuecat_event_id);
CREATE INDEX IF NOT EXISTS subscription_events_processed_at_idx ON public.subscription_events (processed_at);

-- USER SUBSCRIPTIONS (PowerSync-driven subscription management)
CREATE TABLE public.user_subscriptions (
    id uuid NOT NULL DEFAULT extensions.uuid_generate_v4(),
    user_id uuid NOT NULL,
    household_id uuid NULL, -- For household-level subscriptions

    -- Subscription status
    status text NOT NULL DEFAULT 'none', -- none, active, cancelled, expired
    entitlements jsonb NOT NULL DEFAULT '[]', -- Array of entitlement IDs ["plus"]

    -- Timing (Unix timestamps in milliseconds)
    expires_at bigint NULL,
    trial_ends_at bigint NULL,
    cancelled_at bigint NULL,

    -- RevenueCat integration
    product_id text NULL,
    store text NULL, -- app_store, play_store, stripe
    revenuecat_customer_id text NULL,

    -- Metadata (Unix timestamps in milliseconds)
    created_at bigint NULL,
    updated_at bigint NULL,

    CONSTRAINT user_subscriptions_pkey PRIMARY KEY (id),
    CONSTRAINT user_subscriptions_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users (id) ON DELETE CASCADE,
    CONSTRAINT user_subscriptions_household_id_fkey FOREIGN KEY (household_id) REFERENCES public.households (id) ON DELETE CASCADE,
    CONSTRAINT user_subscriptions_status_check CHECK (status IN ('none', 'active', 'cancelled', 'expired')),

    -- Ensure one subscription record per user
    CONSTRAINT user_subscriptions_user_id_unique UNIQUE (user_id)
) TABLESPACE pg_default;

-- Indexes for performance
CREATE INDEX IF NOT EXISTS user_subscriptions_user_id_idx ON public.user_subscriptions (user_id);
CREATE INDEX IF NOT EXISTS user_subscriptions_household_id_idx ON public.user_subscriptions (household_id);
CREATE INDEX IF NOT EXISTS user_subscriptions_status_idx ON public.user_subscriptions (status);
CREATE INDEX IF NOT EXISTS user_subscriptions_expires_at_idx ON public.user_subscriptions (expires_at);

-- RLS policies
ALTER TABLE public.user_subscriptions ENABLE ROW LEVEL SECURITY;

-- Policy: Users can view their own subscription
CREATE POLICY "Users can view own subscription" ON public.user_subscriptions
    FOR SELECT USING (auth.uid() = user_id);

-- Policy: Service role can manage all subscriptions (for webhooks)
CREATE POLICY "Service role can manage subscriptions" ON public.user_subscriptions
    FOR ALL USING (auth.role() = 'service_role');

-- CLIPPINGS
CREATE TABLE public.clippings (
    id uuid NOT NULL DEFAULT extensions.uuid_generate_v4(),
    title text NULL,
    content text NULL,
    user_id uuid NOT NULL,
    household_id uuid NULL,
    created_at bigint NULL,
    updated_at bigint NULL,
    deleted_at bigint NULL,
    CONSTRAINT clippings_pkey PRIMARY KEY (id),
    CONSTRAINT clippings_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users (id) ON DELETE CASCADE,
    CONSTRAINT clippings_household_id_fkey FOREIGN KEY (household_id) REFERENCES public.households (id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS clippings_user_idx ON public.clippings (user_id);
CREATE INDEX IF NOT EXISTS clippings_household_idx ON public.clippings (household_id);
CREATE INDEX IF NOT EXISTS clippings_updated_at_idx ON public.clippings (updated_at DESC);

-- Table to track processed webhook events for idempotency
CREATE TABLE processed_webhooks (
                                    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
                                    revenuecat_event_id TEXT NOT NULL UNIQUE,
                                    event_type TEXT NOT NULL,
                                    processed_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Index for fast lookups (UNIQUE constraint creates one, but being explicit)
CREATE INDEX idx_processed_webhooks_event_id ON processed_webhooks(revenuecat_event_id);

-- Enable RLS (no policies = service role only access)
ALTER TABLE processed_webhooks ENABLE ROW LEVEL SECURITY;

-- Policy: Service role can manage all processed webhooks
CREATE POLICY "Service role can manage processed webhooks" ON processed_webhooks
    FOR ALL USING (auth.role() = 'service_role');


CREATE PUBLICATION powersync FOR ALL TABLES;
