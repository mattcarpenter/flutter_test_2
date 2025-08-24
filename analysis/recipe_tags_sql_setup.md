# Recipe Tags SQL Setup Instructions

This document contains all the SQL commands needed to set up the recipe tags feature in your Supabase database.

## 1. Create Recipe Tags Table

```sql
-- Create the recipe_tags table
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

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS recipe_tags_user_id_idx ON public.recipe_tags(user_id);
CREATE INDEX IF NOT EXISTS recipe_tags_household_id_idx ON public.recipe_tags(household_id);
CREATE INDEX IF NOT EXISTS recipe_tags_deleted_at_idx ON public.recipe_tags(deleted_at);
```

## 2. Enable Row Level Security and Create Policies

```sql
-- Enable RLS on the recipe_tags table
ALTER TABLE public.recipe_tags ENABLE ROW LEVEL SECURITY;

-- Policy: Users can view their own recipe tags
CREATE POLICY "Users can view own recipe tags"
    ON public.recipe_tags
    FOR SELECT 
    USING (user_id = auth.uid());

-- Policy: Users can view household recipe tags
CREATE POLICY "Users can view household recipe tags"
    ON public.recipe_tags
    FOR SELECT 
    USING (
        household_id IN (
            SELECT household_id 
            FROM household_members 
            WHERE user_id = auth.uid() 
            AND is_active = 1
        )
    );

-- Policy: Users can insert recipe tags
CREATE POLICY "Users can insert recipe tags"
    ON public.recipe_tags
    FOR INSERT 
    WITH CHECK (
        user_id = auth.uid() 
        OR household_id IN (
            SELECT household_id 
            FROM household_members 
            WHERE user_id = auth.uid() 
            AND is_active = 1
        )
    );

-- Policy: Users can update their own recipe tags
CREATE POLICY "Users can update own recipe tags"
    ON public.recipe_tags
    FOR UPDATE 
    USING (user_id = auth.uid());

-- Policy: Users can update household recipe tags
CREATE POLICY "Users can update household recipe tags"
    ON public.recipe_tags
    FOR UPDATE 
    USING (
        household_id IN (
            SELECT household_id 
            FROM household_members 
            WHERE user_id = auth.uid() 
            AND is_active = 1
        )
    );
```

## 3. Update Household Management Triggers

### Update the cleanup trigger to handle recipe tags when user leaves household:

```sql
-- First, drop the existing function if you want to replace it
DROP FUNCTION IF EXISTS cleanup_all_entities_on_member_removal CASCADE;

-- Create updated function that includes recipe_tags
CREATE OR REPLACE FUNCTION cleanup_all_entities_on_member_removal()
    RETURNS TRIGGER AS $$
BEGIN
    -- Update all entity types back to personal (household_id = NULL)
    UPDATE public.recipes
    SET household_id = NULL, updated_at = EXTRACT(EPOCH FROM NOW()) * 1000
    WHERE user_id = OLD.user_id AND household_id = OLD.household_id;

    UPDATE public.recipe_folders
    SET household_id = NULL
    WHERE user_id = OLD.user_id AND household_id = OLD.household_id;

    UPDATE public.recipe_tags
    SET household_id = NULL
    WHERE user_id = OLD.user_id AND household_id = OLD.household_id;

    UPDATE public.meal_plans
    SET household_id = NULL, updated_at = EXTRACT(EPOCH FROM NOW()) * 1000
    WHERE user_id = OLD.user_id AND household_id = OLD.household_id;

    UPDATE public.pantry_items
    SET household_id = NULL, updated_at = EXTRACT(EPOCH FROM NOW()) * 1000
    WHERE user_id = OLD.user_id AND household_id = OLD.household_id;

    -- Handle shopping lists and their items
    UPDATE public.shopping_lists
    SET household_id = NULL, updated_at = EXTRACT(EPOCH FROM NOW()) * 1000
    WHERE user_id = OLD.user_id AND household_id = OLD.household_id;

    UPDATE public.shopping_list_items
    SET household_id = NULL, updated_at = EXTRACT(EPOCH FROM NOW()) * 1000
    WHERE shopping_list_id IN (
        SELECT id FROM public.shopping_lists
        WHERE user_id = OLD.user_id AND household_id IS NULL
    );

    UPDATE public.cooks
    SET household_id = NULL, updated_at = EXTRACT(EPOCH FROM NOW()) * 1000
    WHERE user_id = OLD.user_id AND household_id = OLD.household_id;

    UPDATE public.converters
    SET household_id = NULL, updated_at = EXTRACT(EPOCH FROM NOW()) * 1000
    WHERE user_id = OLD.user_id AND household_id = OLD.household_id;

    UPDATE public.recipe_ingredient_term_overrides
    SET household_id = NULL
    WHERE user_id = OLD.user_id AND household_id = OLD.household_id;

    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Recreate the trigger
CREATE TRIGGER trg_cleanup_all_entities
    AFTER UPDATE ON public.household_members
    FOR EACH ROW
    WHEN (NEW.is_active = 0)  -- Only trigger when the user is removed
EXECUTE FUNCTION cleanup_all_entities_on_member_removal();
```

### Update the household assignment trigger to handle recipe tags when user joins household:

```sql
-- First, drop the existing function if you want to replace it
DROP FUNCTION IF EXISTS assign_household_to_all_entities_on_member_addition CASCADE;

-- Create updated function that includes recipe_tags
CREATE OR REPLACE FUNCTION assign_household_to_all_entities_on_member_addition()
    RETURNS TRIGGER AS $$
BEGIN
    -- Migrate all personal data to household
    UPDATE public.recipes
    SET household_id = NEW.household_id, updated_at = EXTRACT(EPOCH FROM NOW()) * 1000
    WHERE user_id = NEW.user_id AND household_id IS NULL;

    UPDATE public.recipe_folders
    SET household_id = NEW.household_id
    WHERE user_id = NEW.user_id AND household_id IS NULL;

    UPDATE public.recipe_tags
    SET household_id = NEW.household_id
    WHERE user_id = NEW.user_id AND household_id IS NULL;

    UPDATE public.meal_plans
    SET household_id = NEW.household_id, updated_at = EXTRACT(EPOCH FROM NOW()) * 1000
    WHERE user_id = NEW.user_id AND household_id IS NULL;

    UPDATE public.pantry_items
    SET household_id = NEW.household_id, updated_at = EXTRACT(EPOCH FROM NOW()) * 1000
    WHERE user_id = NEW.user_id AND household_id IS NULL;

    -- Handle shopping lists and their items
    UPDATE public.shopping_lists
    SET household_id = NEW.household_id, updated_at = EXTRACT(EPOCH FROM NOW()) * 1000
    WHERE user_id = NEW.user_id AND household_id IS NULL;

    UPDATE public.shopping_list_items
    SET household_id = NEW.household_id, updated_at = EXTRACT(EPOCH FROM NOW()) * 1000
    WHERE shopping_list_id IN (
        SELECT id FROM public.shopping_lists
        WHERE user_id = NEW.user_id AND household_id = NEW.household_id
    );

    UPDATE public.cooks
    SET household_id = NEW.household_id, updated_at = EXTRACT(EPOCH FROM NOW()) * 1000
    WHERE user_id = NEW.user_id AND household_id IS NULL;

    UPDATE public.converters
    SET household_id = NEW.household_id, updated_at = EXTRACT(EPOCH FROM NOW()) * 1000
    WHERE user_id = NEW.user_id AND household_id IS NULL;

    UPDATE public.recipe_ingredient_term_overrides
    SET household_id = NEW.household_id
    WHERE user_id = NEW.user_id AND household_id IS NULL;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Check if trigger exists and create if it doesn't
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_trigger 
        WHERE tgname = 'trg_assign_household_to_all_entities'
    ) THEN
        CREATE TRIGGER trg_assign_household_to_all_entities
            AFTER INSERT ON public.household_members
            FOR EACH ROW
            WHEN (NEW.is_active = 1)  -- Only trigger when user is added
            EXECUTE FUNCTION assign_household_to_all_entities_on_member_addition();
    END IF;
END $$;
```

## 4. PowerSync Sync Rules Update

After creating the table and policies, update your PowerSync sync rules YAML file to include recipe_tags:

```yaml
# Add to the belongs_to_user bucket:
belongs_to_user:
  parameters: SELECT request.user_id() as user_id
  data:
    - SELECT * FROM public.recipe_folders WHERE recipe_folders.user_id = bucket.user_id
    - SELECT * FROM public.recipe_tags WHERE recipe_tags.user_id = bucket.user_id  # Add this line
    - SELECT * FROM public.recipes WHERE recipes.user_id = bucket.user_id

# Add to the belongs_to_household bucket:
belongs_to_household:
  parameters: SELECT household_id FROM household_members WHERE user_id = request.user_id() AND is_active = 1
  data:
    - SELECT * FROM public.recipe_folders WHERE household_id = bucket.household_id
    - SELECT * FROM public.recipe_tags WHERE household_id = bucket.household_id  # Add this line
    - SELECT * FROM public.recipes WHERE household_id = bucket.household_id
```

## 5. Verify Installation

After running all the SQL commands, verify the setup:

```sql
-- Check table structure
\d public.recipe_tags

-- Check policies
SELECT * FROM pg_policies WHERE tablename = 'recipe_tags';

-- Test inserting a tag (replace with your user ID)
INSERT INTO public.recipe_tags (name, color, user_id) 
VALUES ('Test Tag', '#4285F4', auth.uid())
RETURNING *;

-- Check that the tag was created
SELECT * FROM public.recipe_tags WHERE user_id = auth.uid();
```

## Notes

- The `tag_ids` column should already be added to the `recipes` table as text (JSON array)
- All timestamp fields (`created_at`, `updated_at`, `deleted_at`) use bigint for Unix timestamps in milliseconds
- Color field stores hex color codes as strings (e.g., '#4285F4')
- All foreign keys have CASCADE delete to maintain referential integrity
- The triggers automatically handle household assignment/removal for tags