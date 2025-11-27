# How Ingredient Matching Works

The app helps you see which ingredients you have on hand when viewing a recipe. Here's how it works.

## Understanding Aliases

**Aliases** are alternative names used to match recipe ingredients with pantry items. Both ingredients and pantry items can have multiple aliases.

A **match** occurs when any alias from a recipe ingredient matches any alias from a pantry item. For example:
- Recipe ingredient "mayonnaise" with aliases: *mayonnaise, mayo*
- Pantry item "Kewpie Mayo" with aliases: *mayo, mayonnaise, kewpie*
- **Match found** because "mayo" appears in both

**How aliases are created:**
- **Automatically**: When you add items, the app generates common variations (requires internet)
- **Manually**: You can add your own aliases anytime

**Where to manage aliases:**

*For recipe ingredients:*
1. Open the recipe and view the ingredients
2. Tap the colored status chip next to any ingredient
3. Tap the ingredient to see its detail page
4. View and edit aliases in the **Aliases** section

*For pantry items:*
1. Go to Pantry and tap any item to edit
2. View and edit aliases in the **Aliases** section

## What You See on Recipe Pages

Each ingredient shows a **colored chip** indicating availability:

- **Green "In Stock"**: You have this in your pantry, or it can be made from another recipe
- **Orange "Low Stock"**: You have this but you're running low
- **Red "Out"**: You have this in your pantry but it's marked as out of stock
- **No chip**: This ingredient isn't in your pantry

Tap any chip to see a summary of all ingredients grouped by status. From there, you can tap individual ingredients to manage their aliases.

## What Counts as "Available"

When determining if you have an ingredient:
- **In Stock** pantry items count
- **Low Stock** pantry items count (but remind you to restock)
- **Out of Stock** pantry items do NOT count
- Items not in your pantry do NOT count

## Sub-Recipe Matching

If a recipe ingredient references another recipe (like "homemade pie crust"), the app checks if that sub-recipe is makeable. If all its ingredients are available, the ingredient shows as "In Stock" even without a direct pantry match.

## Tips for Better Matching

- Use common names for pantry items ("Milk" instead of "2% Organic Milk")
- Add aliases to pantry items for names you commonly use
- Aliases are case-insensitive ("milk" matches "Milk")
- If matching isn't working, check that both the ingredient and pantry item have overlapping aliases
