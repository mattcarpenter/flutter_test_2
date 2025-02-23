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
