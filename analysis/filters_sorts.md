# Recipe Filtering and Sorting Specification

This document outlines the specifications for implementing filtering and sorting functionality in the recipe search results screen, inspired by the NYT Cooking app but adapted for our personal recipe library with pantry-aware matching.

## Implementation Scope

This functionality needs to be added in two places:

1. **Recipes Folder Page** (`lib/src/features/recipes/views/recipes_folder_page.dart`)
   - When viewing recipes within a specific folder
   - Currently shows a simple list of recipes filtered by folder ID

2. **Recipe Search Results** (`lib/src/features/recipes/widgets/recipe_search_results.dart`)
   - When searching for recipes
   - Currently shows a simple list of search results that can be further filtered by folder ID

Both implementations will share the same filtering and sorting logic but may have slight UI differences based on their context.

### Context-Specific Considerations

#### Recipes Folder Page

- The folder filter may be disabled or pre-selected to the current folder
- When in a specific folder, sorting options should be immediately visible since filtering is already happening
- The implementation should preserve the folder filtering when additional filters are applied
- When in "All Recipes" or "Uncategorized" views, full filtering should be available

#### Recipe Search Results

- Search is already applying a text filter, so additional filters refine these results
- Filter and sort UI should be compact to maximize space for results
- Consider how filter/sort state interacts with the search query (e.g., should changing the search query reset filters?)

## UI Components

- **Filter Button (Left)**: Opens a bottom sheet with filtering options (Can see how we do bottom sheets here using the wolt library: lib/src/features/recipes/widgets/cook_modal/add_recipe_search_modal.dart)
- **Sort By Dropdown (Right)**: Allows selection of sorting strategies

## Available Properties for Filtering/Sorting

Based on the data models examined, the following properties are available:

### Recipe Properties
- **Title**: Text (searchable)
- **Description**: Text (searchable)
- **Rating**: Integer (1-5 stars, nullable)
- **Language**: Text code (e.g., "en", nullable)
- **Servings**: Integer (nullable)
- **Time-related**:
  - Prep Time: Integer (minutes, nullable)
  - Cook Time: Integer (minutes, nullable)
  - Total Time: Integer (minutes, nullable)
- **Source**: Text (e.g., website name, nullable)
- **User/Household**: 
  - userId: Text (nullable)
  - householdId: Text (nullable)
- **Dates**:
  - Created At: Timestamp (nullable)
  - Updated At: Timestamp (nullable)
- **Folders**: List of folder IDs
- **Has Images**: Boolean (derived from images array)

### Ingredient Properties
- **Ingredient Names**: List of text values
- **Ingredient Types**: "ingredient" or "section"
- **Units**: Various unit types used

### Steps Properties
- **Step Count**: Number of steps (derived)
- **Has Timer**: Boolean (derived from steps with timerDurationSeconds)

### Pantry Match Properties
- **Match Percentage**: Ratio of matched ingredients to total (0-100%)
- **Is Perfect Match**: Boolean (all ingredients available)

## Filter Specifications

### 1. Cook Time Filter
- **UI Type**: Radios
- **Options**: 
  - Under 30 minutes
  - 30-60 minutes
  - 1-2 hours
  - Over 2 hours
- **Logic**: Based on totalTime field (or sum of prepTime + cookTime if totalTime is null)
- **Multiple Selection**: Not applicable (range selection)
- **Combination**: AND with other filters

### 2. Rating Filter
- **UI Type**: Radios
- **Options**: 1-5 stars
- **Logic**: Show recipes with rating >= selected value
- **Multiple Selection**: Treated as OR (e.g., 4 OR 5 stars)
- **Combination**: AND with other filters

### 3. Pantry Match Filter
- **UI Type**: Radios
- **Options**: 
  - Any match (>0%)
  - Good match (>50%)
  - Great match (>75%)
  - Perfect match (100%)
- **Logic**: Filter by matchPercentage from RecipePantryMatch
- **Multiple Selection**: Not applicable (range selection)
- **Combination**: AND with other filters

## Sort Specifications

### Available Sorting Options

1. **Pantry Match %** (Default when coming from pantry screen)
   - Sort by matchRatio in descending order
   - Secondary sort: Alphabetical by title

2. **Alphabetical** (Default in regular browse)
   - Sort by title in ascending order

3. **Rating**
   - Sort by rating in descending order
   - Secondary sort: Alphabetical by title

4. **Time (Fastest First)**
   - Sort by totalTime in ascending order
   - Secondary sort: Alphabetical by title

5. **Recently Added**
   - Sort by createdAt in descending order

6. **Recently Updated**
   - Sort by updatedAt in descending order

## Filter Combination Logic

- Different filters are combined with AND logic (e.g., show recipes that match time AND rating AND folder criteria)
- Within a single filter type with multiple selections, use OR logic as specified above
- Empty/unspecified filters are ignored (e.g., if no time filter is applied, show recipes of any time)

## Implementation Considerations

### Shared State Management

To efficiently implement filtering and sorting across multiple screens, consider implementing:

1. **Filter/Sort Provider**:
   - Create a dedicated Riverpod provider for filter/sort state
   - Consider using different provider instances for different contexts (search vs. browse)
   - Structure:
     ```dart
     class RecipeFilterSortState {
       final Map<FilterType, List<dynamic>> activeFilters;
       final SortOption activeSortOption;
       final SortDirection sortDirection;
       // Additional state properties
     }
     ```

2. **Filter Application Logic**:
   - Implement filter application in repository or dedicated service class
   - Create extension methods on `List<RecipeEntry>` for applying filters
   - Example:
     ```dart
     extension RecipeFiltering on List<RecipeEntry> {
       List<RecipeEntry> applyFilters(Map<FilterType, List<dynamic>> filters) {
         // Implementation
       }
     }
     ```

3. **Context Awareness**:
   - Make filter/sort state aware of its context (e.g., current folder ID or search query)
   - When context changes, adjust available filters accordingly
   - IMPORTANT: The filtering state must be localized to it's context (e.g., search results vs. folder browsing)

### Limitations and Challenges

1. **Nullable Fields**: Many fields are nullable, requiring fallback logic:
   - For sorting, null values should appear last or first depending on the sort direction
   - For filtering, null values should be handled explicitly (e.g., include or exclude)

2. **Derived Properties**: Some filter properties need to be calculated:
   - Total time might need to be derived from prep + cook time if not available

3. **Persistence**:
   - Filter and sort preferences should be persisted across app sessions
   - Consider separate persistence for different contexts (regular browse vs. pantry-matching)

4. **Edge Cases**:
   - Handling recipes with incomplete data

### User Experience Guidelines

1. **Filter Application**:
   - Apply filters immediately when changed, without requiring an explicit "Apply" action
   - Provide easy way to clear all filters

2. **Filter State Visibility**:
   - Show the number of active filters on the filter button
   - When no results match filters, provide helpful guidance to adjust filters

3. **Sort Selection**:
   - Make the current sort option clearly visible in the dropdown
   - Update results immediately when sort changes

4. **Empty States**:
   - Provide helpful messaging when no recipes match the current filters
   - Suggest filter adjustments based on available data

## Next Steps for Implementation

1. Create shared UI components and logic:
   - Design and implement filter bottom sheet component
   - Design and implement sort dropdown component
   - Implement shared filter/sort logic in repository layer

2. Update Recipes Folder Page:
   - Add filter button and sort dropdown to the app bar
   - Connect UI interactions to shared filter/sort logic
   - Ensure folder filtering is preserved when additional filters are applied

3. Update Recipe Search Results:
   - Add filter button and sort dropdown to the results view
   - Connect UI interactions to shared filter/sort logic
   - Ensure search query filtering is preserved when additional filters are applied

4. Implement state management:
   - Consider separate filter/sort state for each context (search results vs. folder browsing)
   - Add persistence for user preferences in each context
   - Handle state reset when navigating between screens

5. Optimize for performance:
   - Add loading indicators for filter/sort operations
