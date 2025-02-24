create table public.recipe_folders (
                                       id uuid not null default extensions.uuid_generate_v4 (),
                                       name text not null,
                                       user_id uuid null,
                                       parent_id uuid null,
                                       household_id uuid null,
                                       deleted_at bigint null,
                                       constraint recipe_folders_pkey primary key (id),
                                       constraint recipe_folders_household_id_fkey foreign KEY (household_id) references households (id) on delete CASCADE,
                                       constraint recipe_folders_parent_id_fkey foreign KEY (parent_id) references recipe_folders (id) on delete set null,
                                       constraint recipe_folders_user_id_fkey foreign KEY (user_id) references auth.users (id) on delete CASCADE
) TABLESPACE pg_default;

create index IF not exists recipe_folders_user_idx on public.recipe_folders using btree (user_id) TABLESPACE pg_default;

create index IF not exists recipe_folders_household_idx on public.recipe_folders using btree (household_id) TABLESPACE pg_default;

create index IF not exists recipe_folders_parent_idx on public.recipe_folders using btree (parent_id) TABLESPACE pg_default;

-- RECIPES -------------------------------

CREATE TABLE public.recipes (
                                id uuid NOT NULL DEFAULT extensions.uuid_generate_v4(),
                                title text NOT NULL,
                                description text NULL,
                                rating integer NOT NULL,
                                language text NOT NULL,
                                servings integer NULL,
                                prep_time integer NULL,
                                cook_time integer NULL,
                                total_time integer NULL,
                                source text NULL,
                                nutrition text NULL,
                                general_notes text NULL,
                                user_id uuid NULL,
                                household_id uuid NULL,
                                created_at bigint NULL,
                                updated_at bigint NULL,
                                CONSTRAINT recipes_pkey PRIMARY KEY (id),
                                CONSTRAINT recipes_folder_id_fkey FOREIGN KEY (folder_id) REFERENCES public.recipe_folders (id) ON DELETE SET NULL,
                                CONSTRAINT recipes_household_id_fkey FOREIGN KEY (household_id) REFERENCES public.households (id) ON DELETE CASCADE,
                                CONSTRAINT recipes_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users (id) ON DELETE CASCADE
) TABLESPACE pg_default;

-- Indexes
CREATE INDEX IF NOT EXISTS recipes_user_idx ON public.recipes USING btree (user_id) TABLESPACE pg_default;
CREATE INDEX IF NOT EXISTS recipes_folder_idx ON public.recipes USING btree (folder_id) TABLESPACE pg_default;
CREATE INDEX IF NOT EXISTS recipes_household_idx ON public.recipes USING btree (household_id) TABLESPACE pg_default;

-- RECIPE FOLDER ASSIGNMENTS -------------------------------
CREATE TABLE public.recipe_folder_assignments (
                                                  id uuid NOT NULL DEFAULT extensions.uuid_generate_v4(),
                                                  recipe_id uuid NOT NULL,
                                                  folder_id uuid NOT NULL,
                                                  user_id uuid NOT NULL,
                                                  household_id uuid, -- NEW: Denormalized household id
                                                  created_at bigint NULL,
                                                  CONSTRAINT recipe_folder_assignments_pkey PRIMARY KEY (id),
                                                  CONSTRAINT recipe_folder_assignments_recipe_id_fkey FOREIGN KEY (recipe_id)
                                                      REFERENCES public.recipes (id) ON DELETE CASCADE,
                                                  CONSTRAINT recipe_folder_assignments_folder_id_fkey FOREIGN KEY (folder_id)
                                                      REFERENCES public.recipe_folders (id) ON DELETE CASCADE,
                                                  CONSTRAINT recipe_folder_assignments_household_id_fkey FOREIGN KEY (household_id)
                                                      REFERENCES public.households (id) ON DELETE CASCADE,
                                                  CONSTRAINT recipe_folder_assignments_user_id_fkey FOREIGN KEY (user_id)
                                                      REFERENCES auth.users (id) ON DELETE CASCADE
) TABLESPACE pg_default;

-- Indexes for performance:
CREATE INDEX IF NOT EXISTS rfa_recipe_idx
    ON public.recipe_folder_assignments (recipe_id) TABLESPACE pg_default;
CREATE INDEX IF NOT EXISTS rfa_folder_idx
    ON public.recipe_folder_assignments (folder_id) TABLESPACE pg_default;
CREATE INDEX IF NOT EXISTS rfa_household_idx
    ON public.recipe_folder_assignments (household_id) TABLESPACE pg_default;
CREATE INDEX IF NOT EXISTS rfa_user_idx
    ON public.recipe_folder_assignments (user_id) TABLESPACE pg_default;




-- HOUSEHOLDS -------------------------------
CREATE TABLE public.households (
                                   id uuid NOT NULL DEFAULT extensions.uuid_generate_v4(),
                                   name text NOT NULL,
                                   user_id uuid NOT NULL,
                                   CONSTRAINT households_pkey PRIMARY KEY (id),
                                   CONSTRAINT households_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users (id) ON DELETE CASCADE
) TABLESPACE pg_default;

-- HOUSEHOLDS MEMBERS -------------------------------
CREATE TABLE public.household_members (
                                          id uuid NOT NULL DEFAULT extensions.uuid_generate_v4(),
                                          household_id uuid NOT NULL,
                                          user_id uuid NOT NULL,
                                          is_active integer NOT NULL DEFAULT 1,
                                          CONSTRAINT household_members_pkey PRIMARY KEY (household_id, user_id),
                                          CONSTRAINT household_members_household_id_fkey FOREIGN KEY (household_id)
                                              REFERENCES public.households (id) ON DELETE CASCADE,
                                          CONSTRAINT household_members_user_id_fkey FOREIGN KEY (user_id)
                                              REFERENCES auth.users (id) ON DELETE CASCADE
) TABLESPACE pg_default;

CREATE INDEX IF NOT EXISTS household_members_household_idx
    ON public.household_members USING btree (household_id) TABLESPACE pg_default;
CREATE INDEX IF NOT EXISTS household_members_user_idx
    ON public.household_members USING btree (user_id) TABLESPACE pg_default;

-- RECIPE SHARES -------------------------------
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

-- Optionally, add indexes to speed up lookups:
CREATE INDEX IF NOT EXISTS recipe_shares_recipe_idx ON public.recipe_shares (recipe_id);
CREATE INDEX IF NOT EXISTS recipe_shares_household_idx ON public.recipe_shares (household_id);
CREATE INDEX IF NOT EXISTS recipe_shares_user_idx ON public.recipe_shares (user_id);

-- RECIPE FOLDER SHARES -------------------------------

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

-- Indexes for faster lookups:
CREATE INDEX IF NOT EXISTS recipe_folder_shares_target_user_idx
    ON public.recipe_folder_shares (target_user_id) TABLESPACE pg_default;
CREATE INDEX IF NOT EXISTS recipe_folder_shares_target_household_idx
    ON public.recipe_folder_shares (target_household_id) TABLESPACE pg_default;
CREATE INDEX IF NOT EXISTS recipe_folder_shares_folder_idx
    ON public.recipe_folder_shares (folder_id) TABLESPACE pg_default;

-- DENORMALIZED RECIPE FOLDER SHARES for HOUSEHOLDS -------------------------------
CREATE TABLE public.user_household_shares (
                                              user_id uuid NOT NULL,
                                              household_id uuid NOT NULL,
                                              folder_id uuid NOT NULL,
                                              PRIMARY KEY (user_id, household_id, folder_id),
                                              CONSTRAINT uhs_user_fkey FOREIGN KEY (user_id) REFERENCES auth.users (id) ON DELETE CASCADE,
                                              CONSTRAINT uhs_folder_fkey FOREIGN KEY (folder_id) REFERENCES public.recipe_folders (id) ON DELETE CASCADE,
                                              CONSTRAINT uhs_household_fkey FOREIGN KEY (household_id) REFERENCES public.households (id) ON DELETE CASCADE
);
