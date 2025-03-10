### 1. Overview
Documentation of key decisions related to the database schema, access control, and data sharing mechanisms in the recipe management application.

### 2. Context

- **App Overview:**

  The app enables users to create, manage, and organize recipes into folders. Users can also share folders with other individuals or with entire households.

- **User Types & Groups:**
    - **Individual Users:** Own recipes and folders (tracked by `user_id`).
    - **Households:** Group multiple users via `household_members`, granting them shared access to data tied to a household.
- **Core Data Model:**
    - **Recipes:** Owned by individual users, recipes are organized into folders.
    - **Folders:** Containers for recipes, owned by individual users, and optionally shared with other users or households. Folders can not be nested.
    - **Households:** Groups of users, enabling shared access to folders and recipes.
    - **Household Members:** Users who belong to a household, gaining shared access to household data.
    - **Recipe Folder Shares:** A table that tracks direct sharing of folders with individual users.
    - **User Household Shares:** A denormalized table that maps shared folders to all active members of a household.
- **Sharing Mechanisms:**
    - **Direct Sharing:**
        - Folder sharing is implemented so that an owner can share a folder with specific users using the `recipe_folder_shares` table.
        - Direct sharing of recipes is not supported. Recipes are accessible via the folders they belong to.
    - **Household Sharing:**
        - Members of households have shared access to folders and recipes owned by any household member. This is accomplished by keeping a `household_id` column on the recipes and folders tables.
    - **Household Sharing via Direct Shares:**
        - When a folder is directly shared with a user who belongs to a household, a _trigger_ populates the `user_household_shares` table to ensure that all household members can access the shared folder.
        - This denormalized table maps shared folders to all active household members, ensuring that if any member has a folder shared with them, every member of that household gains visibility (and possibly editing rights) to the folder and its recipes.
- **Technical Stack & Constraints:**
    - Postgres with Supabase, leveraging Row-Level Security (RLS) to enforce data access.
    - Powersync handles data synchronization
    - Triggers maintain derived data (e.g., in `user_household_shares`) to support efficient sync filtering.

---

### 3. Decisions

#### Folders cannot be nested
- Rationale: Simplifies the data model and sync rules.
  - Inheritance of sharing permissions from parent folders would require complicated triggers and sync rules, especially in the context of direct sharing with household members
  - UX challenges around one-to-many relationships between folders and recipes and what happens if a folder is deleted, or if a sharee creates a folder within a folder

#### Direct Sharing of Recipes is not supported
- Rationale: Doesn't scale well. Prefer importing (cloning) recipes instead.

#### Recipe to Folder Relationship is One-to-Many
- Rationale: Users may want to organize recipes based on multiple dimensions (e.g., cuisine, meal type, dietary restrictions)

#### Recipe to Folder Relationships stored in array column on recipes table
- Rationale: PowerSync does not support joins. Although a mapping table could have been used to support one-to-many in a single-owner or household scenario, the implicit sharing of an external user's folders with household members necessitates a denormalized structure.

#### Recipe steps and ingredients stored as JSON in recipes table
- Rationale: simplifies the data model and sync rules. sqlite can handle JSON, enabling querying and filtering based on recipe steps and ingredients.
