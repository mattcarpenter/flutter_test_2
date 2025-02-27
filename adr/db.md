### 1. Overview
TBD

### 2. Context

- **App Overview:**

  The app enables users to create, manage, and organize recipes into folders. Users can also share folders with other individuals or with entire households.

- **User Types & Groups:**
    - **Individual Users:** Own recipes and folders (tracked by `user_id`).
    - **Households:** Group multiple users via `household_members`, granting them shared access to data tied to a household.
- **Sharing Mechanisms:**
    - **Direct Sharing (Folders Only):**
        - Folder sharing is implemented so that an owner can share a folder with specific users.
        - Although a `recipes_shares` table exists as a leftover, direct sharing of recipes is not supported. Recipes are accessible via the folders they belong to.
    - **Household Sharing via Direct Shares:**
        - When a folder is directly shared with a user who belongs to a household, the `user_household_shares` table is used.
        - This denormalized table maps shared folders to all active household members, ensuring that if any member has a folder shared with them, every member of that household gains visibility (and possibly editing rights) to the folder and its recipes.
- **Technical Stack & Constraints:**
    - Postgres with Supabase, leveraging Row-Level Security (RLS) to enforce data access.
    - Powersync handles data synchronization, and sync rules benefit from denormalizing key fields like `household_id`.
    - Triggers maintain derived data (e.g., in `user_household_shares`) to support efficient sync filtering.

---

### 3. Decision

**Primary Decision:**

Adopt a layered permissions model that integrates ownership, household membership, and sharing (via folders) as follows:

1. **Ownership-based Permissions (RLS):**
    - Recipes and folders are secured by verifying that `auth.uid() = user_id`.
    - RLS policies ensure that users can only view, update, or delete data they own unless that data is explicitly shared.
2. **Household-Based Access:**
    - Each recipe or folder optionally carries a denormalized `household_id` field.
    - RLS policies permit access if the user’s household membership matches the record’s `household_id`.
    - This simplifies syncing by avoiding complex joins.
3. **Sharing (Direct and Household):**
    - **Direct Sharing (Folders Only):**
        - Sharing is implemented exclusively for folders; recipes inherit sharing access via the folders they reside in.
        - RLS policies check the `recipe_folder_shares` table to determine if a folder has been directly shared with a user.
    - **Household Extension of Direct Shares:**
        - The `user_household_shares` table expands sharing by linking directly shared folders to all active members of the target household.
        - This mechanism ensures that if one household member has a folder shared with them, all members can access it (along with its recipes) through tailored sync policies.
4. **Sync Rules (Powersync):**
    - **Buckets are defined** to deliver data based on ownership (`belongs_to_user`), household membership (`belongs_to_household`), and sharing (both direct and household-based via `shared_folder_direct` and `shared_folder_household`).
    - This ensures that users sync only the records they’re permitted to access, improving performance and security.

---

### 4. Rationale

- **Security at the Database Level:**
    - RLS provides a robust defense, ensuring unauthorized access is prevented even if the application layer is bypassed.
- **Efficient and Simplified Syncing:**
    - Denormalizing the `household_id` and precomputing shared relationships (via `user_household_shares`) reduce the need for complex joins in the sync layer.
- **Focused Sharing Approach:**
    - By limiting direct sharing to folders only, the model avoids redundancy and simplifies management. Recipes are indirectly shared as part of the folders.
    - The use of `user_household_shares` ensures that when a folder is shared with any household member, all members benefit, aligning with the natural group dynamic of a household.

---

### 5. Consequences

- **Pros:**
    - **Enhanced Data Security:** RLS policies guarantee that each query enforces ownership, household, and sharing restrictions.
    - **Optimized Synchronization:** Denormalized data and precomputed share relationships improve sync performance and simplify query logic.
    - **Clear Sharing Semantics:** Focusing on folder sharing (with recipes accessed through folders) reduces complexity, and the household extension via `user_household_shares` ensures consistent visibility among household members.
- **Cons:**
    - **Maintenance Complexity:** Triggers and derived tables add layers of complexity that require careful management and testing.
    - **Data Redundancy:** Denormalization introduces some duplication, which must be managed to ensure data consistency.

---

### 6. Alternatives Considered

- **Direct Recipe Sharing:**
    - Initially, a mechanism for directly sharing recipes was considered, but it was ultimately dropped in favor of a simpler, folder-centric approach.
- **Full Normalization:**
    - Maintaining all relationships in a normalized form was an option; however, it would complicate the sync layer and impact performance negatively.
- **Application-Level Access Control Only:**
    - Relying solely on the application for enforcing permissions was rejected in favor of the more secure and resilient RLS-based approach.

---

### 7. Summary

- **Ownership & Household Integration:**
    - Each record (recipe or folder) is tied to a user and may be linked to a household, enabling automatic sharing among household members.
- **Folder-Centric Sharing:**
    - Direct sharing is implemented exclusively for folders. Direct sharing of recipes is not supported—recipes are accessible through their parent folder.
- **Extended Household Sharing:**
    - The `user_household_shares` table ensures that folders shared with an individual are visible to all members of the respective household.
- **RLS and Sync Integration:**
    - RLS policies and Powersync buckets work together to ensure that users only access data they’re authorized to see, whether through ownership, household membership, or direct sharing.

---
### Notes on Sharing

- **Direct Folder Sharing:**
    - **Table:** `recipe_folder_shares`
    - **Key Columns:**
        - `folder_id`: Identifies the folder being shared.
        - `sharer_id`: The owner who initiates the share.
        - `target_user_id`: Specifies an individual recipient for a direct share.
        - `target_household_id`: Specifies a household for sharing, so that every active member gains access.
        - `can_edit`: Indicates if the recipient has edit permissions.
        - `created_at`: Timestamp for when the share was created.
- **Extended Household Sharing:**
    - **Table:** `user_household_shares`
    - **Purpose:**
        - When a folder is shared directly with a user who belongs to a household, triggers automatically populate this table to map the shared folder to all active members of that household. This ensures that all household members see the shared folder (and its recipes) regardless of the original direct share being to one individual.
- **Security via RLS:**
    - Row-Level Security (RLS) policies enforce that a folder is accessible only if the user is either its owner (checked via `user_id`) or if there is a valid share record—either in `recipe_folder_shares` or via the derived `user_household_shares`.
    - This guarantees that unauthorized users cannot access shared folders, and that the access is dynamically adjusted based on sharing settings and household membership.
- **Relevant Triggers:**
    - **For Folder Sharing:**
        - `trg_rfs_after_insert`, `trg_rfs_after_delete`, and `trg_rfs_after_update` ensure that any change in folder sharing (insert, update, or delete) is reflected in the `user_household_shares` table.
    - **For Household Membership Changes:**
        - Triggers like `trg_hm_after_insert`, `trg_hm_after_update`, and `trg_hm_after_delete` keep the share mappings current as users join, update, or leave households.
