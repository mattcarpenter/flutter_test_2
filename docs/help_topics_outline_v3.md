# Help Section Outline v3

Reorganized based on user feedback with progressively more detail. Structured for accordion-style help page.

---

## Section 1: Quick Questions (FAQ)

Short answers to common questions users might have.

---

### How do I pin a recipe for quick access?

- Tap the bookmark icon on the recipe's cover image
- Pinned recipes appear on your home screen
- Find all pinned recipes under "Pinned Recipes" section

**Implementation note:** Bookmark button located in recipe header (`lib/src/features/recipes/widgets/recipe_view/recipe_header.dart:136-144`)

---

### How do I add recipe ingredients to my shopping list?

- Open the recipe and tap the **... menu** in the top right
- Select **"Check Pantry"** from the menu
- In the pantry matching modal that opens, tap the **... button** again
- Select **"Add to Shopping List"**
- Select which ingredients you need (in-stock items unchecked by default)
- Choose which shopping list to add them to

**Implementation note:** Add to shopping list modal (`lib/src/features/recipes/widgets/add_to_shopping_list_modal.dart`), accessed via pantry matching sheet

---

### Can I have more than one shopping list?

- Yes, you can create multiple lists (e.g., "Costco", "Farmers Market")
- Tap the **... button in the top right** of the shopping list tab
- Select "Manage Lists" to create, switch, or delete lists
- The default "My Shopping List" cannot be deleted

**Implementation note:** Shopping list management accessed via overflow menu (`lib/src/features/shopping_list/widgets/shopping_list_header.dart`)

---

### How do I move purchased items to my pantry?

- Check off items as you buy them (tap the item)
- Tap the **"With marked..."** floating action button that appears at bottom-right
- Select "Update Pantry"
- Review and confirm which items to add or update
- Items become "In Stock" in your pantry

**Implementation details:**
- FAB: `lib/src/features/shopping_list/widgets/shopping_list_selection_fab.dart:26-39`
- Modal: `lib/src/features/shopping_list/views/update_pantry_modal.dart:49-97`
- Shows two sections: "Items to add" (new items with green "New item" chip) and "Items to update" (existing items showing status transition like "Out → In Stock")

---

### Where do I create tags?

- Tags are created while editing a recipe, not in settings
- Edit any recipe and look for the Tags section
- You can add existing tags or create new ones there
- Manage tag colors and delete tags in Settings > Manage Tags

**Implementation note:** Tag management in recipe edit form and settings screen

---

### How do I create a shopping list from my meal plan?

- Go to Meal Plans and find the date you want to shop for
- Tap the "..." menu on the date header
- Select "Add to Shopping List"
- Ingredients from all recipes that day are combined
- Duplicates are merged automatically

**Implementation note:** Meal plan context menu includes shopping list generation feature

---

### What's the difference between a folder and a smart folder?

- **Regular folders**: You manually add recipes to them
- **Smart folders**: Automatically collect recipes based on rules
  - Can be based on **specific tags** (e.g., all recipes tagged "Dessert")
  - Can be based on **ingredients** (e.g., all recipes containing "chicken")
- Smart folders update automatically when recipes match their criteria

**Implementation note:** Smart folder rules defined in folder edit modal (`lib/src/features/recipes/views/add_folder_modal.dart`)

---

### How do I change which tab opens when I start the app?

- Go to Settings > Home Screen
- Choose from: Recipes, Shopping, Meal Plan, or Pantry
- Note: Change takes effect next time you open the app

**Implementation note:** Home screen preference setting

---

### How do I make recipe text bigger?

- Go to Settings > Layout & Appearance
- Adjust "Recipe Font Size" (Small, Medium, Large)
- Preview shows immediately; applies to all recipes

**Implementation note:** Font size setting affects recipe view rendering

---

### Can I use cook mode with multiple recipes at the same time?

- Yes! Start cooking one recipe (tap "Start Cooking")
- Then tap **"Add Recipe"** in the cooking screen
- Switch between recipes using the cards at the bottom
- Each recipe tracks its own progress independently

**Implementation note:** Multi-recipe cooking mode (`lib/src/features/recipes/views/cook_mode/multi_recipe_cook_mode.dart`)

---

### How do I move a meal plan item to a different day?

- **Grab the drag handle** (three horizontal lines) on the right side of the item
- Drag it to a different date
- Note: You cannot reorder items within the same day currently

**Implementation note:** Meal plan items use drag handles for reordering (`lib/src/features/meal_plan/widgets/meal_plan_item_tile.dart`)

---

## Section 2: Troubleshooting

Problem-oriented questions for when something isn't working as expected.

---

### I added something to my pantry but it's not matching recipe ingredients

This usually happens when the ingredient and pantry item don't share any matching **aliases** (also called "terms" in the backend).

**What are aliases?**
- Aliases are alternative names used to match ingredients with pantry items
- For example, a recipe ingredient "mayo" can match a pantry item named "mayonnaise" if they share the alias "mayo"
- Aliases are automatically generated in the background when you create items (requires internet connection)

**Troubleshooting steps:**

1. **Check internet connectivity**: Alias generation requires a backend connection
   - If you added items while offline, aliases may not have been generated yet
   - Disconnect from VPN if applicable and wait a moment

2. **Manually check the aliases:**

   **For recipe ingredients:**
   - Open the recipe and view the ingredients list
   - Tap the **stock status chip** next to any ingredient (the colored chip on the right that says "In Stock", "Out", etc.)
   - This opens a multi-page detail sheet (`lib/src/features/recipes/widgets/recipe_view/ingredient_matches_bottom_sheet.dart`)
   - Tap an ingredient to see its detail page
   - View the **"Matching Terms"** section showing all aliases
   - You can add custom aliases here by tapping "Add Term"

   **For pantry items:**
   - Go to your Pantry tab
   - Tap on a pantry item to edit it
   - Opens edit modal (`lib/src/features/pantry/views/update_pantry_item_modal.dart`)
   - View the **"Matching Terms"** section showing all aliases
   - You can add, reorder (drag), or delete aliases here

3. **Add a custom alias if needed:**
   - If the ingredient and pantry item don't share any aliases, add one manually
   - For example, if your recipe has "buttermilk" but your pantry item is "Organic Buttermilk", add "buttermilk" as an alias to the pantry item

**Pro tips:**
- Use common, generic names for pantry items (e.g., "Milk" instead of "2% Organic Milk")
- Aliases are case-insensitive
- You can add as many aliases as you want
- Aliases can come from three sources: system (auto-generated), user (manually added), or pantry (linked to another pantry item)

**Implementation details:**
- Recipe ingredient aliases UI: `lib/src/features/recipes/widgets/recipe_view/ingredient_matches_bottom_sheet.dart:525-1685`
- Pantry item aliases UI: `lib/src/features/pantry/views/update_pantry_item_modal.dart:99-712`
- Matching logic: `lib/src/repositories/recipe_repository.dart:792-955`

---

### Why did "Update Pantry" create a duplicate instead of updating my existing item?

This happens when the shopping list item doesn't share any matching **aliases** with your existing pantry item.

**Example scenario:**
- Shopping list: "Whole milk"
- Pantry: "Milk"
- If these don't share an alias, the app creates a new pantry item instead of updating the existing one

**The modal shows you what will happen:**
- When you tap "Update Pantry" from the shopping list (via the "With marked..." button at bottom-right)
- The modal has two sections (`lib/src/features/shopping_list/views/update_pantry_modal.dart:220-288`):
  - **"Items to add"**: Shows items that will be created as NEW pantry items (green "New item" chip)
  - **"Items to update"**: Shows items that will UPDATE existing pantry items (with status transition like "Out → In Stock")
- Review these sections before confirming to catch potential duplicates

**How to fix duplicates:**
1. Delete the duplicate from your pantry
2. Add an alias to the remaining pantry item so it matches the shopping list item name
   - Example: Add "whole milk" as an alias to your "Milk" pantry item
3. Next time you update pantry from the shopping list, it will recognize the match

**How to avoid duplicates:**
- Use consistent naming between shopping list and pantry items
- Add common aliases to your pantry items
- Review the "Items to add" vs "Items to update" sections before confirming

**Implementation details:**
- Update pantry modal: `lib/src/features/shopping_list/views/update_pantry_modal.dart`
- Matching logic: `lib/src/features/shopping_list/services/pantry_update_service.dart:62-91`
- Uses term-based matching (case-insensitive comparison of all aliases)

---

### Why can't I join another household?

- You can only belong to **one household at a time**
- If you're already in a household, you must leave it first
- Go to Settings > Household and leave your current household
- Then you can accept the new invite

**Implementation note:** Household membership enforced in backend

---

### Why can't I leave my household?

- If you're the **owner**, you must transfer ownership first
- Select another member to become the new owner when leaving
- If you're the **only member**, leaving will delete the household entirely
- Your recipes will become personal (unshared) after leaving

**Implementation note:** Household ownership transfer flow in settings

---

### My invite link stopped working

- Invite links expire after a certain period
- Ask the household owner to generate a new invite
- Make sure you're not already in a household (see above)

**Implementation note:** Invite link expiration handled by backend

---

### I signed out and all my recipes disappeared

- Don't worry! Your recipes are still in the cloud
- **Solution**: Sign back in with the same account
- All your recipes, folders, pantry items, and meal plans will reappear
- The app stores data locally, but signing out switches to a "guest" mode

**Why this happens:**
- Data syncs with the cloud in the background
- When signed out, you're viewing local guest data (empty)
- When signed back in, your personal data syncs back down

**Data sync note:**
- If you sign out before sync completes, recent changes may be lost
- Wait for any sync warnings to clear before signing out
- Look for messages like "Some data hasn't finished syncing"

**Implementation note:** Auth state tied to data visibility via PowerSync

---

### Why are some ingredients already unchecked when adding to shopping list from a recipe?

- Items that are **already in your pantry** with "In Stock" status are unchecked by default
- Items that are **already on your shopping list** are also unchecked
- You can manually check/uncheck anything before adding

**Reasoning:** The app assumes you don't need to buy items you already have in stock.

**Implementation note:** Pre-filtering logic in add to shopping list modal

---

## Section 3: Understanding Key Features

Deeper explanations for features that need more context. These could be expandable "Learn more" sections.

---

### How Ingredient Matching Works

The app helps you see which recipes you can make with what's in your pantry. Here's how it works:

#### **Part 1: Understanding Aliases**

**What are aliases?**
- Aliases (also called "terms" in the backend) are alternative names used to match ingredients with pantry items
- Both recipe ingredients and pantry items have lists of aliases
- A **match** occurs when ANY alias from the recipe ingredient matches ANY alias from a pantry item

**Example:**
- Recipe ingredient: "mayonnaise" with aliases: ["mayonnaise", "mayo"]
- Pantry item: "Kewpie Mayo" with aliases: ["mayo", "mayonnaise", "kewpie"]
- ✅ **Match found** because "mayo" appears in both lists

**How are aliases generated?**
- **Automatically**: When you create a recipe ingredient or pantry item, the app sends the name to the backend
- The backend returns common variations and synonyms (requires internet connection)
- **Manually**: You can add your own custom aliases at any time
- **From pantry**: You can link a recipe ingredient to a specific pantry item, copying its aliases

**Where to view/manage aliases:**

**For recipe ingredients:**
1. Open any recipe and view the ingredients list
2. Tap the **stock status chip** (colored label on the right) next to any ingredient
3. In the bottom sheet that opens, tap the ingredient you want to manage
4. View/edit the **"Matching Terms"** section
5. Add custom terms via "Add Term" button (choose "Enter Custom Term" or "Select from Pantry")
6. Reorder terms by dragging (higher priority terms are checked first)

**Implementation:** `lib/src/features/recipes/widgets/recipe_view/ingredient_matches_bottom_sheet.dart:525-1685`

**For pantry items:**
1. Go to Pantry tab
2. Tap any item to edit it
3. View/edit the **"Matching Terms"** section
4. Add, reorder (drag), or delete aliases

**Implementation:** `lib/src/features/pantry/views/update_pantry_item_modal.dart:99-712`

**Alias sources:**
- **System**: Auto-generated by the backend (requires internet)
- **User**: Manually added by you
- **Pantry**: Copied from a specific pantry item you selected

**Matching behavior:**
- Case-insensitive (e.g., "Milk" matches "milk")
- Order matters: Higher priority terms are tried first
- First match wins: Once a match is found, no further terms are checked

**Offline handling:**
- If added while offline, aliases won't be generated until internet is restored
- Items wait in a queue and process automatically when connection returns
- You can always add custom aliases manually without internet

---

#### **Part 2: Stock Status and Recipe Display**

**What you see on recipe pages:**
- Each ingredient shows a **colored status chip** indicating its availability:
  - **Green "In Stock"**: Item is in your pantry with "In Stock" status, OR can be made via a sub-recipe
  - **Orange "Low Stock"**: Item is in your pantry but marked as low stock
  - **Red "Out"**: Item is in your pantry but marked as out of stock
  - **No chip**: Item has no match in your pantry at all

**Implementation:** Stock chips displayed at `lib/src/features/recipes/widgets/recipe_view/recipe_ingredients_view.dart:139-154`

**Tapping the chip:**
- Opens a detailed view showing all ingredients with their match status
- Ingredients grouped by:
  - **Available**: In stock or low stock or makeable via sub-recipe
  - **Out of Stock**: Items with direct pantry match marked out of stock
  - **Not in Pantry**: Items with no match at all
- Shows summary counts at the top
- Tap any ingredient to manage its aliases

**What counts as available:**
- **In Stock** pantry items ✅
- **Low Stock** pantry items ✅ (counts as available, but reminds you to restock)
- Items that can be made via a **sub-recipe** ✅ (e.g., "pie crust" ingredient matches "pie crust" recipe)
- **Out of Stock** items ❌ (doesn't count)
- **Not in Pantry** items ❌ (doesn't count)

**Sub-recipe matching:**
- If a recipe ingredient references another recipe (e.g., "homemade pasta"), it checks if that recipe is makeable
- If the sub-recipe is fully available, the ingredient shows as "In Stock" even without a pantry match
- This allows for component-based cooking (make parts of a recipe separately)

**Note: No percentage shown**
- The app does NOT show a "50% match" or any percentage anywhere in the UI
- You see only the colored chips indicating individual ingredient status
- The summary section shows counts like "12 available, 2 out of stock, 3 not in pantry"

**Implementation details:**
- Stock chip component: `lib/src/widgets/ingredient_stock_chip.dart:1-40`
- Visual styling: `lib/src/widgets/stock_chip.dart:1-109`
- Detailed matches sheet: `lib/src/features/recipes/widgets/recipe_view/ingredient_matches_bottom_sheet.dart:227-447`
- Matching logic: `lib/src/repositories/recipe_repository.dart:792-955`
- Real-time updates: `lib/src/providers/recipe_provider.dart:621-644` (auto-refreshes when pantry or recipe changes)

---

### Stock Status Explained

**Three levels:**
- **In Stock**: You have it, ready to use - counts for recipe matching ✅
- **Low Stock**: Running low, buy soon - counts for recipe matching ✅ but serves as a reminder
- **Out of Stock**: Completely out - doesn't count for matching ❌

**When to use each:**
- Mark "Low Stock" when you notice you're running out
- Mark "Out of Stock" when it's completely gone
- Update to "In Stock" after shopping (or use "Update Pantry" from shopping list)

**Visual indicators:**
- In Stock: Green chip/badge
- Low Stock: Orange/yellow chip/badge
- Out of Stock: Red chip/badge

**Implementation note:** Stock status enum defined in `lib/database/models/pantry_items.dart:6-11`

---

### How Households Work

**What is a household?**
- A group that shares all recipe data together
- One shared pantry, shopping list, and meal plan

**Key rules:**
- You can only be in **one household at a time**
- The person who creates it is the **owner**
- Owners can invite/remove members; members can use shared data

**What gets shared:**
- All recipes and folders
- The entire pantry
- All shopping lists
- All meal plans

**What stays personal:**
- Your account settings
- Your app preferences

**Implementation note:** Household sharing enforced via Supabase RLS and PowerSync sync rules

---

### Email vs Code Invites

**Email invites:**
- You enter the person's email address
- They receive an email with instructions
- Best when you know their email

**Code invites:**
- You get a shareable link/code
- Anyone with the link can join
- Best for sharing via text, social media, etc.
- You can give it a label like "John's Guest"

Both work the same way once accepted.

**Implementation note:** Invite system in household settings

---

### Cooking Mode Features

**Starting a cook:**
- Tap "Start Cooking" on any recipe page
- Navigate steps with Previous/Next buttons
- Section headers (like "For the sauce") don't count as steps

**Multi-recipe cooking:**
- Add more recipes with the "Add Recipe" button
- Recipe cards at the bottom show each recipe's progress
- Tap a card to switch to that recipe
- Each recipe tracks its own step progress independently

**Pausing and resuming:**
- Your progress is saved automatically
- Return to the recipe later and tap "Resume Cooking"
- Pick up exactly where you left off

**Implementation note:** Cook mode in `lib/src/features/recipes/views/cook_mode/` directory

---

## Topics to Add Based on User Feedback

Monitor support questions and add topics as patterns emerge:

- [ ] Password reset issues
- [ ] Account linking (Google/Apple sign-in)
- [ ] Recipe import/export (when implemented)
- [ ] Meal plan note editing (currently not implemented)
- [ ] Recipe sharing outside household (not implemented in UI)
- [ ] Smart folder AND vs OR tag logic
- [ ] Alias/term troubleshooting (when backend canonicalization fails)
- [ ] VPN interference with alias generation

---

## Structure Notes

**Suggested accordion organization:**

```
Help
├── Quick Questions
│   ├── Recipes & Cooking
│   │   ├── How do I pin a recipe?
│   │   ├── How do I add ingredients to shopping list?
│   │   ├── Can I use cook mode with multiple recipes?
│   │   └── How do I make recipe text bigger?
│   ├── Shopping & Pantry
│   │   ├── Can I have more than one shopping list?
│   │   ├── How do I move purchased items to pantry?
│   │   ├── Why are some ingredients unchecked when adding to shopping list?
│   │   └── How do I create shopping list from meal plan?
│   ├── Organization
│   │   ├── Where do I create tags?
│   │   ├── What's the difference between folder and smart folder?
│   │   └── How do I move a meal plan item?
│   └── Settings & Account
│       └── How do I change home screen tab?
├── Troubleshooting
│   ├── Matching Issues
│   │   ├── I added to pantry but it's not matching recipe ingredients
│   │   └── Why did update pantry create a duplicate?
│   ├── Household & Sharing Issues
│   │   ├── Why can't I join another household?
│   │   ├── Why can't I leave my household?
│   │   └── My invite link stopped working
│   └── Data & Sync Issues
│       └── I signed out and all my recipes disappeared
└── Learn More
    ├── How Ingredient Matching Works
    │   ├── Part 1: Understanding Aliases
    │   └── Part 2: Stock Status and Recipe Display
    ├── Stock Status Explained
    ├── How Households Work
    ├── Email vs Code Invites
    └── Cooking Mode Features
```

Consider adding a search bar if the help section grows beyond 25-30 items.

---

## Implementation Guidance for Help UI

**Key file paths for building the help screen:**

1. **Create help topics data model** with:
   - Question/title
   - Answer/content (markdown supported)
   - Category
   - Source file paths (optional, for "See implementation" links)

2. **Accordion component requirements:**
   - Expandable/collapsible sections
   - Support for nested accordions (category > questions)
   - Markdown rendering for answers
   - Search functionality (filter by question text)

3. **Suggested file structure:**
   ```
   lib/src/features/help/
   ├── models/
   │   └── help_topic.dart
   ├── data/
   │   └── help_topics.dart (static data matching this outline)
   ├── views/
   │   └── help_screen.dart
   └── widgets/
       ├── help_accordion.dart
       ├── help_category.dart
       └── help_search_bar.dart
   ```

4. **Navigation:**
   - Add "Help" option to Settings menu
   - Consider adding contextual help buttons throughout app (e.g., "?" icon in pantry screen linking to matching section)

5. **Future enhancements:**
   - Add "Was this helpful?" feedback buttons
   - Track which topics are viewed most often
   - Add contextual help tooltips linked to specific help topics