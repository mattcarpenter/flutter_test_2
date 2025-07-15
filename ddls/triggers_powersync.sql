-- Cleanup on household removal - ALL ENTITIES
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

CREATE TRIGGER trg_cleanup_all_entities
    AFTER UPDATE ON public.household_members
    FOR EACH ROW
    WHEN (NEW.is_active = 0)  -- Only trigger when the user is removed
EXECUTE FUNCTION cleanup_all_entities_on_member_removal();

-- updating records when joining household (insert membership) - ALL ENTITIES
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

    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_assign_household_to_all_entities
    AFTER UPDATE ON public.household_members
    FOR EACH ROW
    WHEN (NEW.is_active = 1)  -- Only trigger when the user joins/activates the household
EXECUTE FUNCTION assign_household_to_all_entities_on_member_addition();

-- updating records when joining household (changing status from 0 to 1) - ALL ENTITIES
CREATE OR REPLACE FUNCTION assign_household_to_all_entities_on_member_insert()
    RETURNS TRIGGER AS $$
BEGIN
    -- Migrate all personal data to household
    UPDATE public.recipes
    SET household_id = NEW.household_id, updated_at = EXTRACT(EPOCH FROM NOW()) * 1000
    WHERE user_id = NEW.user_id AND household_id IS NULL;

    UPDATE public.recipe_folders
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

    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_assign_household_to_all_entities_insert
    AFTER INSERT ON public.household_members
    FOR EACH ROW
EXECUTE FUNCTION assign_household_to_all_entities_on_member_insert();

-- TRIGGERS FOR FOLDER SHARING ----------------------------------------------------

CREATE OR REPLACE FUNCTION update_user_household_shares_after_rfs_insert()
    RETURNS trigger AS $$
BEGIN
    IF NEW.target_household_id IS NOT NULL THEN
        INSERT INTO public.user_household_shares (user_id, household_id, folder_id)
        SELECT hm.user_id, hm.household_id, NEW.folder_id
        FROM public.household_members hm
        WHERE hm.household_id = NEW.target_household_id
          AND hm.is_active = 1;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_rfs_after_insert
    AFTER INSERT ON public.recipe_folder_shares
    FOR EACH ROW
EXECUTE FUNCTION update_user_household_shares_after_rfs_insert();

CREATE OR REPLACE FUNCTION update_user_household_shares_after_rfs_delete()
    RETURNS trigger AS $$
BEGIN
    IF OLD.target_household_id IS NOT NULL THEN
        DELETE FROM public.user_household_shares
        WHERE household_id = OLD.target_household_id
          AND folder_id = OLD.folder_id;
    END IF;
    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_rfs_after_delete
    AFTER DELETE ON public.recipe_folder_shares
    FOR EACH ROW
EXECUTE FUNCTION update_user_household_shares_after_rfs_delete();

CREATE OR REPLACE FUNCTION update_user_household_shares_after_rfs_update()
    RETURNS trigger AS $$
BEGIN
    -- Remove rows for the old share values if it was targeting a household.
    IF OLD.target_household_id IS NOT NULL THEN
        DELETE FROM public.user_household_shares
        WHERE household_id = OLD.target_household_id
          AND folder_id = OLD.folder_id;
    END IF;

    -- Insert rows for the new share values.
    IF NEW.target_household_id IS NOT NULL THEN
        INSERT INTO public.user_household_shares (user_id, household_id, folder_id)
        SELECT hm.user_id, hm.household_id, NEW.folder_id
        FROM public.household_members hm
        WHERE hm.household_id = NEW.target_household_id
          AND hm.is_active = 1;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_rfs_after_update
    AFTER UPDATE ON public.recipe_folder_shares
    FOR EACH ROW
EXECUTE FUNCTION update_user_household_shares_after_rfs_update();

CREATE OR REPLACE FUNCTION update_user_household_shares_after_hm_insert()
    RETURNS trigger AS $$
BEGIN
    IF NEW.is_active = 1 THEN
        INSERT INTO public.user_household_shares (user_id, household_id, folder_id)
        SELECT NEW.user_id, NEW.household_id, rfs.folder_id
        FROM public.recipe_folder_shares rfs
        WHERE rfs.target_household_id = NEW.household_id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_hm_after_insert
    AFTER INSERT ON public.household_members
    FOR EACH ROW
EXECUTE FUNCTION update_user_household_shares_after_hm_insert();

CREATE OR REPLACE FUNCTION update_user_household_shares_after_hm_update()
    RETURNS trigger AS $$
BEGIN
    -- If the membership becomes active (or household changes), insert missing share rows.
    IF NEW.is_active = 1 AND (OLD.is_active <> NEW.is_active OR OLD.household_id <> NEW.household_id) THEN
        INSERT INTO public.user_household_shares (user_id, household_id, folder_id)
        SELECT NEW.user_id, NEW.household_id, rfs.folder_id
        FROM public.recipe_folder_shares rfs
        WHERE rfs.target_household_id = NEW.household_id;
    ELSIF OLD.is_active = 1 AND NEW.is_active <> 1 THEN
        -- If membership becomes inactive, remove the share rows for that user.
        DELETE FROM public.user_household_shares
        WHERE user_id = OLD.user_id AND household_id = OLD.household_id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_hm_after_update
    AFTER UPDATE ON public.household_members
    FOR EACH ROW
EXECUTE FUNCTION update_user_household_shares_after_hm_update();

CREATE OR REPLACE FUNCTION update_user_household_shares_after_hm_delete()
    RETURNS trigger AS $$
BEGIN
    IF OLD.is_active = 1 THEN
        DELETE FROM public.user_household_shares
        WHERE user_id = OLD.user_id AND household_id = OLD.household_id;
    END IF;
    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_hm_after_delete
    AFTER DELETE ON public.household_members
    FOR EACH ROW
EXECUTE FUNCTION update_user_household_shares_after_hm_delete();

CREATE OR REPLACE FUNCTION set_target_household_on_rfs_insert()
    RETURNS trigger AS $$
DECLARE
    household uuid;
BEGIN
    IF NEW.target_household_id IS NULL AND NEW.target_user_id IS NOT NULL THEN
        SELECT hm.household_id INTO household
        FROM public.household_members hm
        WHERE hm.user_id = NEW.target_user_id AND hm.is_active = 1
        LIMIT 1;
        NEW.target_household_id := household;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_set_target_household_on_rfs_insert
    BEFORE INSERT ON public.recipe_folder_shares
    FOR EACH ROW
EXECUTE FUNCTION set_target_household_on_rfs_insert();

-- NEW HOUSEHOLD AUTO-ASSIGNMENT TRIGGERS ----------------------------------------
-- These triggers automatically assign household_id to entities when created by household members

-- Function to get user's active household
CREATE OR REPLACE FUNCTION get_user_active_household(user_id_param uuid)
    RETURNS uuid AS $$
DECLARE
    household_id_result uuid;
BEGIN
    SELECT hm.household_id INTO household_id_result
    FROM public.household_members hm
    WHERE hm.user_id = user_id_param AND hm.is_active = 1
    LIMIT 1;
    
    RETURN household_id_result;
END;
$$ LANGUAGE plpgsql;

-- Auto-assign household_id on recipes insert
CREATE OR REPLACE FUNCTION assign_household_on_recipes_insert()
    RETURNS TRIGGER AS $$
DECLARE
    user_household uuid;
BEGIN
    IF NEW.household_id IS NULL THEN
        user_household := get_user_active_household(NEW.user_id);
        IF user_household IS NOT NULL THEN
            NEW.household_id := user_household;
        END IF;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_assign_household_on_recipes_insert
    BEFORE INSERT ON public.recipes
    FOR EACH ROW
EXECUTE FUNCTION assign_household_on_recipes_insert();

-- Auto-assign household_id on meal_plans insert
CREATE OR REPLACE FUNCTION assign_household_on_meal_plans_insert()
    RETURNS TRIGGER AS $$
DECLARE
    user_household uuid;
BEGIN
    IF NEW.household_id IS NULL THEN
        user_household := get_user_active_household(NEW.user_id);
        IF user_household IS NOT NULL THEN
            NEW.household_id := user_household;
        END IF;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_assign_household_on_meal_plans_insert
    BEFORE INSERT ON public.meal_plans
    FOR EACH ROW
EXECUTE FUNCTION assign_household_on_meal_plans_insert();

-- Auto-assign household_id on pantry_items insert
CREATE OR REPLACE FUNCTION assign_household_on_pantry_items_insert()
    RETURNS TRIGGER AS $$
DECLARE
    user_household uuid;
BEGIN
    IF NEW.household_id IS NULL THEN
        user_household := get_user_active_household(NEW.user_id);
        IF user_household IS NOT NULL THEN
            NEW.household_id := user_household;
        END IF;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_assign_household_on_pantry_items_insert
    BEFORE INSERT ON public.pantry_items
    FOR EACH ROW
EXECUTE FUNCTION assign_household_on_pantry_items_insert();

-- Auto-assign household_id on shopping_lists insert
CREATE OR REPLACE FUNCTION assign_household_on_shopping_lists_insert()
    RETURNS TRIGGER AS $$
DECLARE
    user_household uuid;
BEGIN
    IF NEW.household_id IS NULL THEN
        user_household := get_user_active_household(NEW.user_id);
        IF user_household IS NOT NULL THEN
            NEW.household_id := user_household;
        END IF;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_assign_household_on_shopping_lists_insert
    BEFORE INSERT ON public.shopping_lists
    FOR EACH ROW
EXECUTE FUNCTION assign_household_on_shopping_lists_insert();

-- Auto-assign household_id on shopping_list_items insert
CREATE OR REPLACE FUNCTION assign_household_on_shopping_list_items_insert()
    RETURNS TRIGGER AS $$
DECLARE
    user_household uuid;
BEGIN
    IF NEW.household_id IS NULL THEN
        user_household := get_user_active_household(NEW.user_id);
        IF user_household IS NOT NULL THEN
            NEW.household_id := user_household;
        END IF;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_assign_household_on_shopping_list_items_insert
    BEFORE INSERT ON public.shopping_list_items
    FOR EACH ROW
EXECUTE FUNCTION assign_household_on_shopping_list_items_insert();

-- Auto-assign household_id on cooks insert
CREATE OR REPLACE FUNCTION assign_household_on_cooks_insert()
    RETURNS TRIGGER AS $$
DECLARE
    user_household uuid;
BEGIN
    IF NEW.household_id IS NULL THEN
        user_household := get_user_active_household(NEW.user_id);
        IF user_household IS NOT NULL THEN
            NEW.household_id := user_household;
        END IF;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_assign_household_on_cooks_insert
    BEFORE INSERT ON public.cooks
    FOR EACH ROW
EXECUTE FUNCTION assign_household_on_cooks_insert();

-- Auto-assign household_id on converters insert
CREATE OR REPLACE FUNCTION assign_household_on_converters_insert()
    RETURNS TRIGGER AS $$
DECLARE
    user_household uuid;
BEGIN
    IF NEW.household_id IS NULL THEN
        user_household := get_user_active_household(NEW.user_id);
        IF user_household IS NOT NULL THEN
            NEW.household_id := user_household;
        END IF;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_assign_household_on_converters_insert
    BEFORE INSERT ON public.converters
    FOR EACH ROW
EXECUTE FUNCTION assign_household_on_converters_insert();

-- Auto-assign household_id on recipe_ingredient_term_overrides insert
CREATE OR REPLACE FUNCTION assign_household_on_recipe_ingredient_term_overrides_insert()
    RETURNS TRIGGER AS $$
DECLARE
    user_household uuid;
BEGIN
    IF NEW.household_id IS NULL THEN
        user_household := get_user_active_household(NEW.user_id);
        IF user_household IS NOT NULL THEN
            NEW.household_id := user_household;
        END IF;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_assign_household_on_recipe_ingredient_term_overrides_insert
    BEFORE INSERT ON public.recipe_ingredient_term_overrides
    FOR EACH ROW
EXECUTE FUNCTION assign_household_on_recipe_ingredient_term_overrides_insert();

-- HOUSEHOLD SUBSCRIPTION SHARING TRIGGERS ----------------------------------------
-- These triggers automatically update subscription household_id when users join/leave households

-- Function to update subscription household_id when user joins household
CREATE OR REPLACE FUNCTION update_subscription_household_on_join()
RETURNS TRIGGER AS $$
BEGIN
  -- When user joins/activates in household, update their subscription
  UPDATE public.user_subscriptions 
  SET household_id = NEW.household_id,
      updated_at = EXTRACT(EPOCH FROM NOW()) * 1000
  WHERE user_id = NEW.user_id 
    AND status = 'active' 
    AND entitlements::jsonb ? 'plus';
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger for household joining (INSERT)
CREATE TRIGGER trg_update_subscription_household_on_join_insert
AFTER INSERT ON public.household_members
FOR EACH ROW
WHEN (NEW.is_active = 1)
EXECUTE FUNCTION update_subscription_household_on_join();

-- Trigger for household activation (UPDATE)
CREATE TRIGGER trg_update_subscription_household_on_join_update
AFTER UPDATE ON public.household_members
FOR EACH ROW
WHEN (OLD.is_active = 0 AND NEW.is_active = 1)
EXECUTE FUNCTION update_subscription_household_on_join();

-- Function to remove subscription household_id when user leaves household
CREATE OR REPLACE FUNCTION update_subscription_household_on_leave()
RETURNS TRIGGER AS $$
BEGIN
  -- When user leaves/deactivates from household, remove household_id from their subscription
  UPDATE public.user_subscriptions 
  SET household_id = NULL,
      updated_at = EXTRACT(EPOCH FROM NOW()) * 1000
  WHERE user_id = OLD.user_id 
    AND household_id = OLD.household_id;
  
  RETURN OLD;
END;
$$ LANGUAGE plpgsql;

-- Trigger for household leaving (UPDATE)
CREATE TRIGGER trg_update_subscription_household_on_leave_update
AFTER UPDATE ON public.household_members
FOR EACH ROW
WHEN (OLD.is_active = 1 AND NEW.is_active = 0)
EXECUTE FUNCTION update_subscription_household_on_leave();

-- Trigger for household leaving (DELETE)
CREATE TRIGGER trg_update_subscription_household_on_leave_delete
AFTER DELETE ON public.household_members
FOR EACH ROW
WHEN (OLD.is_active = 1)
EXECUTE FUNCTION update_subscription_household_on_leave();
