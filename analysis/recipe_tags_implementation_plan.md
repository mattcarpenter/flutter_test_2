# Recipe Tags Implementation Plan

## Overview

This document outlines the complete implementation plan for adding tags functionality to recipes. The feature will allow users to assign colored tags to recipes for better organization and filtering. The implementation follows the established patterns from the folder assignment feature while introducing tag-specific capabilities.

## Feature Requirements

### Core Functionality
- Add tags to recipes in the recipe editor form
- Display assigned tags as chips at the bottom of the recipe editor
- "Edit Tags" button opens a Wolt bottom sheet modal for tag management
- Tag selection modal with checkboxes (left-aligned, square, neutral colored)
- Color indicators (filled circles) with color picker functionality
- Add new tags directly from the selection modal
- Household-level sharing (no complex sharing like folders may have)

### UI Specifications
- **Tag Display**: Chips showing tag name and color at bottom of recipe editor
- **Modal Header**: Cancel and Save buttons in top bar
- **Checkboxes**: Left-aligned, square, neutral colored (different from folder modal's right-aligned circular style)
- **Color Indicators**: Right-aligned filled circles showing tag color
- **Color Selection**: Context menu/picker for selecting tag colors
- **Add New Tags**: Text input with button at bottom of modal

## Data Model Architecture

### Recipe Tags Table
Following the `RecipeFolders` pattern with tag-specific additions:

```dart
@DataClassName('RecipeTagEntry')
class RecipeTags extends Table {
  TextColumn get id => text().clientDefault(() => const Uuid().v4()).unique()();
  TextColumn get name => text()();
  TextColumn get color => text()(); // New: hex color code
  TextColumn get userId => text().nullable()();
  TextColumn get householdId => text().nullable()();
  DateTimeColumn get createdAt => dateTime().clientDefault(() => DateTime.now())();
  DateTimeColumn get updatedAt => dateTime().clientDefault(() => DateTime.now())();
  IntColumn get deletedAt => integer().nullable()(); // Soft delete timestamp
}
```

### Recipe Model Updates
Add tag association to existing recipes table:

```dart
// Add to recipes.dart
TextColumn get tagIds => text().nullable().map(StringListTypeConverter())();
```

### Tag Color Palette
Define available colors as constants:

```dart
// lib/src/constants/tag_colors.dart
import 'package:flutter/material.dart';

class TagColors {
  static const List<Color> palette = [
    Color(0xFF4285F4), // Blue
    Color(0xFF34A853), // Green  
    Color(0xFFEA4335), // Red
    Color(0xFFFBBC04), // Yellow
    Color(0xFF9C27B0), // Purple
    Color(0xFFFF9800), // Orange
    Color(0xFF607D8B), // Blue Grey
    Color(0xFF795548), // Brown
    Color(0xFFE91E63), // Pink
    Color(0xFF00BCD4), // Cyan
    Color(0xFF009688), // Teal
    Color(0xFF3F51B5), // Indigo
  ];
  
  static const Color defaultColor = Color(0xFF4285F4);
  
  static String getColorName(Color color) {
    switch (color.value) {
      case 0xFF4285F4: return 'Blue';
      case 0xFF34A853: return 'Green';
      case 0xFFEA4335: return 'Red';
      case 0xFFFBBC04: return 'Yellow';
      case 0xFF9C27B0: return 'Purple';
      case 0xFFFF9800: return 'Orange';
      case 0xFF607D8B: return 'Blue Grey';
      case 0xFF795548: return 'Brown';
      case 0xFFE91E63: return 'Pink';
      case 0xFF00BCD4: return 'Cyan';
      case 0xFF009688: return 'Teal';
      case 0xFF3F51B5: return 'Indigo';
      default: return 'Custom';
    }
  }
}
```

## SQL Infrastructure

### PostgreSQL Schema Changes

**Update `ddls/postgres_powersync.sql`:**

```sql
-- Recipe Tags table
CREATE TABLE IF NOT EXISTS public.recipe_tags (
    id text PRIMARY KEY DEFAULT gen_random_uuid()::text,
    name text NOT NULL,
    color text NOT NULL DEFAULT '#4285F4',
    user_id text REFERENCES auth.users(id),
    household_id text REFERENCES households(id),
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now(),
    deleted_at bigint NULL
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS recipe_tags_user_id_idx ON public.recipe_tags(user_id);
CREATE INDEX IF NOT EXISTS recipe_tags_household_id_idx ON public.recipe_tags(household_id);
CREATE INDEX IF NOT EXISTS recipe_tags_deleted_at_idx ON public.recipe_tags(deleted_at);
```

**Update the existing recipes table definition in `ddls/postgres_powersync.sql`:**

Add the `tag_ids` column to the existing CREATE TABLE statement for recipes:

```sql
CREATE TABLE IF NOT EXISTS public.recipes (
    -- ... existing columns ...
    folder_ids text NULL,
    tag_ids text NULL,  -- Add this line
    -- ... rest of existing columns ...
);
```

### PowerSync Schema Updates

**Update `lib/database/schema.dart`:**

```dart
// Add to schema
Table(recipeTagsTable, [
  Column.text('name'),
  Column.text('color'),
  Column.text('user_id'),
  Column.text('household_id'),
  Column.integer('created_at'),
  Column.integer('updated_at'),
  Column.integer('deleted_at'),
])
```

### Sync Rules Configuration

**Update `ddls/sync-rules.yaml`:**

```yaml
belongs_to_user:
  parameters: SELECT request.user_id() as user_id
  data:
    - SELECT * FROM public.recipe_tags WHERE recipe_tags.user_id = bucket.user_id

belongs_to_household:
  parameters: SELECT household_id FROM household_members WHERE user_id = request.user_id() AND is_active = 1
  data:
    - SELECT * FROM public.recipe_tags WHERE household_id = bucket.household_id
```

### RLS Policies

**Update `ddls/policies_powersync.sql`:**

```sql
-- Recipe Tags RLS Policies
CREATE POLICY "Users can view own recipe tags" ON public.recipe_tags
    FOR SELECT USING (user_id = auth.uid());

CREATE POLICY "Users can view household recipe tags" ON public.recipe_tags
    FOR SELECT USING (
        household_id IN (
            SELECT household_id 
            FROM household_members 
            WHERE user_id = auth.uid() 
            AND is_active = 1
        )
    );

CREATE POLICY "Users can insert recipe tags" ON public.recipe_tags
    FOR INSERT WITH CHECK (
        user_id = auth.uid() 
        OR household_id IN (
            SELECT household_id 
            FROM household_members 
            WHERE user_id = auth.uid() 
            AND is_active = 1
        )
    );

CREATE POLICY "Users can update own recipe tags" ON public.recipe_tags
    FOR UPDATE USING (user_id = auth.uid());

CREATE POLICY "Users can update household recipe tags" ON public.recipe_tags
    FOR UPDATE USING (
        household_id IN (
            SELECT household_id 
            FROM household_members 
            WHERE user_id = auth.uid() 
            AND is_active = 1
        )
    );
```

### Triggers for Household Management

**Update `ddls/triggers_powersync.sql`:**

```sql
-- Auto-assign household_id to recipe tags for household members
CREATE OR REPLACE FUNCTION auto_assign_recipe_tag_household()
RETURNS TRIGGER AS $$
BEGIN
  -- If user is a household member, assign household_id
  SELECT household_id INTO NEW.household_id
  FROM household_members 
  WHERE user_id = NEW.user_id 
    AND is_active = 1 
    AND household_id IS NOT NULL
  LIMIT 1;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER auto_assign_recipe_tag_household_trigger
  BEFORE INSERT ON public.recipe_tags
  FOR EACH ROW
  EXECUTE FUNCTION auto_assign_recipe_tag_household();

-- Update recipe tags when household membership changes
CREATE OR REPLACE FUNCTION update_recipe_tags_household_membership()
RETURNS TRIGGER AS $$
BEGIN
  -- When joining household
  IF TG_OP = 'INSERT' AND NEW.is_active = 1 THEN
    UPDATE public.recipe_tags 
    SET household_id = NEW.household_id
    WHERE user_id = NEW.user_id AND household_id IS NULL;
  END IF;
  
  -- When leaving household  
  IF TG_OP = 'UPDATE' AND OLD.is_active = 1 AND NEW.is_active = 0 THEN
    UPDATE public.recipe_tags 
    SET household_id = NULL
    WHERE user_id = NEW.user_id AND household_id = OLD.household_id;
  END IF;
  
  RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_recipe_tags_household_membership_trigger
  AFTER INSERT OR UPDATE ON household_members
  FOR EACH ROW
  EXECUTE FUNCTION update_recipe_tags_household_membership();
```

### Orphan Record Claiming

**Update `lib/database/powersync.dart`:**

```dart
Future<void> _claimOrphanedRecords(String userId) async {
  // Existing folder claiming code...
  
  // Update recipe tags - handle NULL userId
  await (appDb.update(appDb.recipeTags)
    ..where((t) => t.userId.isNull()))
    .write(RecipeTagsCompanion(userId: Value(userId)));
  
  // Update recipe tags - handle empty string userId
  await (appDb.update(appDb.recipeTags)
    ..where((t) => t.userId.equals('')))
    .write(RecipeTagsCompanion(userId: Value(userId)));
}
```

## Business Logic Implementation

### Repository Layer

**Create `lib/src/repositories/recipe_tag_repository.dart`:**

```dart
class RecipeTagRepository {
  final AppDatabase _db;

  RecipeTagRepository(this._db);

  Stream<List<RecipeTagEntry>> watchTags() {
    return (_db.select(_db.recipeTags)
      ..where((tbl) => tbl.deletedAt.isNull())
      ..orderBy([(t) => OrderingTerm(expression: t.name)]))
      .watch();
  }

  Future<RecipeTagEntry> addTag({
    required String name,
    required String color,
    String? userId,
  }) async {
    final entry = RecipeTagsCompanion(
      name: Value(name),
      color: Value(color),
      userId: Value(userId),
    );
    
    final id = await _db.into(_db.recipeTags).insert(entry);
    return await (_db.select(_db.recipeTags)
      ..where((tbl) => tbl.id.equals(id)))
      .getSingle();
  }

  Future<void> updateTag({
    required String tagId,
    String? name,
    String? color,
  }) async {
    await (_db.update(_db.recipeTags)
      ..where((tbl) => tbl.id.equals(tagId)))
      .write(RecipeTagsCompanion(
        name: name != null ? Value(name) : const Value.absent(),
        color: color != null ? Value(color) : const Value.absent(),
        updatedAt: Value(DateTime.now()),
      ));
  }

  Future<void> deleteTag(String tagId) async {
    await (_db.update(_db.recipeTags)
      ..where((tbl) => tbl.id.equals(tagId)))
      .write(RecipeTagsCompanion(
        deletedAt: Value(DateTime.now().millisecondsSinceEpoch),
      ));
  }
}
```

### Provider Layer

**Create `lib/src/providers/recipe_tag_provider.dart`:**

```dart
final recipeTagRepositoryProvider = Provider<RecipeTagRepository>((ref) {
  final database = ref.watch(databaseProvider);
  return RecipeTagRepository(database);
});

final recipeTagNotifierProvider = 
    StateNotifierProvider<RecipeTagNotifier, AsyncValue<List<RecipeTagEntry>>>((ref) {
  final repository = ref.watch(recipeTagRepositoryProvider);
  return RecipeTagNotifier(repository);
});

class RecipeTagNotifier extends StateNotifier<AsyncValue<List<RecipeTagEntry>>> {
  final RecipeTagRepository _repository;
  late final StreamSubscription<List<RecipeTagEntry>> _subscription;

  RecipeTagNotifier(this._repository) : super(const AsyncValue.loading()) {
    _subscription = _repository.watchTags().listen(
      (tags) => state = AsyncValue.data(tags),
      onError: (error, stack) => state = AsyncValue.error(error, stack),
    );
  }

  Future<void> addTag({
    required String name,
    required String color,
    String? userId,
  }) async {
    try {
      await _repository.addTag(
        name: name,
        color: color,
        userId: userId,
      );
    } catch (error, stack) {
      state = AsyncValue.error(error, stack);
    }
  }

  Future<void> updateTag({
    required String tagId,
    String? name,
    String? color,
  }) async {
    try {
      await _repository.updateTag(
        tagId: tagId,
        name: name,
        color: color,
      );
    } catch (error, stack) {
      state = AsyncValue.error(error, stack);
    }
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
```

### Recipe Repository Updates

**Update `lib/src/repositories/recipe_repository.dart`:**

```dart
Future<void> updateRecipeTagIds(String recipeId, List<String> tagIds) async {
  await (_db.update(_db.recipes)
    ..where((tbl) => tbl.id.equals(recipeId)))
    .write(RecipesCompanion(
      tagIds: Value(tagIds),
      updatedAt: Value(DateTime.now()),
    ));
}

Future<void> removeTagIdFromAllRecipes(String tagId) async {
  final recipesWithTag = await (_db.select(_db.recipes)
    ..where((tbl) => tbl.tagIds.isNotNull()))
    .get();

  for (final recipe in recipesWithTag) {
    if (recipe.tagIds?.contains(tagId) == true) {
      final updatedTagIds = List<String>.from(recipe.tagIds!)
        ..remove(tagId);
      
      await updateRecipeTagIds(recipe.id, updatedTagIds);
    }
  }
}
```

## UI Component Implementation

### Tag Chips Display

**Create `lib/src/features/recipes/widgets/recipe_editor_form/items/tag_chips_row.dart`:**

```dart
class TagChipsRow extends ConsumerWidget {
  final List<String> tagIds;
  final VoidCallback onEditTags;

  const TagChipsRow({
    super.key,
    required this.tagIds,
    required this.onEditTags,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tagsAsync = ref.watch(recipeTagNotifierProvider);
    
    return tagsAsync.when(
      data: (allTags) {
        final selectedTags = allTags
            .where((tag) => tagIds.contains(tag.id))
            .toList();
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Tags',
                  style: AppTypography.fieldLabel.copyWith(
                    color: AppColors.of(context).textPrimary,
                  ),
                ),
                TextButton(
                  onPressed: onEditTags,
                  child: const Text('Edit Tags'),
                ),
              ],
            ),
            SizedBox(height: AppSpacing.sm),
            if (selectedTags.isEmpty)
              Text(
                'No tags assigned',
                style: AppTypography.body.copyWith(
                  color: AppColors.of(context).textSecondary,
                ),
              )
            else
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.xs,
                children: selectedTags.map((tag) => 
                  TagChip(tag: tag)
                ).toList(),
              ),
          ],
        );
      },
      loading: () => const SizedBox(height: 48),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class TagChip extends StatelessWidget {
  final RecipeTagEntry tag;

  const TagChip({super.key, required this.tag});

  @override
  Widget build(BuildContext context) {
    final tagColor = Color(int.parse(tag.color.replaceFirst('#', '0xFF')));
    
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: tagColor.withOpacity(0.1),
        border: Border.all(color: tagColor.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: tagColor,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: AppSpacing.xs),
          Text(
            tag.name,
            style: AppTypography.caption.copyWith(
              color: AppColors.of(context).textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
```

### Tag Selection Modal

**Create `lib/src/features/recipes/widgets/tag_selection_modal.dart`:**

```dart
void showTagSelectionModal(
  BuildContext context, {
  required List<String> currentTagIds,
  required ValueChanged<List<String>> onTagIdsChanged,
}) {
  final GlobalKey<TagSelectionContentState> contentKey = 
      GlobalKey<TagSelectionContentState>();

  WoltModalSheet.show(
    useRootNavigator: true,
    context: context,
    pageListBuilder: (bottomSheetContext) => [
      TagSelectionModalPage.build(
        context: context,
        currentTagIds: currentTagIds,
        onTagIdsChanged: onTagIdsChanged,
        contentKey: contentKey,
      ),
    ],
  );
}

class TagSelectionModalPage {
  TagSelectionModalPage._();

  static WoltModalSheetPage build({
    required BuildContext context,
    required List<String> currentTagIds,
    required ValueChanged<List<String>> onTagIdsChanged,
    required GlobalKey<TagSelectionContentState> contentKey,
  }) {
    return WoltModalSheetPage(
      backgroundColor: AppColors.of(context).background,
      hasTopBarLayer: false,
      isTopBarLayerAlwaysVisible: false,
      leadingNavBarWidget: TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Cancel'),
      ),
      trailingNavBarWidget: TextButton(
        onPressed: () {
          contentKey.currentState?.saveChanges();
          Navigator.of(context).pop();
        },
        child: const Text('Save'),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.xl, AppSpacing.lg, AppSpacing.lg),
        child: TagSelectionContent(
          key: contentKey,
          currentTagIds: currentTagIds,
          onTagIdsChanged: onTagIdsChanged,
        ),
      ),
    );
  }
}
```

### New Checkbox Style Component

**Create `lib/src/widgets/app_checkbox_square.dart`:**

```dart
class AppCheckboxSquare extends StatelessWidget {
  final bool checked;
  final VoidCallback? onTap;
  final bool enabled;

  static const double _size = 20.0;
  static const double _borderRadius = 4.0;

  const AppCheckboxSquare({
    super.key,
    required this.checked,
    this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    
    Widget checkboxWidget = Container(
      width: _size,
      height: _size,
      decoration: BoxDecoration(
        color: checked 
          ? colors.textSecondary 
          : colors.surface,
        border: Border.all(
          color: checked 
            ? colors.textSecondary 
            : colors.border,
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(_borderRadius),
      ),
      child: checked
          ? Icon(
              Icons.check,
              size: 14,
              color: colors.surface,
            )
          : null,
    );

    if (onTap != null && enabled) {
      return GestureDetector(
        onTap: onTap,
        child: checkboxWidget,
      );
    }

    return checkboxWidget;
  }
}
```

### Tag Row with Color and Checkbox

**Create `lib/src/widgets/tag_selection_row.dart`:**

```dart
class TagSelectionRow extends StatelessWidget {
  final String tagId;
  final String label;
  final String color;
  final bool checked;
  final VoidCallback? onToggle;
  final Function(String color) onColorChanged;
  final bool first;
  final bool last;

  const TagSelectionRow({
    super.key,
    required this.tagId,
    required this.label,
    required this.color,
    required this.checked,
    this.onToggle,
    required this.onColorChanged,
    this.first = false,
    this.last = false,
  });

  List<AdaptiveMenuItem> _buildColorMenuItems(BuildContext context) {
    return TagColors.palette.map((paletteColor) {
      final colorHex = '#${paletteColor.value.toRadixString(16).substring(2).toUpperCase()}';
      final isSelected = colorHex == color.toUpperCase();
      
      return AdaptiveMenuItem(
        title: TagColors.getColorName(paletteColor),
        icon: Icon(
          isSelected ? Icons.check_circle : Icons.circle,
          color: paletteColor,
        ),
        onTap: () => onColorChanged(colorHex),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final tagColor = Color(int.parse(color.replaceFirst('#', '0xFF')));

    return Container(
      constraints: const BoxConstraints(minHeight: 48),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.vertical(
          top: first ? const Radius.circular(8) : Radius.zero,
          bottom: last ? const Radius.circular(8) : Radius.zero,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onToggle,
          borderRadius: BorderRadius.vertical(
            top: first ? const Radius.circular(8) : Radius.zero,
            bottom: last ? const Radius.circular(8) : Radius.zero,
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              children: [
                AppCheckboxSquare(
                  checked: checked,
                  onTap: onToggle,
                ),
                SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    label,
                    style: AppTypography.body.copyWith(
                      color: colors.textPrimary,
                    ),
                  ),
                ),
                // Color indicator with overflow menu for color selection
                AdaptivePullDownButton(
                  items: _buildColorMenuItems(context),
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: tagColor,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: colors.border,
                        width: 1,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
```

## Database Integration Updates

### Update Database Class

**Update `lib/database/database.dart`:**

```dart
@DriftDatabase(
  tables: [
    // ... existing tables
    RecipeTags,
  ],
  daos: [
    // ... existing DAOs
  ],
)
class AppDatabase extends _$AppDatabase {
  // ... existing implementation
}
```

## Integration Points

### Recipe Editor Form Updates

**Update `lib/src/features/recipes/widgets/recipe_editor_form/recipe_editor_form.dart`:**

Add tag chips row at the bottom of the form:

```dart
// Add after existing content, before action buttons
TagChipsRow(
  tagIds: recipe.tagIds ?? [],
  onEditTags: () {
    showTagSelectionModal(
      context,
      currentTagIds: recipe.tagIds ?? [],
      onTagIdsChanged: (newTagIds) {
        // Update recipe with new tag IDs
        ref.read(recipeNotifierProvider.notifier)
            .updateRecipe(recipe.copyWith(tagIds: newTagIds));
      },
    );
  },
),
SizedBox(height: AppSpacing.lg),
```

## Testing Considerations

### Unit Tests
- Repository layer CRUD operations
- Provider state management
- Tag color validation
- Recipe-tag association logic

### Integration Tests  
- Modal opening/closing workflows
- Tag assignment/removal flows
- Offline sync behavior
- Household sharing scenarios

### UI Tests
- Chip rendering with colors
- Modal interactions
- Color picker functionality
- Form validation

## Migration Strategy

1. **Phase 1**: Database schema and infrastructure
   - Deploy DDL changes
   - Update PowerSync schema and sync rules
   - Test data sync with existing recipes

2. **Phase 2**: Business logic implementation
   - Repository and provider implementation
   - Backend integration testing
   - Offline behavior validation

3. **Phase 3**: UI implementation
   - Tag chips display
   - Selection modal
   - Color picker integration
   - User testing and feedback

4. **Phase 4**: Polish and optimization
   - Performance tuning
   - Error handling refinement
   - Accessibility improvements

## Future Enhancements (Out of Scope)

- Tag-based filtering on recipes page
- Tag usage analytics
- Bulk tag operations
- Tag templates/presets
- Advanced color customization
- Tag hierarchies or categories

## Conclusion

This implementation plan provides a complete blueprint for adding tags functionality while maintaining consistency with existing patterns. The approach ensures proper multi-user support, offline capabilities, and integration with the existing recipe management system. The modular design allows for incremental implementation and future enhancements.