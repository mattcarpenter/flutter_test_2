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
                                          CONSTRAINT household_members_pkey PRIMARY KEY (household_id, user_id),
                                          CONSTRAINT household_members_household_id_fkey FOREIGN KEY (household_id) REFERENCES public.households (id) ON DELETE CASCADE,
                                          CONSTRAINT household_members_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users (id) ON DELETE CASCADE
) TABLESPACE pg_default;

CREATE INDEX IF NOT EXISTS household_members_household_idx
    ON public.household_members USING btree (household_id) TABLESPACE pg_default;
CREATE INDEX IF NOT EXISTS household_members_user_idx
    ON public.household_members USING btree (user_id) TABLESPACE pg_default;

-- 3. RECIPE FOLDERS (Depends on households and auth.users)
CREATE TABLE public.recipe_folders (
                                       id uuid NOT NULL DEFAULT extensions.uuid_generate_v4(),
                                       name text NOT NULL,
                                       user_id uuid NULL,
                                       household_id uuid NULL,
                                       deleted_at bigint NULL,
                                       CONSTRAINT recipe_folders_pkey PRIMARY KEY (id),
                                       CONSTRAINT recipe_folders_household_id_fkey FOREIGN KEY (household_id) REFERENCES public.households (id) ON DELETE CASCADE,
                                       CONSTRAINT recipe_folders_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users (id) ON DELETE CASCADE
) TABLESPACE pg_default;

CREATE INDEX IF NOT EXISTS recipe_folders_user_idx
    ON public.recipe_folders USING btree (user_id) TABLESPACE pg_default;
CREATE INDEX IF NOT EXISTS recipe_folders_household_idx
    ON public.recipe_folders USING btree (household_id) TABLESPACE pg_default;

-- 4. RECIPES (Depends on recipe_folders, households, and auth.users)
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
                                folder_ids text null,
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

CREATE PUBLICATION powersync FOR ALL TABLES;
