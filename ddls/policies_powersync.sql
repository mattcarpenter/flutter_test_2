CREATE POLICY "Users can view their own folders"
    ON recipe_folders
    FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert folders only for households they belong to"
    ON public.recipe_folders
    FOR INSERT
    WITH CHECK (
      ((auth.uid() = user_id) OR ((household_id IS NOT NULL) AND is_household_member(household_id, auth.uid())))
    );

CREATE POLICY "Users can update folders only for households they belong to"
    ON public.recipe_folders
    FOR UPDATE
    USING (
    auth.uid() = user_id
        OR (
        household_id IS NOT NULL
            AND public.is_household_member(household_id, auth.uid())
        )
    )
    WITH CHECK (
    household_id IS NULL
        OR public.is_household_member(household_id, auth.uid())
    );

-- RECIPES -------------------------------
CREATE POLICY "Users can view recipes if authorized"
    ON public.recipes
    FOR SELECT
    USING (
    user_id = auth.uid()
        OR (
        household_id IS NOT NULL
            AND public.is_household_member(household_id, auth.uid())
        )
    );

CREATE POLICY "Users can insert recipes if authorized"
    ON public.recipes
    FOR INSERT
    WITH CHECK (
    user_id = auth.uid()
        AND (
        household_id IS NULL
            OR (household_id IS NOT NULL AND public.is_household_member(household_id, auth.uid()))
        )
    );

CREATE POLICY "Users can update recipes if authorized"
    ON public.recipes
    FOR UPDATE
    USING (
    user_id = auth.uid()
        OR (
        household_id IS NOT NULL
            AND public.is_household_member(household_id, auth.uid())
        )
    )
    WITH CHECK (
    user_id = auth.uid()
        OR (
        household_id IS NOT NULL
            AND public.is_household_member(household_id, auth.uid())
        )
    );

-- Allow users to view only their own recipes.
CREATE POLICY "Users can view their own recipes"
    ON public.recipes
    FOR SELECT
    USING (auth.uid() = user_id);

-- Allow users to insert only recipes that belong to them.
CREATE POLICY "Users can insert their own recipes"
    ON public.recipes
    FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- Allow users to update only their own recipes.
CREATE POLICY "Users can update their own recipes"
    ON public.recipes
    FOR UPDATE
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- HOUSEHOLDS -------------------------------
CREATE POLICY "Users can view households they belong to"
    ON public.households
    FOR SELECT
    USING (
    auth.uid() = user_id
        OR EXISTS (
        SELECT 1
        FROM public.household_members hm
        WHERE hm.household_id = households.id
          AND hm.user_id = auth.uid()
    )
    );
CREATE POLICY "Users can insert households they own"
    ON public.households
    FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update households they own"
    ON public.households
    FOR UPDATE
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- HOUSEHOLD MEMBERS -------------------------------

CREATE POLICY "Users can view active membership rows or their own membership row"
    ON public.household_members
    FOR SELECT
    USING (
    (auth.uid() = user_id)
        OR (
        is_active = 1
            AND EXISTS (
            SELECT 1
            FROM public.households h
            WHERE h.id = household_members.household_id
              AND h.user_id = auth.uid()
        )
        )
    );

CREATE POLICY "Users can insert their own membership row"
    ON public.household_members
    FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own membership row"
    ON public.household_members
    FOR UPDATE
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);


-- RECIPE SHARES -------------------------------

CREATE POLICY "Users can view recipe_shares relevant to them"
    ON public.recipe_shares
    FOR SELECT
    USING (
    -- Direct share: row has a user_id that matches auth.uid()
    (user_id IS NOT NULL AND auth.uid() = user_id)
        OR
        -- Household share: the row’s household_id is set and the current user is a member
    (household_id IS NOT NULL AND EXISTS (
        SELECT 1 FROM public.household_members hm
        WHERE hm.household_id = recipe_shares.household_id
          AND hm.user_id = auth.uid()
    ))
    );

CREATE POLICY "Users can insert recipe_shares for recipes they share"
    ON public.recipe_shares
    FOR INSERT
    WITH CHECK (
    -- When inserting, the share must be directed either to themselves or via a household they belong to.
    (user_id IS NOT NULL AND auth.uid() = user_id)
        OR
    (household_id IS NOT NULL AND EXISTS (
        SELECT 1 FROM public.household_members hm
        WHERE hm.household_id = recipe_shares.household_id
          AND hm.user_id = auth.uid()
    ))
    );

CREATE POLICY "Users can update recipe_shares relevant to them"
    ON public.recipe_shares
    FOR UPDATE
    USING (
    (user_id IS NOT NULL AND auth.uid() = user_id)
        OR
    (household_id IS NOT NULL AND EXISTS (
        SELECT 1 FROM public.household_members hm
        WHERE hm.household_id = recipe_shares.household_id
          AND hm.user_id = auth.uid()
    ))
    )
    WITH CHECK (
    (user_id IS NOT NULL AND auth.uid() = user_id)
        OR
    (household_id IS NOT NULL AND EXISTS (
        SELECT 1 FROM public.household_members hm
        WHERE hm.household_id = recipe_shares.household_id
          AND hm.user_id = auth.uid()
    ))
    );

-- RECIPE FOLDER SHARES -------------------------------
CREATE POLICY "Users can view shared recipe folders"
    ON public.recipe_folder_shares
    FOR SELECT
    USING (
    -- The user is the one who shared the folder.
    sharer_id = auth.uid()
        OR
        -- The share is directly targeted to the current user.
    target_user_id = auth.uid()
        OR
        -- The share is targeted to a household that the user belongs to.
    (
        target_household_id IS NOT NULL
            AND target_household_id IN (
            SELECT hm.household_id
            FROM public.household_members hm
            WHERE hm.user_id = auth.uid() AND hm.is_active = 1
        )
        )
    );
CREATE POLICY "Users can insert shared recipe folders"
    ON public.recipe_folder_shares
    FOR INSERT
    WITH CHECK (
    -- Only the sharer (i.e. folder owner) can create a share.
    sharer_id = auth.uid()
        AND EXISTS (
        SELECT 1 FROM public.recipe_folders f
        WHERE f.id = recipe_folder_shares.folder_id
          AND (
            f.user_id = auth.uid()
                OR (
                f.household_id IS NOT NULL
                    AND f.household_id IN (
                    SELECT hm.household_id
                    FROM public.household_members hm
                    WHERE hm.user_id = auth.uid() AND hm.is_active = 1
                )
                )
            )
    )
    );

CREATE POLICY "Users can update shared recipe folders"
    ON public.recipe_folder_shares
    FOR UPDATE
    USING (
    -- Only the original sharer can update the share record.
    sharer_id = auth.uid()
    )
    WITH CHECK (
    sharer_id = auth.uid()
    );

CREATE POLICY "Users can delete shared recipe folders"
    ON public.recipe_folder_shares
    FOR DELETE
    USING (
    -- Only the sharer can delete the share record.
    sharer_id = auth.uid()
    );

-- COOKS -------------------------------
-- Enable RLS on the cooks table
ALTER TABLE public.cooks ENABLE ROW LEVEL SECURITY;

-- Policy for SELECT: Only the cook owner or household members can view a cook.
CREATE POLICY "Users can view their own cooks"
    ON public.cooks
    FOR SELECT
    USING (
    auth.uid() = user_id OR
    (household_id IS NOT NULL AND public.is_household_member(household_id, auth.uid()))
    );

-- Policy for INSERT: Only allow cooks to be created by the owner or by users who are members of the specified household.
CREATE POLICY "Users can insert cooks only for households they belong to"
    ON public.cooks
    FOR INSERT
    WITH CHECK (
    auth.uid() = user_id OR
    (household_id IS NOT NULL AND public.is_household_member(household_id, auth.uid()))
    );

-- Policy for UPDATE: Only allow the owner or household members to update a cook.
CREATE POLICY "Users can update cooks only for households they belong to"
    ON public.cooks
    FOR UPDATE
    USING (
    auth.uid() = user_id OR
    (household_id IS NOT NULL AND public.is_household_member(household_id, auth.uid()))
    )
    WITH CHECK (
    household_id IS NULL OR public.is_household_member(household_id, auth.uid())
    );
