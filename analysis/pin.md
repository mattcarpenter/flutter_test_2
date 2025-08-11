# Pinned Recipes Feature - Implementation Analysis

## Overview

This document provides a comprehensive analysis and implementation plan for adding a "Pinned Recipes" feature to the Flutter recipe app. The feature will allow users to pin their favorite recipes for quick access via a horizontal scrolling section on the main recipes page.

## Requirements Summary

### UI Changes
1. **recipes_root.dart**: Replace "Recipes" heading with "Pinned Recipes" section featuring:
   - Horizontal scrolling list of recipe thumbnails with titles
   - Edge-to-edge scrolling similar to image upload feature
   - Larger cards than those used in recipe folder page
   - "View All" text button on the right
   - Show up to 10 recipes, sorted by last pinned first

2. **recipe_page.dart**: Add pin/bookmark functionality:
   - Translucent circular button overlaying recipe image
   - Bookmark icon in the center
   - Toggle between pinned/unpinned states

### Data Model Changes
3. **Database Schema**: Add two new columns to recipes table:
   - `pinned` (boolean) - whether recipe is pinned
   - `pinnedAt` (timestamp) - when recipe was pinned (for sorting)

## Current Architecture Analysis

### Database Structure
Based on analysis of existing files:

**Current Recipes Table** (`lib/database/models/recipes.dart`):
- Uses Drift ORM with `@DataClassName('RecipeEntry')`
- Primary key: `id` (text/UUID with client-side default)
- Timestamps stored as integers (Unix epoch milliseconds)
- Existing fields: `createdAt`, `updatedAt`, `deletedAt` (all nullable integers)
- Complex data stored as JSON via converters (ingredients, steps, images, folderIds)

**PowerSync Schema** (`lib/database/schema.dart`):
- Recipes table defined in PowerSync schema with Column.integer for timestamps
- Synchronized with Supabase backend

**PostgreSQL DDL** (`ddls/postgres_powersync.sql`):
- Recipes table (lines 81-106) uses `bigint` for timestamps
- Pattern: `created_at`, `updated_at`, `deleted_at` all nullable bigint

### UI Patterns Analysis

**Horizontal Scrolling Pattern** (`lib/src/features/recipes/widgets/recipe_editor_form/sections/image_picker_section.dart`):
- Uses `AnimatedList` with `scrollDirection: Axis.horizontal`
- Edge-to-edge achieved with `Transform.translate(offset: Offset(-16, 0))` and `SizedBox(width: MediaQuery.sizeOf(context).width)`
- Fixed item dimensions: 143px width/height
- Padding handled within individual items: `padding: EdgeInsets.all(4.0)`

**Recipe Cards** (`lib/src/features/recipes/widgets/recipe_tile.dart`):
- Current cards are square with `childAspectRatio: 1.0`
- Structure: Image (Expanded) -> Title (Text) -> Subtitle (time/servings)
- Image with rounded corners using `ClipRRect(borderRadius: BorderRadius.circular(8))`
- Cover image logic via `RecipeImage.getCoverImage()` and size variants

**Recipe Image Display** (`lib/src/features/recipes/widgets/recipe_view/recipe_image_gallery.dart`):
- Main image in `AspectRatio(aspectRatio: 16 / 9)` with `ClipRRect(borderRadius: 8)`
- Perfect location for pin button overlay in `_buildMainImage()` method

### Data Layer Architecture

**Repository Pattern** (`lib/src/repositories/recipe_repository.dart`):
- Uses Drift for local database operations
- Methods: `addRecipe()`, `updateRecipe()`, `getRecipeById()`, `watchAllRecipes()`
- Handles ingredient term queue management for canonicalization

**Provider Pattern** (`lib/src/providers/recipe_provider.dart`):
- `RecipeNotifier extends StateNotifier<AsyncValue<List<RecipeWithFolders>>>`
- Reactive updates via stream subscriptions
- Methods for add/update/delete operations

## Implementation Plan

### Phase 1: Database Model Changes

#### 1.1 Update Drift Model
**File: `lib/database/models/recipes.dart`**
```dart
// Add new columns after existing timestamp fields (line 32):
IntColumn get pinned => integer().withDefault(const Constant(0))();
IntColumn get pinnedAt => integer().nullable()();
```

#### 1.2 Update PowerSync Schema
**File: `lib/database/schema.dart`**
```dart
// Add to recipes table definition (after line 91):
Column.integer('pinned'),
Column.integer('pinned_at'),
```

#### 1.3 Update PostgreSQL DDL
**File: `ddls/postgres_powersync.sql`**
```sql
-- Add to recipes table (after line 100):
pinned integer NOT NULL DEFAULT 0,
pinned_at bigint NULL,
```

### Phase 2: Data Layer Implementation

#### 2.1 Repository Methods
**File: `lib/src/repositories/recipe_repository.dart`**
- Add `toggleRecipePin(String recipeId, bool pinned)` method
- Add `getPinnedRecipes()` method for querying pinned recipes
- Add `watchPinnedRecipes()` stream method

#### 2.2 Provider Updates
**File: `lib/src/providers/recipe_provider.dart`**
- Add `togglePin(String recipeId)` method to RecipeNotifier
- Add dedicated pinned recipes provider: `pinnedRecipesProvider`

### Phase 3: UI Components

#### 3.1 Pinned Recipe Card Component
Create new component for larger pinned recipe cards:
- Size: ~180px width, maintain aspect ratio
- Based on existing RecipeTile but optimized for horizontal layout
- Show title below image (similar to current pattern)

#### 3.2 Pinned Recipes Section
Create horizontal scrolling section:
- Use edge-to-edge pattern from ImagePickerSection
- Fixed height container with horizontal ListView/AnimatedList
- Header with "Pinned Recipes" title and "View All" button

#### 3.3 Pin Button Overlay
**File: `lib/src/features/recipes/widgets/recipe_view/recipe_image_gallery.dart`**
Modify `_buildMainImage()` method to add pin button:
```dart
return Stack(
  children: [
    // Existing image display
    LocalOrNetworkImage(...),
    // New pin button overlay
    Positioned(
      top: 12,
      right: 12,
      child: PinButton(recipeId: widget.recipeId),
    ),
  ],
);
```

### Phase 4: Integration

#### 4.1 Update recipes_root.dart
Replace empty "Recipes" section with:
- Section header: "Pinned Recipes" with "View All" button
- Horizontal pinned recipes list
- Handle empty state when no recipes are pinned

#### 4.2 Pin Button Implementation
Create `PinButton` widget:
- Translucent circular background
- Bookmark icon (filled when pinned, outline when not)
- Tap handler to toggle pin state via provider

## Technical Considerations

### Database Migration
- No migration needed since app hasn't been released
- New columns will be added to existing DDL
- Default values handle existing recipes (pinned=0, pinnedAt=null)

### Data Synchronization
- PowerSync will handle sync with Supabase automatically
- Pin state changes will sync across devices
- Use integer timestamps (millisecondsSinceEpoch) for consistency

### Performance
- Pinned recipes query will be efficient (indexed on pinned=1)
- Horizontal scrolling with fixed item count (max 10) prevents performance issues
- Image loading uses existing caching patterns

### State Management
- Pin state changes trigger reactive UI updates via Riverpod
- Optimistic updates for better UX (update UI immediately, sync in background)

### UI/UX Consistency
- Follows existing visual patterns (rounded corners, spacing, typography)
- Uses established color schemes and component styles
- Maintains adaptive design principles

## File Structure

### New Files
```
lib/src/features/recipes/widgets/
├── pinned_recipe_card.dart          # Larger recipe card for horizontal list
├── pinned_recipes_section.dart      # Horizontal scrolling section
└── pin_button.dart                  # Overlay pin/unpin button
```

### Modified Files
```
lib/database/models/recipes.dart                    # Add pinned, pinnedAt columns
lib/database/schema.dart                            # PowerSync schema update
ddls/postgres_powersync.sql                         # PostgreSQL DDL update
lib/src/repositories/recipe_repository.dart         # Pin/unpin methods
lib/src/providers/recipe_provider.dart              # Pin state management
lib/src/features/recipes/views/recipes_root.dart    # Replace empty section
lib/src/features/recipes/widgets/recipe_view/recipe_image_gallery.dart  # Add pin button
```

## Data Model Design

### Pin Status
- Use integer (0/1) instead of boolean for better database compatibility
- 0 = unpinned, 1 = pinned

### Timestamp Pattern
```dart
// When pinning a recipe:
pinned = 1
pinnedAt = DateTime.now().millisecondsSinceEpoch

// When unpinning a recipe:
pinned = 0
pinnedAt = null  // Clear timestamp to save space
```

### Query Pattern
```dart
// Get pinned recipes, sorted by most recently pinned:
(_db.select(_db.recipes)
  ..where((tbl) => tbl.pinned.equals(1))
  ..orderBy([(tbl) => OrderingTerm.desc(tbl.pinnedAt)])
  ..limit(10))
.watch();
```

## Implementation Priority

1. **High Priority**: Database model changes (blocks everything else)
2. **High Priority**: Repository and provider methods (core functionality)
3. **Medium Priority**: Pin button in recipe view (primary user interaction)
4. **Medium Priority**: Pinned recipes section in recipes_root.dart (main feature)
5. **Low Priority**: UI polish and empty states

## Success Criteria

- Users can pin/unpin recipes from recipe detail page
- Pinned recipes appear in horizontal scrolling section on main recipes page
- Pin state persists across app restarts and device sync
- UI follows existing design patterns and feels integrated
- No performance degradation with horizontal scrolling
- Graceful handling of edge cases (no pinned recipes, many pinned recipes)

## Future Enhancements

- Pin recipes from context menu in recipe lists
- Pin limits (e.g., max 20 pinned recipes)
- Pin categories/tags
- Drag-to-reorder pinned recipes
- Pin recipes to specific folders