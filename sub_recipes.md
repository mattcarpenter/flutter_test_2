# Sub-Recipes Implementation Requirements

## Overview
Enable recipe ingredients to reference other recipes, creating a hierarchical recipe system where complex recipes can build upon simpler component recipes (e.g., "Chicken Soup" uses "Chicken Stock" recipe as an ingredient).

## Initial Requirements Summary
- Data model changes:
    - recipes can have an ingredient that references another recipe. About those ingredients:
        - type is still 'ingredient'
        - new property added to ingredient class for recipeId
- UX
    - Create/update recipe bottom sheet:
        - Long press on an ingredient shows context menu
        - Add "Link to Existing Recipe" option
            - Link to existing recipe option should show another bottom sheet
            - That bottom sheet can basically clone lib/src/features/recipes/widgets/cook_modal/add_recipe_search_modal.dart
            - selecting a recipe will write its id to recipeId
    - Recipe page (lib/src/features/recipes/views/recipe_page.dart)
        - Should place a "See Recipe" button next to ingredients that have a recipeId. I'm thinking it should be chip shaped. not too big or anything

## User Stories

### Primary User Stories
1. **As a cook**, I want to link an ingredient to an existing recipe so that I can reuse complex sub-components
2. **As a cook**, I want to see which ingredients are linked to recipes and easily navigate to view them
3. **As a cook**, I want accurate pantry matching that considers whether I can make the sub-recipes
4. **As a cook**, I want the system to handle both direct pantry items and sub-recipe availability intelligently

### Advanced User Stories
5. **As a cook**, I want to create multi-level recipe hierarchies (soup → stock → roasted bones)
6. **As a cook**, I want the system to prevent infinite loops when recipes reference each other
7. **As a cook**, I want clear indicators when a referenced recipe becomes unavailable or deleted
8. **As a cook**, I want to quickly search and select recipes when linking ingredients

## Functional Requirements

### FR1: Ingredient Recipe Linking
- **FR1.1**: Ingredients can optionally reference another recipe via `recipeId` field
- **FR1.2**: Ingredient type remains 'ingredient' (not a new type)
- **FR1.3**: Linked ingredients retain all existing properties (name, quantities, notes)
- **FR1.4**: One ingredient can only reference one recipe (1:1 relationship)
- **FR1.5**: Multiple ingredients can reference the same recipe (N:1 relationship)

### FR2: User Interface Enhancements
- **FR2.1**: Long-press context menu on ingredients shows "Link to Existing Recipe" option
- **FR2.2**: Recipe selection modal provides search and filtering capabilities
- **FR2.3**: Recipe page displays "See Recipe" chip for linked ingredients
- **FR2.4**: Chip navigation preserves user context and allows return
- **FR2.5**: Visual distinction between regular ingredients and recipe-linked ingredients

### FR3: Pantry Matching Logic
- **FR3.1**: Ingredient is considered "available" if EITHER:
  - Direct pantry item exists with `stock_status = inStock` (existing logic)
  - Referenced recipe is fully makeable (new logic)
- **FR3.2**: Recipe is "makeable" if ALL ingredients are available (recursive definition)
- **FR3.3**: System handles multi-level nesting (A → B → C → D)
- **FR3.4**: Circular dependency detection prevents infinite loops
- **FR3.5**: Performance optimization for deep recipe hierarchies

### FR4: Data Integrity
- **FR4.1**: Orphaned recipe references are handled gracefully
- **FR4.2**: Deleted recipes are unlinked from ingredients that reference them
- **FR4.3**: Permission changes are reflected in recipe availability
- **FR4.4**: Cross-household recipe references work within sharing permissions

## Non-Functional Requirements

### NFR1: Performance
- **NFR1.1**: Recipe makeability calculation completes within 500ms for 95% of queries
- **NFR1.2**: System supports up to 10 levels of recipe nesting without performance degradation
- **NFR1.3**: Circular dependency detection completes in O(n) time complexity
- **NFR1.4**: Database queries use indexes effectively to avoid full table scans

### NFR2: Scalability  
- **NFR2.1**: System handles 10,000+ recipes with recipe references efficiently
- **NFR2.2**: PowerSync synchronization works seamlessly across multiple devices
- **NFR2.3**: Memory usage remains bounded even with complex recipe hierarchies

### NFR3: Reliability
- **NFR3.1**: Broken recipe references don't crash the application
- **NFR3.2**: Partial recipe data loads gracefully handle missing references
- **NFR3.3**: System recovers from database inconsistencies automatically

### NFR4: Usability
- **NFR4.1**: Recipe linking workflow requires maximum 3 taps/clicks
- **NFR4.2**: Visual indicators clearly distinguish linked vs regular ingredients
- **NFR4.3**: Error messages provide actionable guidance for broken references

## Edge Cases & Error Handling

### EC1: Circular Dependencies
- **Scenario**: Recipe A references Recipe B which references Recipe A
- **Handling**: Detect cycles using graph traversal, mark as unmakeable, show user warning
- **Implementation**: Maintain visited set during recursive makeability calculation

### EC2: Deep Nesting
- **Scenario**: Recipe chain A → B → C → D → E → F (6+ levels)
- **Handling**: No limits to recursion depth since realistically nobody's gonna push it too hard

### EC3: Orphaned References
- **Scenario**: Referenced recipe is deleted while still linked
- **Handling**: Ingredient becomes unlinked, shows as regular ingredient with error indicator
- **Implementation**: Soft deletion with cleanup background job

### EC4: Permission Loss
- **Scenario**: User loses access to referenced recipe (household changes)
- **Handling**: Ingredient treated as unavailable, clear error message displayed
- **Implementation**: Check recipe access permissions during makeability calculation

### EC5: Mixed Availability
- **Scenario**: Ingredient "chicken stock" exists as both pantry item and recipe reference
- **Handling**: Prioritize direct pantry match over recipe makeability
- **Implementation**: SQL query order: direct matches UNION recipe matches

### EC6: Empty or Invalid Recipes
- **Scenario**: Referenced recipe has no ingredients or is malformed
- **Handling**: Treat as unmakeable, log warning for debugging
- **Implementation**: Null/empty ingredient list returns false for makeability

### EC7: Section Headers vs Ingredients
- **Scenario**: User tries to link a section header instead of an actual ingredient
- **Handling**: Only allow linking on ingredients where `type = 'ingredient'`
- **Implementation**: Context menu only appears for ingredient type entries

### EC8: Concurrent Modifications
- **Scenario**: Two users editing same recipe simultaneously, one adds recipe link
- **Handling**: PowerSync handles conflict resolution, last write wins
- **Implementation**: Rely on existing PowerSync conflict resolution

## Acceptance Criteria

### AC1: Basic Linking Functionality
- [ ] User can long-press ingredient and see "Link to Existing Recipe" option
- [ ] Recipe selection modal shows searchable list of available recipes
- [ ] Selected recipe ID is stored in ingredient.recipeId field
- [ ] Linked ingredients show "See Recipe" chip in recipe view
- [ ] Chip navigation opens referenced recipe and allows return

### AC2: Pantry Matching Accuracy
- [ ] Ingredient with direct pantry match (inStock) shows green circle
- [ ] Ingredient with makeable recipe reference shows green circle  
- [ ] Ingredient with unmakeable recipe reference shows appropriate color (red/yellow/grey)
- [ ] Recipe match percentage accurately reflects recipe-linked ingredients
- [ ] Filter by pantry match includes recipes with makeable sub-recipes

### AC3: Error Handling
- [ ] Broken recipe references show error indicator instead of crashing
- [ ] Circular dependencies are detected and handled gracefully
- [ ] Deleted recipe references are cleaned up automatically
- [ ] Permission-denied recipes show appropriate error message

## Technical Implementation

### Database Schema Changes

#### Ingredients Model Updates
```dart
// Add to lib/database/models/ingredients.dart
class Ingredient {
  // ... existing fields
  final String? recipeId; // NEW: Optional reference to another recipe
  
  Ingredient({
    // ... existing parameters
    this.recipeId, // Add to constructor
  });
}
```

#### Recipe Terms Table Updates
```sql
-- Add to recipe_ingredient_terms table
ALTER TABLE recipe_ingredient_terms 
ADD COLUMN linked_recipe_id TEXT REFERENCES recipes(id);

-- Index for performance
CREATE INDEX idx_recipe_ingredient_terms_linked_recipe 
ON recipe_ingredient_terms(linked_recipe_id);
```

### SQL Implementation: Recursive Makeability Calculation

#### Core Recursive CTE Structure
```sql
WITH RECURSIVE recipe_makeability AS (
  -- Base case: Calculate makeability for recipes with no recipe-linked ingredients
  SELECT 
    r.id as recipe_id,
    CASE 
      WHEN COUNT(DISTINCT rit.ingredient_id) = 0 THEN 1  -- Empty recipe is makeable
      WHEN COUNT(DISTINCT rit.ingredient_id) = COUNT(DISTINCT matched_ingredients.ingredient_id) THEN 1
      ELSE 0 
    END as is_makeable,
    0 as depth
  FROM recipes r
  LEFT JOIN recipe_ingredient_terms rit ON r.id = rit.recipe_id 
    AND rit.ingredient_type = 'ingredient'  -- Exclude sections
  LEFT JOIN (
    -- Direct pantry matches only (no recipe links)
    SELECT DISTINCT 
      rit.recipe_id, 
      rit.ingredient_id
    FROM recipe_ingredient_terms rit
    INNER JOIN ingredient_terms_with_mapping itwm 
      ON rit.recipe_id = itwm.recipe_id 
      AND rit.ingredient_id = itwm.ingredient_id
    INNER JOIN pantry_item_terms pit 
      ON LOWER(itwm.effective_term) = LOWER(pit.term)
    INNER JOIN pantry_items pi 
      ON pit.pantry_item_id = pi.id 
      AND pi.stock_status = 2  -- inStock only
      AND pi.deleted_at IS NULL
    WHERE rit.linked_recipe_id IS NULL  -- Direct ingredients only
  ) matched_ingredients ON rit.recipe_id = matched_ingredients.recipe_id 
    AND rit.ingredient_id = matched_ingredients.ingredient_id
  WHERE r.deleted_at IS NULL
    AND r.id NOT IN (
      -- Exclude recipes that have recipe-linked ingredients (handle in recursive step)
      SELECT DISTINCT recipe_id 
      FROM recipe_ingredient_terms 
      WHERE linked_recipe_id IS NOT NULL
    )
  GROUP BY r.id
  
  UNION ALL
  
  -- Recursive case: Calculate makeability including recipe-linked ingredients
  SELECT 
    r.id as recipe_id,
    CASE 
      WHEN COUNT(DISTINCT rit.ingredient_id) = 0 THEN 1  -- Empty recipe
      WHEN COUNT(DISTINCT rit.ingredient_id) = 
           COUNT(DISTINCT COALESCE(direct_matches.ingredient_id, recipe_matches.ingredient_id)) THEN 1
      ELSE 0 
    END as is_makeable,
    rm.depth + 1
  FROM recipes r
  INNER JOIN recipe_ingredient_terms rit ON r.id = rit.recipe_id 
    AND rit.ingredient_type = 'ingredient'
  INNER JOIN recipe_makeability rm ON rit.linked_recipe_id = rm.recipe_id
  LEFT JOIN (
    -- Direct pantry matches
    SELECT DISTINCT rit.recipe_id, rit.ingredient_id
    FROM recipe_ingredient_terms rit
    INNER JOIN ingredient_terms_with_mapping itwm 
      ON rit.recipe_id = itwm.recipe_id AND rit.ingredient_id = itwm.ingredient_id
    INNER JOIN pantry_item_terms pit ON LOWER(itwm.effective_term) = LOWER(pit.term)
    INNER JOIN pantry_items pi ON pit.pantry_item_id = pi.id 
      AND pi.stock_status = 2 AND pi.deleted_at IS NULL
    WHERE rit.linked_recipe_id IS NULL
  ) direct_matches ON rit.recipe_id = direct_matches.recipe_id 
    AND rit.ingredient_id = direct_matches.ingredient_id
  LEFT JOIN (
    -- Recipe-linked ingredients that are makeable
    SELECT DISTINCT rit.recipe_id, rit.ingredient_id
    FROM recipe_ingredient_terms rit
    INNER JOIN recipe_makeability rm ON rit.linked_recipe_id = rm.recipe_id
    WHERE rm.is_makeable = 1 AND rit.linked_recipe_id IS NOT NULL
  ) recipe_matches ON rit.recipe_id = recipe_matches.recipe_id 
    AND rit.ingredient_id = recipe_matches.ingredient_id
  WHERE r.deleted_at IS NULL
    AND rm.depth < 20  -- Prevent infinite recursion
    AND r.id NOT IN (
      -- Circular dependency detection: exclude if recipe references itself in chain
      SELECT linked_recipe_id 
      FROM recipe_ingredient_terms 
      WHERE recipe_id = rm.recipe_id
    )
  GROUP BY r.id, rm.depth
)
```

#### Integration with Existing Queries

##### Update `findMatchingRecipesFromPantry()`
```sql
-- Enhanced version including recipe makeability
WITH recipe_makeability AS (
  -- Use the recursive CTE above
),
matching_ingredients AS (
  -- Existing direct pantry matches
  SELECT
    itwm.recipe_id,
    itwm.ingredient_id,
    1 AS matched
  FROM ingredient_terms_with_mapping itwm
  INNER JOIN pantry_item_terms pit
    ON LOWER(itwm.effective_term) = LOWER(pit.term)
  INNER JOIN pantry_items pi 
    ON pit.pantry_item_id = pi.id AND pi.stock_status = 2
  WHERE NOT EXISTS (
    SELECT 1 FROM recipe_ingredient_terms rit 
    WHERE rit.recipe_id = itwm.recipe_id 
      AND rit.ingredient_id = itwm.ingredient_id 
      AND rit.linked_recipe_id IS NOT NULL
  )
  GROUP BY itwm.recipe_id, itwm.ingredient_id
  
  UNION
  
  -- NEW: Recipe-linked ingredients that are makeable
  SELECT DISTINCT
    rit.recipe_id,
    rit.ingredient_id,
    1 AS matched
  FROM recipe_ingredient_terms rit
  INNER JOIN recipe_makeability rm 
    ON rit.linked_recipe_id = rm.recipe_id
  WHERE rm.is_makeable = 1
)
-- Rest of query remains the same...
```

### Code Structure Changes

#### Repository Layer Updates
```dart
// lib/src/repositories/recipe_repository.dart

class RecipeRepository {
  // Add method to check circular dependencies
  Future<bool> wouldCreateCircularDependency(String recipeId, String linkedRecipeId) async {
    final result = await _db.customSelect('''
      WITH RECURSIVE recipe_chain AS (
        SELECT linked_recipe_id, 1 as depth
        FROM recipe_ingredient_terms 
        WHERE recipe_id = ? AND linked_recipe_id IS NOT NULL
        
        UNION ALL
        
        SELECT rit.linked_recipe_id, rc.depth + 1
        FROM recipe_ingredient_terms rit
        INNER JOIN recipe_chain rc ON rit.recipe_id = rc.linked_recipe_id
        WHERE rc.depth < 20 AND rit.linked_recipe_id IS NOT NULL
      )
      SELECT 1 FROM recipe_chain WHERE linked_recipe_id = ?
    ''', [recipeId, recipeId]).get();
    
    return result.isNotEmpty;
  }
  
  // Add method to get makeable recipes
  Future<List<String>> getMakeableRecipeIds() async {
    final result = await _db.customSelect('''
      WITH RECURSIVE recipe_makeability AS (
        -- Use the recursive CTE structure above
      )
      SELECT recipe_id FROM recipe_makeability WHERE is_makeable = 1
    ''').get();
    
    return result.map((row) => row.read<String>('recipe_id')).toList();
  }
  
  // Update existing methods to handle recipe links
  Future<List<RecipePantryMatch>> findMatchingRecipesFromPantry() async {
    // Enhanced SQL with recipe makeability
  }
  
  // Add method to link ingredient to recipe
  Future<void> linkIngredientToRecipe(String recipeId, String ingredientId, String linkedRecipeId) async {
    // Check for circular dependency first
    if (await wouldCreateCircularDependency(recipeId, linkedRecipeId)) {
      throw Exception('Cannot link recipe: would create circular dependency');
    }
    
    // Update the ingredient in the recipe's JSON
    final recipe = await getRecipeById(recipeId);
    if (recipe?.ingredients != null) {
      final updatedIngredients = recipe!.ingredients!.map((ing) {
        if (ing.id == ingredientId) {
          return ing.copyWith(recipeId: linkedRecipeId);
        }
        return ing;
      }).toList();
      
      // Update recipe with new ingredients
      await updateRecipe(recipe.copyWith(ingredients: updatedIngredients));
    }
  }
}
```

#### Provider Layer Updates
```dart
// lib/src/providers/recipe_provider.dart

// Add provider for recipe makeability
final recipesMakeabilityProvider = StreamProvider.autoDispose<Map<String, bool>>((ref) {
  // Watch pantry changes and recipe changes
  ref.watch(pantryItemsProvider);
  ref.watch(allRecipesProvider);
  
  return ref.read(recipeRepositoryProvider).getMakeableRecipeIds().asStream()
    .map((ids) => {for (String id in ids) id: true});
});

// Update existing providers to include recipe links
final recipeIngredientMatchesProvider = StreamProvider.autoDispose
    .family<RecipeIngredientMatches, String>((ref, recipeId) {
  // Enhanced to handle recipe-linked ingredients
  ref.watch(pantryItemsProvider);
  ref.watch(recipeByIdStreamProvider(recipeId));
  ref.watch(recipesMakeabilityProvider); // NEW: Watch makeability changes
  
  return ref.read(recipeRepositoryProvider).findPantryMatchesForRecipe(recipeId).asStream();
});
```

#### UI Component Updates
```dart
// lib/src/features/recipes/widgets/recipe_editor_form/items/ingredient_list_item.dart

class IngredientListItem extends StatelessWidget {
  final Ingredient ingredient;
  final Function(String ingredientId, String linkedRecipeId) onLinkRecipe;
  
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: () => _showContextMenu(context),
      child: ListTile(
        title: Text(ingredient.name),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (ingredient.recipeId != null) ...[
              Icon(Icons.link, size: 16, color: Theme.of(context).primaryColor),
              SizedBox(width: 4),
            ],
            Icon(Icons.drag_handle),
          ],
        ),
      ),
    );
  }
  
  void _showContextMenu(BuildContext context) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: Text('Ingredient Options'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _showRecipeSelector(context);
            },
            child: Text(ingredient.recipeId == null 
              ? 'Link to Existing Recipe'
              : 'Change Linked Recipe'),
          ),
          if (ingredient.recipeId != null)
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.pop(context);
                onLinkRecipe(ingredient.id, ''); // Empty string removes link
              },
              isDestructiveAction: true,
              child: Text('Remove Recipe Link'),
            ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel'),
        ),
      ),
    );
  }
  
  void _showRecipeSelector(BuildContext context) {
    // Clone the add_recipe_search_modal.dart functionality
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => RecipeSelectorModal(
        onRecipeSelected: (recipe) {
          onLinkRecipe(ingredient.id, recipe.id);
          Navigator.pop(context);
        },
      ),
    );
  }
}
```

#### Recipe View Updates
```dart
// lib/src/features/recipes/widgets/recipe_view/recipe_ingredients_view.dart

class RecipeIngredientsView extends ConsumerWidget {
  Widget build(BuildContext context, WidgetRef ref) {
    final ingredientMatches = ref.watch(recipeIngredientMatchesProvider(recipe.id));
    
    return Column(
      children: recipe.ingredients?.map((ingredient) {
        final match = ingredientMatches.asData?.value.matches
          .firstWhere((m) => m.ingredient.id == ingredient.id);
        
        return ListTile(
          leading: IngredientMatchCircle(match: match),
          title: Text(ingredient.name),
          trailing: ingredient.recipeId != null 
            ? ActionChip(
                label: Text('See Recipe'),
                onPressed: () => _navigateToLinkedRecipe(context, ingredient.recipeId!),
                avatar: Icon(Icons.launch, size: 16),
              )
            : null,
        );
      }).toList() ?? [],
    );
  }
  
  void _navigateToLinkedRecipe(BuildContext context, String recipeId) {
    context.push('/recipes/$recipeId');
  }
}
```

### Migration Strategy

#### Database Migration
```sql
-- Migration: Add recipe linking support
-- File: lib/database/migrations/YYYYMMDD_add_recipe_linking.sql

-- Add linked_recipe_id to recipe_ingredient_terms table
ALTER TABLE recipe_ingredient_terms 
ADD COLUMN linked_recipe_id TEXT;

-- Add index for performance
CREATE INDEX idx_recipe_ingredient_terms_linked_recipe 
ON recipe_ingredient_terms(linked_recipe_id);

-- Add index for circular dependency detection
CREATE INDEX idx_recipe_ingredient_terms_recipe_linked 
ON recipe_ingredient_terms(recipe_id, linked_recipe_id);
```

#### Data Migration Script
```dart
// lib/database/migrations/recipe_linking_migration.dart

class RecipeLinkingMigration {
  static Future<void> migrate(Database db) async {
    // 1. Add columns if they don't exist
    try {
      await db.execute('''
        ALTER TABLE recipe_ingredient_terms 
        ADD COLUMN linked_recipe_id TEXT
      ''');
    } catch (e) {
      // Column may already exist, ignore error
    }
    
    // 2. Create indexes
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_recipe_ingredient_terms_linked_recipe 
      ON recipe_ingredient_terms(linked_recipe_id)
    ''');
    
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_recipe_ingredient_terms_recipe_linked 
      ON recipe_ingredient_terms(recipe_id, linked_recipe_id)
    ''');
    
    // 3. Populate linked_recipe_id from ingredients JSON where recipeId exists
    await _populateLinkedRecipeIds(db);
  }
  
  static Future<void> _populateLinkedRecipeIds(Database db) async {
    // Read all recipes with ingredients
    final recipes = await db.query('recipes', where: 'ingredients IS NOT NULL');
    
    for (final recipeRow in recipes) {
      final recipeId = recipeRow['id'] as String;
      final ingredientsJson = recipeRow['ingredients'] as String?;
      
      if (ingredientsJson != null) {
        final ingredients = json.decode(ingredientsJson) as List;
        
        for (final ingredientMap in ingredients) {
          final ingredient = ingredientMap as Map<String, dynamic>;
          final ingredientId = ingredient['id'] as String?;
          final linkedRecipeId = ingredient['recipeId'] as String?;
          
          if (ingredientId != null && linkedRecipeId != null) {
            // Update corresponding recipe_ingredient_terms row
            await db.update(
              'recipe_ingredient_terms',
              {'linked_recipe_id': linkedRecipeId},
              where: 'recipe_id = ? AND ingredient_id = ?',
              whereArgs: [recipeId, ingredientId],
            );
          }
        }
      }
    }
  }
}
```

### Testing Strategy

#### Unit Tests
```dart
// test/unit/recipe_makeability_test.dart

void main() {
  group('Recipe Makeability', () {
    late RecipeRepository repository;
    late TestDatabase database;
    
    setUp(() async {
      database = await TestDatabase.create();
      repository = RecipeRepository(database);
    });
    
    test('simple recipe with all pantry items is makeable', () async {
      // Setup pantry items
      await database.addPantryItem('chicken', stockStatus: StockStatus.inStock);
      await database.addPantryItem('rice', stockStatus: StockStatus.inStock);
      
      // Create recipe with matching ingredients
      final recipe = await database.addRecipe('Chicken Rice', [
        Ingredient(id: '1', type: 'ingredient', name: 'chicken'),
        Ingredient(id: '2', type: 'ingredient', name: 'rice'),
      ]);
      
      // Assert recipe is makeable
      final makeableIds = await repository.getMakeableRecipeIds();
      expect(makeableIds, contains(recipe.id));
    });
    
    test('recipe with unmakeable sub-recipe is not makeable', () async {
      // Setup scenario where sub-recipe cannot be made
      final subRecipe = await database.addRecipe('Chicken Stock', [
        Ingredient(id: '1', type: 'ingredient', name: 'chicken bones'),
        Ingredient(id: '2', type: 'ingredient', name: 'vegetables'),
      ]);
      
      final mainRecipe = await database.addRecipe('Chicken Soup', [
        Ingredient(id: '1', type: 'ingredient', name: 'chicken stock', recipeId: subRecipe.id),
      ]);
      
      // Assert parent recipe is not makeable (no pantry items for sub-recipe)
      final makeableIds = await repository.getMakeableRecipeIds();
      expect(makeableIds, isNot(contains(mainRecipe.id)));
    });
    
    test('circular dependency is detected and handled', () async {
      // Create Recipe A → Recipe B → Recipe A
      final recipeA = await database.addRecipe('Recipe A', []);
      final recipeB = await database.addRecipe('Recipe B', [
        Ingredient(id: '1', type: 'ingredient', name: 'ingredient from A', recipeId: recipeA.id),
      ]);
      
      // Try to add circular reference
      expect(
        () => repository.linkIngredientToRecipe(recipeA.id, '1', recipeB.id),
        throwsA(isA<Exception>()),
      );
    });
    
    test('deep nesting performs within time limits', () async {
      // Create 10-level deep recipe hierarchy
      String? previousRecipeId;
      for (int i = 0; i < 10; i++) {
        final ingredients = previousRecipeId != null 
          ? [Ingredient(id: '1', type: 'ingredient', name: 'sub-recipe', recipeId: previousRecipeId)]
          : [Ingredient(id: '1', type: 'ingredient', name: 'base ingredient')];
        
        final recipe = await database.addRecipe('Recipe Level $i', ingredients);
        previousRecipeId = recipe.id;
      }
      
      // Add pantry item for base ingredient
      await database.addPantryItem('base ingredient', stockStatus: StockStatus.inStock);
      
      // Assert calculation completes within 1 second
      final stopwatch = Stopwatch()..start();
      final makeableIds = await repository.getMakeableRecipeIds();
      stopwatch.stop();
      
      expect(stopwatch.elapsedMilliseconds, lessThan(1000));
      expect(makeableIds.length, equals(10)); // All recipes should be makeable
    });
  });
}
```

#### Integration Tests
```dart
// test/integration/sub_recipes_test.dart

void main() {
  group('Sub-Recipes Integration', () {
    testWidgets('linking ingredient to recipe updates makeability', (tester) async {
      await tester.pumpApp();
      
      // Create recipe with ingredient
      await tester.createRecipe('Test Recipe', ['chicken stock']);
      
      // Link ingredient to makeable sub-recipe
      await tester.longPress(find.text('chicken stock'));
      await tester.tap(find.text('Link to Existing Recipe'));
      await tester.selectRecipe('Chicken Stock Recipe');
      
      // Verify pantry match indicators update
      expect(find.byType(IngredientMatchCircle), findsOneWidget);
      
      // Verify recipe appears in "makeable" filtered list
      await tester.navigateToRecipesList();
      await tester.applyFilter(PantryMatchFilter.anyMatch);
      expect(find.text('Test Recipe'), findsOneWidget);
    });
    
    testWidgets('broken recipe link shows error gracefully', (tester) async {
      await tester.pumpApp();
      
      // Create recipe with linked ingredient
      await tester.createRecipe('Test Recipe', ['chicken stock']);
      await tester.linkIngredientToRecipe('chicken stock', 'Chicken Stock Recipe');
      
      // Delete the linked recipe
      await tester.deleteRecipe('Chicken Stock Recipe');
      
      // Verify UI shows error state, doesn't crash
      await tester.viewRecipe('Test Recipe');
      expect(find.byIcon(Icons.error), findsOneWidget);
      expect(find.text('Test Recipe'), findsOneWidget); // Recipe still loads
    });
  });
}
```

## Risk Assessment

### High Risk Items
1. **SQL Complexity**: Recursive CTEs may have performance implications with large datasets
   - **Mitigation**: Extensive testing with 10,000+ recipes, query optimization, proper indexing
2. **Circular Dependencies**: Complex to detect and handle correctly in all scenarios
   - **Mitigation**: Graph algorithms with cycle detection, depth limiting, comprehensive edge case testing
3. **Data Integrity**: Recipe references may become stale across PowerSync devices
   - **Mitigation**: Foreign key constraints where possible, cleanup jobs, graceful error handling

### Medium Risk Items
1. **UI Complexity**: Context menus and navigation flows add interaction complexity
   - **Mitigation**: Prototype early, user testing, fallback to simple flows
2. **Migration Complexity**: Adding relationships to existing production data
   - **Mitigation**: Careful migration scripts with rollback plans, testing on data copies
3. **Performance Regression**: Additional queries may slow existing recipe operations
   - **Mitigation**: Performance benchmarking, query optimization, caching strategies

### Low Risk Items
1. **Provider Updates**: Incremental changes following existing patterns
2. **Model Changes**: Additive changes to existing data structures
3. **UI Components**: Well-established patterns for chips and modals

## Success Metrics

### Functional Success
- [ ] 100% of recipe linking workflows complete successfully
- [ ] 0% crash rate when encountering broken recipe references
- [ ] 100% accuracy in pantry matching calculations with sub-recipes
- [ ] 100% circular dependency detection rate

### Performance Success
- [ ] 95% of makeability calculations complete within 500ms
- [ ] 99% uptime during recipe linking operations
- [ ] <5% performance regression on existing recipe operations
- [ ] Memory usage remains stable with 1000+ linked recipes

### User Experience Success
- [ ] <3 taps required to link an ingredient to a recipe
- [ ] Clear visual indicators for all linked ingredients (100% visibility)
- [ ] Intuitive error messages for all error scenarios
- [ ] <2 second navigation time between linked recipes

## Future Considerations

### Phase 2 Enhancements
1. **Recipe Scaling**: Automatically scale sub-recipe quantities based on parent recipe servings
2. **Batch Operations**: Link multiple ingredients to recipes simultaneously
3. **Recipe Templates**: Create template recipes specifically for use as ingredients
4. **Visual Recipe Tree**: Show hierarchical view of recipe dependencies
5. **Smart Suggestions**: AI-powered suggestions for recipe linking based on ingredient names

### Technical Debt Considerations
1. **Query Optimization**: Monitor and optimize recursive CTE performance in production
2. **Caching Strategy**: Consider materialized views for frequently accessed makeability data
3. **API Evolution**: Design APIs to support future recipe relationship types (portions, scaling factors)
4. **Analytics**: Track usage patterns to optimize common recipe linking workflows

### Scalability Planning
1. **Database Partitioning**: Consider partitioning strategies for very large recipe databases
2. **Async Processing**: Move complex makeability calculations to background jobs if needed
3. **Caching Layer**: Implement Redis or similar for makeability status caching
4. **API Rate Limiting**: Protect against excessive makeability calculation requests

---

*This document serves as the comprehensive specification for implementing sub-recipe functionality. All requirements should be implemented and tested before considering the feature complete. The implementation should be done incrementally, with the core linking functionality first, followed by advanced features like circular dependency detection and performance optimizations.*
