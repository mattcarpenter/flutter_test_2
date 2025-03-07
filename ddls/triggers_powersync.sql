-- Cleanup on household removal
CREATE OR REPLACE FUNCTION cleanup_folders_on_member_removal()
    RETURNS TRIGGER AS $$
BEGIN
    UPDATE public.recipe_folders
    SET household_id = NULL
    WHERE user_id = OLD.user_id AND household_id = OLD.household_id;

    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_cleanup_folders
    AFTER UPDATE ON public.household_members
    FOR EACH ROW
    WHEN (NEW.is_active = 0)  -- Only trigger when the user is removed
EXECUTE FUNCTION cleanup_folders_on_member_removal();

-- updating records when joining household (insert membership)
CREATE OR REPLACE FUNCTION assign_household_to_folders_on_member_addition()
    RETURNS TRIGGER AS $$
BEGIN
    UPDATE public.recipe_folders
    SET household_id = NEW.household_id
    WHERE user_id = NEW.user_id AND household_id IS NULL;

    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_assign_household_to_folders
    AFTER UPDATE ON public.household_members
    FOR EACH ROW
    WHEN (NEW.is_active = 1)  -- Only trigger when the user joins/activates the household
EXECUTE FUNCTION assign_household_to_folders_on_member_addition();

-- updating records when joining household (changing status from 0 to 1)
CREATE OR REPLACE FUNCTION assign_household_to_folders_on_member_insert()
    RETURNS TRIGGER AS $$
BEGIN
    UPDATE public.recipe_folders
    SET household_id = NEW.household_id
    WHERE user_id = NEW.user_id AND household_id IS NULL;

    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_assign_household_to_folders_insert
    AFTER INSERT ON public.household_members
    FOR EACH ROW
EXECUTE FUNCTION assign_household_to_folders_on_member_insert();

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
    household text;
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
