# Household Sharing: Next Steps

After thoroughly examining the codebase, I now have a good understanding of how household data sharing works in the application. Here's my recommendation for managing pre-existing entities when a household is created or a user joins one:

## Current Implementation Analysis

1. **RLS Policies**: The application has well-defined row-level security policies in Postgres that control access to recipes and other entities based on user_id and household_id. Users can see items they own directly (user_id matches) or items shared with their household (household_id matches a household they belong to).

2. **Database Triggers**: There are existing triggers in `triggers_powersync.sql` that automatically update recipe folders when a user joins a household, specifically:
   - `assign_household_to_folders_on_member_addition()` (for updates)
   - `assign_household_to_folders_on_member_insert()` (for inserts)
   
   These triggers set the household_id for all folders owned by a user who joins a household, making them available to all household members.

3. **Sync Rules**: PowerSync configuration in `sync_rules.yaml` defines how data is synced to clients, with rules for user-specific data and household-specific data.

4. **Current Gaps**: While triggers exist for folders, there are no equivalent triggers for recipes, pantry items, and other entity types. This is the primary gap in the current implementation.

## Recommendation: Database Triggers Approach

I recommend extending the existing database trigger pattern to handle all entity types. This approach is consistent with your current architecture, scalable, and minimizes client-side complexity.

### Implementation Steps:

1. **Create Generic Database Triggers**: Add SQL triggers that automatically update household_id on existing entities when:
   - A user creates a household
   - A user joins a household
   - A user leaves a household

Here's a sample implementation:

```sql
-- Update recipes when a user joins a household (insert)
CREATE OR REPLACE FUNCTION assign_household_to_recipes_on_member_insert()
    RETURNS TRIGGER AS $$
BEGIN
    -- Update existing recipes
    UPDATE public.recipes
    SET household_id = NEW.household_id
    WHERE user_id = NEW.user_id AND household_id IS NULL;
    
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_assign_household_to_recipes_insert
    AFTER INSERT ON public.household_members
    FOR EACH ROW
EXECUTE FUNCTION assign_household_to_recipes_on_member_insert();

-- Update recipes when a user's household membership is activated
CREATE OR REPLACE FUNCTION assign_household_to_recipes_on_member_activation()
    RETURNS TRIGGER AS $$
BEGIN
    -- Only run when membership is activated
    IF NEW.is_active = 1 AND (OLD.is_active <> 1 OR OLD.household_id <> NEW.household_id) THEN
        UPDATE public.recipes
        SET household_id = NEW.household_id
        WHERE user_id = NEW.user_id AND household_id IS NULL;
    END IF;
    
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_assign_household_to_recipes_activation
    AFTER UPDATE ON public.household_members
    FOR EACH ROW
EXECUTE FUNCTION assign_household_to_recipes_on_member_activation();

-- Clear household_id when a user leaves a household
CREATE OR REPLACE FUNCTION cleanup_recipes_on_member_removal()
    RETURNS TRIGGER AS $$
BEGIN
    UPDATE public.recipes
    SET household_id = NULL
    WHERE user_id = OLD.user_id AND household_id = OLD.household_id;
    
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_cleanup_recipes
    AFTER UPDATE ON public.household_members
    FOR EACH ROW
    WHEN (NEW.is_active = 0)  -- Only trigger when the user is removed
EXECUTE FUNCTION cleanup_recipes_on_member_removal();
```

2. **Repeat for Other Entity Types**: Create similar triggers for pantry items, shopping lists, and any other entity types that should be shared within a household.

3. **Optional User Control**: If users should be able to choose which items are shared with their household, add a flag like `is_shared_with_household` to each entity type that defaults to true. This gives users control over which items are automatically shared.

## Benefits of This Approach:

1. **Consistency**: The database handles the sharing logic, ensuring consistency across all clients.
2. **Scalability**: The approach works with any number of entities and users.
3. **Simplicity**: Client code doesn't need complex sharing logic.
4. **Performance**: Bulk updates happen efficiently at the database level.
5. **Maintainability**: Database triggers are a standard pattern for handling cascading changes.

## Limitations and Considerations:

1. **Selective Sharing**: In the base implementation, all pre-existing items are shared when a user joins a household. If more selective sharing is needed, consider:
   - Adding the optional flag mentioned above
   - Creating a UI that lets users choose which items to share after joining a household
   
2. **Migration Strategy**: For existing users, consider a one-time migration script to ensure correct household assignments.

3. **Recovery**: If a user leaves a household accidentally, their items may lose the household_id. Consider adding a mechanism to recover/restore sharing relationships.

This approach leverages the existing architecture while filling the gaps in the current implementation, providing a complete solution for household sharing that handles both newly created entities and pre-existing ones.