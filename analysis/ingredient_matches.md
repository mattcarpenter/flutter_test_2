# UX Design Prompt: Enhancing Ingredient-Pantry Matching UI

## Current Functionality Context

Our recipe app has a feature that automatically matches recipe ingredients with items in the user's pantry. The matching system works by comparing "terms" associated with each ingredient and pantry item (a term could be the ingredient name itself or alternative names/synonyms).

Currently, users can:
1. View recipe ingredients with colored indicators:
   - Gray circle = No match in pantry
   - Red circle = Match found but out of stock
   - Green circle = Match found and in stock
2. Tap any ingredient's indicator to bring up a bottom sheet showing:
   - A summary of matches (e.g., "Pantry matches: 8 of 11 ingredients")
   - A list of all ingredients and their corresponding pantry matches (if any)

The current bottom sheet is primarily informational and doesn't allow users to influence the matching process. When automatic matching fails, users have no way to manually associate an ingredient with a pantry item.

## Technical Context

Our data model works as follows:
- Ingredients have an optional list of "terms" (alternate names or descriptors)
- Pantry items also have "terms" (one of which is the primary name of the item)
- Matching happens by comparing ingredient terms with pantry item terms
- No direct foreign keys or ID references between ingredients and pantry items
- To create a manual association, we would add a term to an ingredient that matches a term of the desired pantry item

For example, if a recipe calls for "scallions" but the user has "green onions" in their pantry:
1. The automatic matching might fail
2. The user would want to manually associate "scallions" with "green onions"
3. Technically, we'd add "green onions" as a term to the "scallions" ingredient

## Design Challenge

**How should we implement the ability for users to explicitly map a recipe ingredient to a pantry item as a manual override?**

We're looking to enhance our existing ingredient matches bottom sheet to include this functionality. Please consider:

1. The UX flow for manually associating an ingredient with a pantry item
2. How to present available pantry items for selection
3. Whether to show existing terms that an ingredient uses for matching
4. How to handle the case where there's already an automatic match but the user wants to choose a different pantry item
5. Whether and how to let users remove a manual association
6. How to visually indicate which matches are automatic vs. manual
7. Where this functionality should be positioned within our existing bottom sheet

Please provide a comprehensive UX recommendation including:
- User flow descriptions
- UI component suggestions
- Potential pitfalls or edge cases
- Mockup descriptions or sketches if helpful

The solution should balance ease-of-use with discoverability, while fitting into our existing UI patterns. Remember that this feature would likely be used when the automatic matching fails, so it needs to be obvious enough that users can discover it when needed.