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

CREATE PUBLICATION powersync FOR ALL TABLES;
