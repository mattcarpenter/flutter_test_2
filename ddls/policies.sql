-- Allow users to view only their own user record
CREATE POLICY "Enable users to view their own data only"
    ON users FOR SELECT
    USING (auth.uid() = id);

-- Allow users to update their own user record
CREATE POLICY "Enable users to update their own data"
    ON users FOR UPDATE
    USING (auth.uid() = id);

-- (Optional) Restrict users from deleting their own account
CREATE POLICY "Restrict users from deleting their account"
    ON users FOR DELETE
    USING (false); -- No users can delete their account unless explicitly overridden

-- Allow authenticated users to create a household
CREATE POLICY "Enable insert for authenticated users only"
    ON households FOR INSERT
    TO authenticated
    WITH CHECK (true);

-- Allow users to view only the household they belong to
CREATE POLICY "Enable users to view their own household only"
    ON households FOR SELECT
    USING (
    EXISTS (
        SELECT 1 FROM users
        WHERE id = auth.uid()
          AND users.household_id = households.id
    )
    );

-- Allow users to update their own household
CREATE POLICY "Enable users to update their household"
    ON households FOR UPDATE
    USING (
    EXISTS (
        SELECT 1 FROM users
        WHERE id = auth.uid()
          AND users.household_id = households.id
    )
    );

-- (Optional) Restrict users from deleting a household
CREATE POLICY "Restrict users from deleting households"
    ON households FOR DELETE
    USING (false);

-- Allow users to insert their own folders
CREATE POLICY "Enable insert for users based on user_id"
    ON recipe_folders FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- Allow users to update their own folders
CREATE POLICY "Enable update for users based on user_id"
    ON recipe_folders FOR UPDATE
    USING (auth.uid() = user_id);

-- Allow users to view their own folders
CREATE POLICY "Enable users to view their own data only"
    ON recipe_folders FOR SELECT
    USING (auth.uid() = user_id);

-- Allow users to view folders shared with them
CREATE POLICY "Enable users to view shared folders"
    ON recipe_folders FOR SELECT
    USING (
    EXISTS (
        SELECT 1 FROM shared_permissions
        WHERE entity_type = 'recipe_folder'
          AND entity_id = recipe_folders.id
          AND target_user_id = auth.uid()
    )
    );

-- Allow users to view folders in their household
CREATE POLICY "Enable users to view household folders"
    ON recipe_folders FOR SELECT
    USING (
    EXISTS (
        SELECT 1 FROM users
        WHERE id = auth.uid()
          AND household_id = recipe_folders.household_id
    )
    );

-- Allow users to insert their own recipes
CREATE POLICY "Enable insert for users based on user_id"
    ON recipes FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- Allow users to update their own recipes
CREATE POLICY "Enable update for users based on user_id"
    ON recipes FOR UPDATE
    USING (auth.uid() = user_id);

-- Allow users to view their own recipes
CREATE POLICY "Enable users to view their own data only"
    ON recipes FOR SELECT
    USING (auth.uid() = user_id);

-- Allow users to view recipes shared with them
CREATE POLICY "Enable users to view shared recipes"
    ON recipes FOR SELECT
    USING (
    EXISTS (
        SELECT 1 FROM shared_permissions
        WHERE entity_type = 'recipe'
          AND entity_id = recipes.id
          AND target_user_id = auth.uid()
    )
    );

-- Allow users to view recipes in their household
CREATE POLICY "Enable users to view household recipes"
    ON recipes FOR SELECT
    USING (
    EXISTS (
        SELECT 1 FROM users
        WHERE id = auth.uid()
          AND household_id = recipes.household_id
    )
    );

-- Allow only owners to share their folders/recipes
CREATE POLICY "Enable insert for owners of entities"
    ON shared_permissions FOR INSERT
    WITH CHECK (
    EXISTS (
        SELECT 1 FROM recipe_folders
        WHERE id = shared_permissions.entity_id
          AND shared_permissions.entity_type = 'recipe_folder'
          AND recipe_folders.user_id = auth.uid()
    ) OR
    EXISTS (
        SELECT 1 FROM recipes
        WHERE id = shared_permissions.entity_id
          AND shared_permissions.entity_type = 'recipe'
          AND recipes.user_id = auth.uid()
    )
    );

-- Allow only owners to remove sharing
CREATE POLICY "Enable delete for owners of entities"
    ON shared_permissions FOR DELETE
    USING (
    EXISTS (
        SELECT 1 FROM recipe_folders
        WHERE id = shared_permissions.entity_id
          AND shared_permissions.entity_type = 'recipe_fold er'
          AND recipe_folders.user_id = auth.uid()
    ) OR
    EXISTS (
        SELECT 1 FROM recipes
        WHERE id = shared_permissions.entity_id
          AND shared_permissions.entity_type = 'recipe'
          AND recipes.user_id = auth.uid()
    )
    );

---- Pantry and Shopping List
CREATE POLICY "Users can view their own pantry items"
    ON pantry_items
    FOR SELECT
    USING (
    auth.uid() = user_id
        OR (household_id IS NOT NULL AND is_household_member(household_id, auth.uid()))
    );

CREATE POLICY "Users can insert pantry items"
    ON pantry_items
    FOR INSERT
    WITH CHECK (
    auth.uid() = user_id
        OR (household_id IS NOT NULL AND is_household_member(household_id, auth.uid()))
    );

CREATE POLICY "Users can update pantry items"
    ON pantry_items
    FOR UPDATE
    USING (
    auth.uid() = user_id
        OR (household_id IS NOT NULL AND is_household_member(household_id, auth.uid()))
    )
    WITH CHECK (
    household_id IS NULL OR is_household_member(household_id, auth.uid())
    );

CREATE POLICY "Users can view their own shopping lists"
    ON shopping_lists
    FOR SELECT
    USING (
    auth.uid() = user_id
        OR (household_id IS NOT NULL AND is_household_member(household_id, auth.uid()))
    );

CREATE POLICY "Users can insert shopping lists"
    ON shopping_lists
    FOR INSERT
    WITH CHECK (
    auth.uid() = user_id
        OR (household_id IS NOT NULL AND is_household_member(household_id, auth.uid()))
    );

CREATE POLICY "Users can update shopping lists"
    ON shopping_lists
    FOR UPDATE
    USING (
    auth.uid() = user_id
        OR (household_id IS NOT NULL AND is_household_member(household_id, auth.uid()))
    )
    WITH CHECK (
    household_id IS NULL OR is_household_member(household_id, auth.uid())
    );

CREATE POLICY "Users can view shopping list items"
    ON shopping_list_items
    FOR SELECT
    USING (
    auth.uid() = user_id
        OR (household_id IS NOT NULL AND is_household_member(household_id, auth.uid()))
    );

CREATE POLICY "Users can insert shopping list items"
    ON shopping_list_items
    FOR INSERT
    WITH CHECK (
    auth.uid() = user_id
        OR (household_id IS NOT NULL AND is_household_member(household_id, auth.uid()))
    );

CREATE POLICY "Users can update shopping list items"
    ON shopping_list_items
    FOR UPDATE
    USING (
    auth.uid() = user_id
        OR (household_id IS NOT NULL AND is_household_member(household_id, auth.uid()))
    )
    WITH CHECK (
    household_id IS NULL OR is_household_member(household_id, auth.uid())
    );

CREATE POLICY "Users can view recipe ingredient term overrides"
    ON recipe_ingredient_term_overrides
    FOR SELECT
    USING (
    auth.uid() = user_id
        OR (household_id IS NOT NULL AND is_household_member(household_id, auth.uid()))
    );

CREATE POLICY "Users can insert recipe ingredient term overrides"
    ON recipe_ingredient_term_overrides
    FOR INSERT
    WITH CHECK (
    auth.uid() = user_id
        OR (household_id IS NOT NULL AND is_household_member(household_id, auth.uid()))
    );

CREATE POLICY "Users can update recipe ingredient term overrides"
    ON recipe_ingredient_term_overrides
    FOR UPDATE
    USING (
    auth.uid() = user_id
        OR (household_id IS NOT NULL AND is_household_member(household_id, auth.uid()))
    )
    WITH CHECK (
    household_id IS NULL OR is_household_member(household_id, auth.uid())
    );

CREATE POLICY "Users can delete recipe ingredient term overrides"
    ON recipe_ingredient_term_overrides
    FOR DELETE
    USING (
    auth.uid() = user_id
        OR (household_id IS NOT NULL AND is_household_member(household_id, auth.uid()))
    );
