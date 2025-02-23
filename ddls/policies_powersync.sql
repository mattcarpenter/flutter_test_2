CREATE POLICY "Users can view their own folders"
    ON recipe_folders
    FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own folders"
    ON recipe_folders
    FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can soft delete their own folders"
    ON recipe_folders
    FOR UPDATE
    USING (auth.uid() = user_id)
    WITH CHECK (deleted_at IS NULL OR auth.uid() = user_id);


-- RECIPES -------------------------------

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

CREATE POLICY "Users can view their own membership or members of households they own"
    ON public.household_members
    FOR SELECT
    USING (
    auth.uid() = user_id
        OR EXISTS (
        SELECT 1
        FROM public.households h
        WHERE h.id = household_members.household_id
          AND h.user_id = auth.uid()
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

CREATE POLICY "Users can delete their own membership or household owners can remove members"
    ON public.household_members
    FOR DELETE
    USING (
    auth.uid() = user_id
        OR EXISTS (
        SELECT 1
        FROM public.households h
        WHERE h.id = household_members.household_id
          AND h.user_id = auth.uid()
    )
    );

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
CREATE POLICY "Users can view recipe_folder_shares relevant to them"
    ON public.recipe_folder_shares
    FOR SELECT
    USING (
    (user_id IS NOT NULL AND auth.uid() = user_id)
        OR
    (household_id IS NOT NULL AND EXISTS (
        SELECT 1 FROM public.household_members hm
        WHERE hm.household_id = recipe_folder_shares.household_id
          AND hm.user_id = auth.uid()
    ))
    );

CREATE POLICY "Users can insert recipe_folder_shares for folders they share"
    ON public.recipe_folder_shares
    FOR INSERT
    WITH CHECK (
    (user_id IS NOT NULL AND auth.uid() = user_id)
        OR
    (household_id IS NOT NULL AND EXISTS (
        SELECT 1 FROM public.household_members hm
        WHERE hm.household_id = recipe_folder_shares.household_id
          AND hm.user_id = auth.uid()
    ))
    );

CREATE POLICY "Users can update recipe_folder_shares relevant to them"
    ON public.recipe_folder_shares
    FOR UPDATE
    USING (
    (user_id IS NOT NULL AND auth.uid() = user_id)
        OR
    (household_id IS NOT NULL AND EXISTS (
        SELECT 1 FROM public.household_members hm
        WHERE hm.household_id = recipe_folder_shares.household_id
          AND hm.user_id = auth.uid()
    ))
    )
    WITH CHECK (
    (user_id IS NOT NULL AND auth.uid() = user_id)
        OR
    (household_id IS NOT NULL AND EXISTS (
        SELECT 1 FROM public.household_members hm
        WHERE hm.household_id = recipe_folder_shares.household_id
          AND hm.user_id = auth.uid()
    ))
    );

