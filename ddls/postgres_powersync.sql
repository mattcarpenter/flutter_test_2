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
                                folder_id uuid NULL,
                                household_id uuid NULL,
                                created_at bigint NULL,
                                updated_at bigint NULL,
                                CONSTRAINT recipes_pkey PRIMARY KEY (id),
                                CONSTRAINT recipes_folder_id_fkey FOREIGN KEY (folder_id) REFERENCES public.recipe_folders (id) ON DELETE SET NULL,
                                CONSTRAINT recipes_household_id_fkey FOREIGN KEY (household_id) REFERENCES public.households (id) ON DELETE CASCADE,
                                CONSTRAINT recipes_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users (id) ON DELETE CASCADE
) TABLESPACE pg_default;

CREATE INDEX IF NOT EXISTS recipes_user_idx
    ON public.recipes USING btree (user_id) TABLESPACE pg_default;

CREATE INDEX IF NOT EXISTS recipes_folder_idx
    ON public.recipes USING btree (folder_id) TABLESPACE pg_default;

CREATE INDEX IF NOT EXISTS recipes_household_idx
    ON public.recipes USING btree (household_id) TABLESPACE pg_default;
