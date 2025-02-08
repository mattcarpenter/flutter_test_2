-- Users Table
CREATE TABLE users (
                       _brick_id SERIAL,  -- Auto-incrementing ID for Brick (not primary, not unique)
                       id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
                       name TEXT NOT NULL,
                       email TEXT NOT NULL UNIQUE
);

-- Households Table
CREATE TABLE households (
                            _brick_id SERIAL,
                            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
                            name TEXT NOT NULL
);

-- Recipe Folders Table
CREATE TABLE recipe_folders (
                                _brick_id SERIAL,
                                id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
                                name TEXT NOT NULL,
                                parent_id UUID NULL REFERENCES recipe_folders(id) ON DELETE SET NULL,
                                user_id UUID REFERENCES users(id) ON DELETE CASCADE,
                                household_id UUID REFERENCES households(id) ON DELETE CASCADE,
                                deleted_at TIMESTAMP NULL
);

CREATE INDEX idx_recipe_folders_user_id ON recipe_folders(user_id);
CREATE INDEX idx_recipe_folders_household_id ON recipe_folders(household_id);
CREATE INDEX idx_recipe_folders_deleted_at ON recipe_folders(deleted_at);

-- Recipes Table
CREATE TABLE recipes (
                         _brick_id SERIAL,
                         id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
                         title TEXT NOT NULL,
                         content TEXT NOT NULL,
                         folder_id UUID REFERENCES recipe_folders(id) ON DELETE SET NULL,
                         user_id UUID REFERENCES users(id) ON DELETE CASCADE,
                         household_id UUID REFERENCES households(id) ON DELETE CASCADE,
                         deleted_at TIMESTAMP NULL
);

CREATE INDEX idx_recipes_folder_id ON recipes(folder_id);
CREATE INDEX idx_recipes_user_id ON recipes(user_id);
CREATE INDEX idx_recipes_household_id ON recipes(household_id);
CREATE INDEX idx_recipes_deleted_at ON recipes(deleted_at);

-- Shared Permissions Table
CREATE TABLE shared_permissions (
                                    _brick_id SERIAL,
                                    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
                                    entity_type TEXT NOT NULL CHECK (entity_type IN ('recipe', 'recipe_folder')),
                                    entity_id UUID NOT NULL,
                                    owner_id UUID REFERENCES users(id) ON DELETE CASCADE,
                                    target_user_id UUID REFERENCES users(id) ON DELETE CASCADE,
                                    access_level TEXT NOT NULL CHECK (access_level IN ('read-only', 'read-write'))
);

CREATE INDEX idx_shared_permissions_owner_id ON shared_permissions(owner_id);
CREATE INDEX idx_shared_permissions_target_user_id ON shared_permissions(target_user_id);
CREATE INDEX idx_shared_permissions_entity_id ON shared_permissions(entity_id);

ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE households ENABLE ROW LEVEL SECURITY;
ALTER TABLE recipe_folders ENABLE ROW LEVEL SECURITY;
ALTER TABLE recipes ENABLE ROW LEVEL SECURITY;
ALTER TABLE shared_permissions ENABLE ROW LEVEL SECURITY;

ALTER TABLE users ADD COLUMN household_id UUID NULL REFERENCES households(id) ON DELETE SET NULL;

CREATE INDEX idx_users_household_id ON users(household_id);
