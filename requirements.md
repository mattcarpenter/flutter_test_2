We’ve got a skeleton meal plans page in this app and your task is to implement this feture. the skeleton page is here: lib/src/features/meal_plans/views/meal_plans_root.dart

- Requirements
    - List of dates - infinite scrolling I guess since that’s what the other apps do
    - Each date is a card
    - Each card has a + button and a … button in its header
    - + button shows a context menu with:
        - Add Recipe
        - Add Note
    - … shows a context menu with:
        - Check Pantry
        - Add to Shopping List
        - Clear Items
    - All these functions (except clear items) under both buttons should launch different wolt modal bottom sheets. you can use lib/src/features/pantry/views/add_pantry_item_modal.dart as an implementation reference.
    - we’ll need add a new drift model called meal_plans
        - each will represent a plan for a specific date
        - the actual recipes and notes (and order of them) should be kept in an array of sub objects or something. we can use converters so that it gets stored as json in postgres but deserialized in the app. the recipes model (lib/database/models/recipes.dart) might be a good example since it has an ingredients list which is an array of objects.
        - we’ll need to have userId and householdId (both as optional) on our new entity
        - will need to update the postgres ddl at ddls/postgres_powersync.sql, the powersync schema at lib/database/schema.dart, the rls policies for the new table in postgres/supabase at ddls/policies_powersync.sql, also the powersync sync rules since we’re adding a new table ddls/sync-rules.yaml.
    - within the card for a date, we show a list of recipes and notes. it’s ordered. uses should be able to long-press to drag/reorder them. you can see an example of how we’ve used drag to reorder here: lib/src/features/recipes/widgets/recipe_editor_form/sections/ingredients_section.dart
    - to add a recipe to the list i think we have an existing similar thing for finding recipes: lib/src/features/recipes/widgets/cook_modal/add_recipe_search_modal.dart. maybe we can leverage or clone this. should do a check to see if we’re using this anywhere else or if we have anything like it.
    - The “Add to Shopping List” requirement is slightly complicated probably so i’ll try to detail it here:
        - When a day has one or more recipes added and we tap “Add to Shopping List” in the “…” menu, we’ll show a bottom sheet that basically takes the ingredients from all of the recipes added to that date and shows them in a list with some sort of button to add them to the shopping list
        - however, the user might already have some of the items on their shopping list, OR the user might already have some of the items in stock in their pantry.
        - You recently implemented a feature that matched shopping list items to pantry items so that after shopping is complete a user can update their pantry with the items that were marked as bought from the shopping list. Id like to extend some of the same ideas from this implementation to this new use case. I’d like our new modal here to list all ingredients from the recipes added for that day. there will be a circular checkbox to the left that is default checked if the item does not exist in the pantry, or does exist in the pantry but has a stock status of out of stock or low stock. If the item is already on *any* shopping list then we just don’t show it in the list. we’ll put everything that is checked at the top and anything not checked at the bottom of the list. there should be a button to do the action.

Implementation notes:

- Do not write any migrations. app hasn’t been released yet. we’re just adding a new drift model to the lib/database/models directory called meal_plans
- on the meal plans page we can pre-gen a list of dates in code starting from the current date. should infinite scroll dates lazily. no need to create a meal_plans entity in the db unless the user adds a note and/or recipe to the date
- We’ll need to add new repository and riverpod provider layers for the new functionality. can use recipes as a reference
    - repo: lib/src/repositories/recipe_repository.dart
    - providers: lib/src/providers/recipe_provider.dart

Please think hard about the implementation (claude ULTRATHINK) and share your plans before we implement anything so I can review.

- [ ]  Begin implementation
- [ ]  Add tests for shopping list related features
- [ ]  Add tests for meal plan feature
