# Smart Folders Implementation Plan

## Overview

This document outlines the implementation plan for adding "Smart Folders" to the recipe app. Smart folders are dynamic folders that automatically include recipes based on either:
1. **Tag-based criteria** - recipes matching selected tags
2. **Ingredient-based criteria** - recipes containing selected ingredients (via term matching)

## Requirements Summary

### Core Features
- Two types of smart folders: tag-based and ingredient-based
- AND/OR filter logic for both types
- Smart folders cannot be directly assigned to recipes
- Folder type is immutable after creation
- Edit smart folder settings via long-press context menu

### UI Changes
- Replace + button with `AdaptivePulldownMenu` (Add Folder / Add Smart Folder)
- New modal for creating smart folders with `CupertinoSlidingSegmentedControl`
- Tag mode: tag list with toggles and colors
- Ingredient mode: search + selected pills, full-height modal

---

## 1. Database Schema Changes

### 1.1 Drift Model Updates

**File: `lib/database/models/recipe_folders.dart`**

Add new columns to support folder types and settings:

```dart
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

/// Enum for folder types
enum FolderType {
  normal,     // value: 0
  smartTag,   // value: 1
  smartIngredient, // value: 2
}

/// Enum for filter logic
enum FilterLogic {
  or,   // value: 0 - match any
  and,  // value: 1 - match all
}

@DataClassName('RecipeFolderEntry')
class RecipeFolders extends Table {
  TextColumn get id => text().clientDefault(() => const Uuid().v4()).unique()();
  TextColumn get name => text()();
  TextColumn get userId => text().nullable()();
  TextColumn get householdId => text().nullable()();
  IntColumn get deletedAt => integer().nullable()();

  // NEW COLUMNS
  IntColumn get folderType => integer().withDefault(const Constant(0))(); // 0=normal, 1=smartTag, 2=smartIngredient
  IntColumn get filterLogic => integer().withDefault(const Constant(0))(); // 0=OR, 1=AND
  TextColumn get smartFilterTags => text().nullable()();  // JSON array of tag names (TEXT, not IDs)
  TextColumn get smartFilterTerms => text().nullable()(); // JSON array of ingredient term strings
}
```

### 1.2 JSON Converters for Smart Filter Data

**File: `lib/database/models/converters.dart`** (add to existing file)

```dart
/// Converter for storing list of strings as JSON
class StringListConverter extends TypeConverter<List<String>, String> {
  const StringListConverter();

  @override
  List<String> fromSql(String fromDb) {
    if (fromDb.isEmpty) return [];
    return (jsonDecode(fromDb) as List).cast<String>();
  }

  @override
  String toSql(List<String> value) {
    return jsonEncode(value);
  }
}
```

### 1.3 PowerSync Schema Updates

**File: `lib/database/schema.dart`**

Update the `recipeFoldersTable` definition:

```dart
Table(recipeFoldersTable, [
  Column.text('name'),
  Column.text('user_id'),
  Column.text('parent_id'),
  Column.text('household_id'),
  Column.integer('deleted_at'),
  // NEW COLUMNS
  Column.integer('folder_type'),      // 0=normal, 1=smartTag, 2=smartIngredient
  Column.integer('filter_logic'),     // 0=OR, 1=AND
  Column.text('smart_filter_tags'),   // JSON array of tag names
  Column.text('smart_filter_terms'),  // JSON array of ingredient terms
]),
```

### 1.4 PostgreSQL Schema Updates

**File: `ddls/postgres_powersync.sql`**

Update the `recipe_folders` CREATE TABLE to include the new columns:

```sql
CREATE TABLE public.recipe_folders (
  id uuid NOT NULL DEFAULT extensions.uuid_generate_v4(),
  name text NOT NULL,
  user_id uuid NULL,
  household_id uuid NULL,
  deleted_at bigint NULL,
  -- NEW COLUMNS for smart folders
  folder_type integer NOT NULL DEFAULT 0,      -- 0=normal, 1=smartTag, 2=smartIngredient
  filter_logic integer NOT NULL DEFAULT 0,     -- 0=OR, 1=AND
  smart_filter_tags text NULL,                 -- JSON array of tag names
  smart_filter_terms text NULL,                -- JSON array of ingredient terms
  CONSTRAINT recipe_folders_pkey PRIMARY KEY (id),
  CONSTRAINT recipe_folders_household_id_fkey FOREIGN KEY (household_id)
    REFERENCES public.households (id) ON DELETE CASCADE,
  CONSTRAINT recipe_folders_user_id_fkey FOREIGN KEY (user_id)
    REFERENCES auth.users (id) ON DELETE CASCADE
) TABLESPACE pg_default;
```

> **Note for manual migration (if needed later):**
> ```sql
> ALTER TABLE public.recipe_folders
>   ADD COLUMN IF NOT EXISTS folder_type integer NOT NULL DEFAULT 0,
>   ADD COLUMN IF NOT EXISTS filter_logic integer NOT NULL DEFAULT 0,
>   ADD COLUMN IF NOT EXISTS smart_filter_tags text NULL,
>   ADD COLUMN IF NOT EXISTS smart_filter_terms text NULL;
> ```

---

## 2. Model Layer Changes

### 2.1 Smart Folder Settings Model

**File: `lib/src/models/smart_folder_settings.dart`** (new file)

```dart
import 'dart:convert';

/// Represents the settings for a smart folder
class SmartFolderSettings {
  final List<String> tags;    // Tag names for tag-based folders
  final List<String> terms;   // Ingredient terms for ingredient-based folders
  final bool matchAll;        // true = AND logic, false = OR logic

  const SmartFolderSettings({
    this.tags = const [],
    this.terms = const [],
    this.matchAll = false,
  });

  /// Create from folder entry data
  factory SmartFolderSettings.fromFolderEntry({
    String? smartFilterTags,
    String? smartFilterTerms,
    int filterLogic = 0,
  }) {
    List<String> parseTags = [];
    List<String> parseTerms = [];

    if (smartFilterTags != null && smartFilterTags.isNotEmpty) {
      parseTags = (jsonDecode(smartFilterTags) as List).cast<String>();
    }
    if (smartFilterTerms != null && smartFilterTerms.isNotEmpty) {
      parseTerms = (jsonDecode(smartFilterTerms) as List).cast<String>();
    }

    return SmartFolderSettings(
      tags: parseTags,
      terms: parseTerms,
      matchAll: filterLogic == 1,
    );
  }

  String get tagsJson => jsonEncode(tags);
  String get termsJson => jsonEncode(terms);
  int get filterLogicValue => matchAll ? 1 : 0;
}
```

### 2.2 Folder Type Extension

**File: `lib/src/extensions/folder_type_extension.dart`** (new file)

```dart
import '../../database/database.dart';

extension RecipeFolderEntryExtension on RecipeFolderEntry {
  bool get isNormalFolder => folderType == 0;
  bool get isSmartTagFolder => folderType == 1;
  bool get isSmartIngredientFolder => folderType == 2;
  bool get isSmartFolder => folderType != 0;

  String get folderTypeLabel {
    switch (folderType) {
      case 1: return 'Smart (Tags)';
      case 2: return 'Smart (Ingredients)';
      default: return 'Folder';
    }
  }
}
```

---

## 3. Repository Layer Changes

### 3.1 Recipe Folder Repository Updates

**File: `lib/src/repositories/recipe_folder_repository.dart`**

Add new methods:

```dart
/// Add a smart folder
Future<RecipeFolderEntry> addSmartFolder({
  required String name,
  required int folderType,  // 1 = tag, 2 = ingredient
  required int filterLogic, // 0 = OR, 1 = AND
  List<String>? tags,
  List<String>? terms,
  String? userId,
  String? householdId,
}) async {
  final folderId = const Uuid().v4();
  final entry = RecipeFoldersCompanion(
    id: Value(folderId),
    name: Value(name),
    userId: Value(userId),
    householdId: Value(householdId),
    folderType: Value(folderType),
    filterLogic: Value(filterLogic),
    smartFilterTags: Value(tags != null ? jsonEncode(tags) : null),
    smartFilterTerms: Value(terms != null ? jsonEncode(terms) : null),
  );
  await _db.into(_db.recipeFolders).insert(entry);
  return await (_db.select(_db.recipeFolders)
    ..where((tbl) => tbl.id.equals(folderId)))
    .getSingle();
}

/// Update smart folder settings (tags/terms/logic only, not type)
Future<int> updateSmartFolderSettings({
  required String id,
  int? filterLogic,
  List<String>? tags,
  List<String>? terms,
}) {
  return (_db.update(_db.recipeFolders)
    ..where((tbl) => tbl.id.equals(id))
  ).write(RecipeFoldersCompanion(
    filterLogic: filterLogic != null ? Value(filterLogic) : const Value.absent(),
    smartFilterTags: tags != null ? Value(jsonEncode(tags)) : const Value.absent(),
    smartFilterTerms: terms != null ? Value(jsonEncode(terms)) : const Value.absent(),
  ));
}

/// Get recipes matching a tag-based smart folder
Future<List<RecipeEntry>> getRecipesForTagSmartFolder({
  required List<String> tagNames,
  required bool matchAll,
}) async {
  // This query uses the recipe.tag_ids JSON array and joins with recipe_tags
  // to match by tag name (not ID) since smart folders store tag names

  final results = await _db.customSelect('''
    WITH folder_tags AS (
      SELECT id, name FROM recipe_tags
      WHERE deleted_at IS NULL
      AND name IN (${tagNames.map((_) => '?').join(',')})
    ),
    recipe_tag_matches AS (
      SELECT DISTINCT
        r.id as recipe_id,
        ft.name as matched_tag
      FROM recipes r,
           json_each(r.tag_ids) as tag_id,
           folder_tags ft
      WHERE tag_id.value = ft.id
      AND r.deleted_at IS NULL
    )
    SELECT r.*
    FROM recipes r
    WHERE r.id IN (
      SELECT recipe_id
      FROM recipe_tag_matches
      GROUP BY recipe_id
      ${matchAll ? 'HAVING COUNT(DISTINCT matched_tag) = ${tagNames.length}' : ''}
    )
  ''',
  variables: tagNames.map((t) => Variable(t)).toList(),
  readsFrom: {_db.recipes, _db.recipeTags}).get();

  return results.map((row) => RecipeEntry.fromData(row.data)).toList();
}

/// Get recipes matching an ingredient-based smart folder
Future<List<RecipeEntry>> getRecipesForIngredientSmartFolder({
  required List<String> terms,
  required bool matchAll,
}) async {
  // Search recipe_ingredient_terms table for matching terms
  final results = await _db.customSelect('''
    WITH matched_recipes AS (
      SELECT DISTINCT
        rit.recipe_id,
        rit.term as matched_term
      FROM recipe_ingredient_terms rit
      WHERE LOWER(rit.term) IN (${terms.map((_) => 'LOWER(?)').join(',')})
    )
    SELECT r.*
    FROM recipes r
    WHERE r.deleted_at IS NULL
    AND r.id IN (
      SELECT recipe_id
      FROM matched_recipes
      GROUP BY recipe_id
      ${matchAll ? 'HAVING COUNT(DISTINCT LOWER(matched_term)) >= ${terms.length}' : ''}
    )
  ''',
  variables: terms.map((t) => Variable(t)).toList(),
  readsFrom: {_db.recipes}).get();

  return results.map((row) => RecipeEntry.fromData(row.data)).toList();
}

/// Search ingredient terms for smart folder creation
/// Returns terms matching the search query with recipe counts and details
Future<List<IngredientTermSearchResult>> searchIngredientTerms(String query) async {
  if (query.trim().isEmpty) return [];

  final searchTerm = '%${query.toLowerCase()}%';

  // Get all matching terms with their recipes
  final results = await _db.customSelect('''
    SELECT
      rit.term,
      r.id as recipe_id,
      r.title as recipe_title
    FROM recipe_ingredient_terms rit
    INNER JOIN recipes r ON rit.recipe_id = r.id
    WHERE LOWER(rit.term) LIKE ?
    AND r.deleted_at IS NULL
    ORDER BY
      CASE
        WHEN LOWER(rit.term) = LOWER(?) THEN 0
        WHEN LOWER(rit.term) LIKE LOWER(?) THEN 1
        ELSE 2
      END,
      rit.term,
      r.title
  ''',
  variables: [
    Variable(searchTerm),
    Variable(query),
    Variable('$query%'),
  ],
  readsFrom: {_db.recipes}).get();

  // Group results by term (case-insensitive) and collect recipe info
  final Map<String, List<Map<String, String>>> termRecipes = {};
  final Map<String, String> termCanonical = {}; // Store the best casing

  for (final row in results) {
    final term = row.read<String>('term');
    final termLower = term.toLowerCase();
    final recipeId = row.read<String>('recipe_id');
    final recipeTitle = row.read<String>('recipe_title');

    // Keep the first occurrence's casing as canonical
    termCanonical.putIfAbsent(termLower, () => term);

    termRecipes.putIfAbsent(termLower, () => []);
    // Avoid duplicate recipes for the same term
    if (!termRecipes[termLower]!.any((r) => r['id'] == recipeId)) {
      termRecipes[termLower]!.add({
        'id': recipeId,
        'title': recipeTitle,
      });
    }
  }

  // Convert to IngredientTermSearchResult objects
  return termRecipes.entries.map((entry) {
    final termLower = entry.key;
    final recipes = entry.value;
    return IngredientTermSearchResult(
      term: termCanonical[termLower]!,
      recipeCount: recipes.length,
      recipeIds: recipes.map((r) => r['id']!).toList(),
      recipeTitles: recipes.map((r) => r['title']!).toList(),
    );
  }).toList();
}
```

### 3.2 Ingredient Term Search Result Model

**File: `lib/src/models/ingredient_term_search_result.dart`** (new file)

```dart
/// Result from searching ingredient terms
/// Contains the term along with recipe count and recipe details for display
class IngredientTermSearchResult {
  final String term;
  final int recipeCount;           // Number of recipes containing this term
  final List<String> recipeIds;    // IDs of recipes (for future use)
  final List<String> recipeTitles; // Titles of recipes (for future display)

  const IngredientTermSearchResult({
    required this.term,
    required this.recipeCount,
    required this.recipeIds,
    required this.recipeTitles,
  });

  /// Get a preview of recipe titles (first N recipes)
  String getRecipePreview({int maxRecipes = 3}) {
    if (recipeTitles.isEmpty) return '';
    if (recipeTitles.length <= maxRecipes) {
      return recipeTitles.join(', ');
    }
    final preview = recipeTitles.take(maxRecipes).join(', ');
    final remaining = recipeTitles.length - maxRecipes;
    return '$preview +$remaining more';
  }
}
```

---

## 4. Provider Layer Changes

### 4.1 Recipe Folder Provider Updates

**File: `lib/src/providers/recipe_folder_provider.dart`**

Add new methods to `RecipeFolderNotifier`:

```dart
/// Add a smart folder
Future<String?> addSmartFolder({
  required String name,
  required int folderType,
  required int filterLogic,
  List<String>? tags,
  List<String>? terms,
  String? userId,
  String? householdId,
}) async {
  try {
    final newFolder = await _repository.addSmartFolder(
      name: name,
      folderType: folderType,
      filterLogic: filterLogic,
      tags: tags,
      terms: terms,
      userId: userId,
      householdId: householdId,
    );
    return newFolder.id;
  } catch (e, stack) {
    state = AsyncValue.error(e, stack);
    return null;
  }
}

/// Update smart folder settings
Future<void> updateSmartFolderSettings({
  required String id,
  int? filterLogic,
  List<String>? tags,
  List<String>? terms,
}) async {
  try {
    await _repository.updateSmartFolderSettings(
      id: id,
      filterLogic: filterLogic,
      tags: tags,
      terms: terms,
    );
  } catch (e, stack) {
    state = AsyncValue.error(e, stack);
  }
}
```

### 4.2 Smart Folder Recipes Provider

**File: `lib/src/providers/smart_folder_provider.dart`** (new file)

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../database/database.dart';
import '../repositories/recipe_folder_repository.dart';
import '../repositories/recipe_repository.dart';

/// Provider for recipes in a smart folder
final smartFolderRecipesProvider = FutureProvider.family<List<RecipeEntry>, RecipeFolderEntry>((ref, folder) async {
  final folderRepo = ref.watch(recipeFolderRepositoryProvider);

  if (folder.folderType == 1) {
    // Tag-based smart folder
    final tags = folder.smartFilterTags != null
      ? (jsonDecode(folder.smartFilterTags!) as List).cast<String>()
      : <String>[];
    if (tags.isEmpty) return [];

    return folderRepo.getRecipesForTagSmartFolder(
      tagNames: tags,
      matchAll: folder.filterLogic == 1,
    );
  } else if (folder.folderType == 2) {
    // Ingredient-based smart folder
    final terms = folder.smartFilterTerms != null
      ? (jsonDecode(folder.smartFilterTerms!) as List).cast<String>()
      : <String>[];
    if (terms.isEmpty) return [];

    return folderRepo.getRecipesForIngredientSmartFolder(
      terms: terms,
      matchAll: folder.filterLogic == 1,
    );
  }

  return [];
});

/// Provider for ingredient term search results
final ingredientTermSearchProvider = FutureProvider.family<List<IngredientTermSearchResult>, String>((ref, query) async {
  final repo = ref.watch(recipeFolderRepositoryProvider);
  return repo.searchIngredientTerms(query);
});
```

### 4.3 Ingredient Term Search Deduplication Utility

**File: `lib/src/utils/term_search_utils.dart`** (new file)

```dart
import '../models/ingredient_term_search_result.dart';

/// Utility class for processing ingredient term search results
class TermSearchUtils {
  /// Calculate Levenshtein distance between two strings
  static int levenshteinDistance(String s1, String s2) {
    if (s1 == s2) return 0;
    if (s1.isEmpty) return s2.length;
    if (s2.isEmpty) return s1.length;

    List<int> v0 = List<int>.generate(s2.length + 1, (i) => i);
    List<int> v1 = List<int>.filled(s2.length + 1, 0);

    for (int i = 0; i < s1.length; i++) {
      v1[0] = i + 1;
      for (int j = 0; j < s2.length; j++) {
        int cost = (s1[i] == s2[j]) ? 0 : 1;
        v1[j + 1] = [v1[j] + 1, v0[j + 1] + 1, v0[j] + cost].reduce((a, b) => a < b ? a : b);
      }
      List<int> temp = v0;
      v0 = v1;
      v1 = temp;
    }
    return v0[s2.length];
  }

  /// Sort search results by relevance to search query
  /// Uses Levenshtein distance - closest matches first
  /// Note: Repository already handles aggregation/deduplication, this just sorts
  static List<IngredientTermSearchResult> sortByRelevance(
    List<IngredientTermSearchResult> results,
    String searchQuery,
  ) {
    final queryLower = searchQuery.toLowerCase();
    final distances = <String, int>{};

    for (final result in results) {
      distances[result.term] = levenshteinDistance(queryLower, result.term.toLowerCase());
    }

    // Sort by distance (closest match first), then by recipe count (more recipes = better)
    final sorted = List<IngredientTermSearchResult>.from(results);
    sorted.sort((a, b) {
      final distA = distances[a.term]!;
      final distB = distances[b.term]!;
      if (distA != distB) return distA.compareTo(distB);
      // If same distance, prefer terms with more recipes
      if (a.recipeCount != b.recipeCount) return b.recipeCount.compareTo(a.recipeCount);
      return a.term.compareTo(b.term);
    });

    return sorted;
  }
}
```

---

## 5. UI Layer Changes

### 5.1 Recipes Root - Replace + Button with Menu

**File: `lib/src/features/recipes/views/recipes_root.dart`**

Replace the `AppCircleButton` with `AdaptivePullDownButton`:

```dart
// BEFORE (line 59-64):
AppCircleButton(
  icon: AppCircleButtonIcon.plus,
  onPressed: () {
    showAddFolderModal(context);
  },
),

// AFTER:
AdaptivePullDownButton(
  items: [
    AdaptiveMenuItem(
      title: 'Add Folder',
      icon: const Icon(CupertinoIcons.folder),
      onTap: () {
        showAddFolderModal(context);
      },
    ),
    AdaptiveMenuItem(
      title: 'Add Smart Folder',
      icon: const Icon(CupertinoIcons.wand_and_stars),
      onTap: () {
        showAddSmartFolderModal(context);
      },
    ),
  ],
  child: const AppCircleButton(
    icon: AppCircleButtonIcon.plus,
  ),
),
```

### 5.2 Add Smart Folder Modal

**File: `lib/src/features/recipes/views/add_smart_folder_modal.dart`** (new file)

Create a new modal with two modes (tag/ingredient) controlled by `CupertinoSlidingSegmentedControl`:

```dart
import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase_flutter;
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';

import '../../../providers/recipe_folder_provider.dart';
import '../../../providers/recipe_tag_provider.dart';
import '../../../theme/colors.dart';
import '../../../theme/spacing.dart';
import '../../../theme/typography.dart';
import '../../../widgets/app_button.dart';
import '../../../widgets/app_circle_button.dart';
import '../../../widgets/app_text_field_simple.dart';

/// Show the smart folder creation modal
Future<String?> showAddSmartFolderModal(BuildContext context) {
  return WoltModalSheet.show<String>(
    useRootNavigator: true,
    context: context,
    pageListBuilder: (bottomSheetContext) => [
      AddSmartFolderModalPage.build(context: bottomSheetContext),
    ],
  );
}

class AddSmartFolderModalPage {
  AddSmartFolderModalPage._();

  static SliverWoltModalSheetPage build({required BuildContext context}) {
    return SliverWoltModalSheetPage(
      navBarHeight: 55,
      backgroundColor: AppColors.of(context).background,
      surfaceTintColor: Colors.transparent,
      hasTopBarLayer: true,
      isTopBarLayerAlwaysVisible: false,
      topBarTitle: ModalSheetTitle('New Smart Folder'),
      trailingNavBarWidget: Padding(
        padding: EdgeInsets.only(right: AppSpacing.lg),
        child: AppCircleButton(
          icon: AppCircleButtonIcon.close,
          variant: AppCircleButtonVariant.neutral,
          size: 32,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      mainContentSliversBuilder: (context) => [
        SliverToBoxAdapter(
          child: AddSmartFolderForm(),
        ),
      ],
    );
  }
}

class AddSmartFolderForm extends ConsumerStatefulWidget {
  const AddSmartFolderForm({super.key});

  @override
  ConsumerState<AddSmartFolderForm> createState() => _AddSmartFolderFormState();
}

class _AddSmartFolderFormState extends ConsumerState<AddSmartFolderForm> {
  int _selectedType = 0; // 0 = tags, 1 = ingredients
  final _nameController = TextEditingController();
  final _searchController = TextEditingController();
  bool _matchAll = false; // false = OR, true = AND
  bool _isCreating = false;

  // For tag-based folders
  Set<String> _selectedTagNames = {};

  // For ingredient-based folders
  List<String> _selectedTerms = [];
  List<IngredientTermSearchResult> _searchResults = [];
  bool _isSearching = false;

  @override
  void dispose() {
    _nameController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  bool get _canCreate {
    if (_nameController.text.trim().isEmpty) return false;
    if (_selectedType == 0) {
      return _selectedTagNames.isNotEmpty;
    } else {
      return _selectedTerms.isNotEmpty;
    }
  }

  Future<void> _createSmartFolder() async {
    if (!_canCreate || _isCreating) return;

    setState(() => _isCreating = true);

    try {
      final container = ProviderScope.containerOf(context);
      final userId = supabase_flutter.Supabase.instance.client.auth.currentUser?.id;

      await container.read(recipeFolderNotifierProvider.notifier).addSmartFolder(
        name: _nameController.text.trim(),
        folderType: _selectedType == 0 ? 1 : 2,
        filterLogic: _matchAll ? 1 : 0,
        tags: _selectedType == 0 ? _selectedTagNames.toList() : null,
        terms: _selectedType == 1 ? _selectedTerms : null,
        userId: userId,
      );

      if (mounted) {
        Navigator.of(context).pop(_nameController.text.trim());
      }
    } finally {
      if (mounted) {
        setState(() => _isCreating = false);
      }
    }
  }

  Future<void> _searchTerms(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);

    try {
      final results = await ref.read(
        ingredientTermSearchProvider(query).future
      );

      // Sort results by relevance using Levenshtein distance
      final sorted = TermSearchUtils.sortByRelevance(results, query);

      if (mounted) {
        setState(() {
          _searchResults = sorted;
          _isSearching = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSearching = false);
      }
    }
  }

  void _addTerm(String term) {
    if (!_selectedTerms.contains(term)) {
      setState(() {
        _selectedTerms.add(term);
        _searchController.clear();
        _searchResults = [];
      });
    }
  }

  void _removeTerm(String term) {
    setState(() {
      _selectedTerms.remove(term);
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Padding(
      padding: EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Folder name input
          AppTextFieldSimple(
            controller: _nameController,
            placeholder: 'Folder name',
            autofocus: true,
            onChanged: (_) => setState(() {}),
          ),

          SizedBox(height: AppSpacing.xl),

          // Type selector (Cupertino segmented control)
          Text(
            'Filter recipes by',
            style: AppTypography.label.copyWith(color: colors.textSecondary),
          ),
          SizedBox(height: AppSpacing.sm),
          SizedBox(
            width: double.infinity,
            child: CupertinoSlidingSegmentedControl<int>(
              groupValue: _selectedType,
              onValueChanged: (value) {
                if (value != null) {
                  setState(() => _selectedType = value);
                }
              },
              children: const {
                0: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text('Tags'),
                ),
                1: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text('Ingredients'),
                ),
              },
            ),
          ),

          SizedBox(height: AppSpacing.xl),

          // AND/OR toggle
          Row(
            children: [
              Text(
                'Match',
                style: AppTypography.body.copyWith(color: colors.textPrimary),
              ),
              SizedBox(width: AppSpacing.sm),
              CupertinoSlidingSegmentedControl<bool>(
                groupValue: _matchAll,
                onValueChanged: (value) {
                  if (value != null) {
                    setState(() => _matchAll = value);
                  }
                },
                children: const {
                  false: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    child: Text('Any'),
                  ),
                  true: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    child: Text('All'),
                  ),
                },
              ),
            ],
          ),

          SizedBox(height: AppSpacing.xl),

          // Type-specific content
          if (_selectedType == 0)
            _buildTagSelection(colors)
          else
            _buildIngredientSelection(colors),

          SizedBox(height: AppSpacing.xl),

          // Create button
          AppButtonVariants.primaryFilled(
            text: 'Create Smart Folder',
            size: AppButtonSize.large,
            shape: AppButtonShape.square,
            fullWidth: true,
            loading: _isCreating,
            onPressed: _canCreate ? _createSmartFolder : null,
          ),
        ],
      ),
    );
  }

  Widget _buildTagSelection(AppColors colors) {
    final tagsAsync = ref.watch(recipeTagNotifierProvider);

    return tagsAsync.when(
      loading: () => const Center(child: CupertinoActivityIndicator()),
      error: (e, _) => Text('Error loading tags: $e'),
      data: (tags) {
        if (tags.isEmpty) {
          return Container(
            padding: EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: colors.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'No tags available. Create tags by editing a recipe.',
              style: AppTypography.body.copyWith(color: colors.textSecondary),
              textAlign: TextAlign.center,
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select tags',
              style: AppTypography.label.copyWith(color: colors.textSecondary),
            ),
            SizedBox(height: AppSpacing.sm),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: colors.border),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: tags.asMap().entries.map((entry) {
                  final index = entry.key;
                  final tag = entry.value;
                  final isSelected = _selectedTagNames.contains(tag.name);
                  final isFirst = index == 0;
                  final isLast = index == tags.length - 1;

                  return _TagSelectionRow(
                    tagName: tag.name,
                    tagColor: tag.color,
                    isSelected: isSelected,
                    isFirst: isFirst,
                    isLast: isLast,
                    onToggle: () {
                      setState(() {
                        if (isSelected) {
                          _selectedTagNames.remove(tag.name);
                        } else {
                          _selectedTagNames.add(tag.name);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildIngredientSelection(AppColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search input
        AppTextFieldSimple(
          controller: _searchController,
          placeholder: 'Search ingredients...',
          onChanged: (query) => _searchTerms(query),
        ),

        SizedBox(height: AppSpacing.md),

        // Search results
        if (_isSearching)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CupertinoActivityIndicator()),
          )
        else if (_searchResults.isNotEmpty)
          Container(
            constraints: const BoxConstraints(maxHeight: 200),
            decoration: BoxDecoration(
              border: Border.all(color: colors.border),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: _searchResults.length,
              separatorBuilder: (_, __) => Divider(height: 1, color: colors.border),
              itemBuilder: (context, index) {
                final result = _searchResults[index];
                final isAlreadySelected = _selectedTerms.contains(result.term);

                return ListTile(
                  title: Text(result.term),
                  subtitle: Text(
                    result.recipeCount == 1
                      ? '1 recipe'
                      : '${result.recipeCount} recipes',
                    style: AppTypography.caption.copyWith(color: colors.textTertiary),
                  ),
                  trailing: isAlreadySelected
                    ? Icon(Icons.check, color: colors.primary)
                    : IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: () => _addTerm(result.term),
                      ),
                  onTap: isAlreadySelected ? null : () => _addTerm(result.term),
                );
              },
            ),
          ),

        SizedBox(height: AppSpacing.md),

        // Selected terms as pills
        if (_selectedTerms.isNotEmpty) ...[
          Text(
            'Selected ingredients',
            style: AppTypography.label.copyWith(color: colors.textSecondary),
          ),
          SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: _selectedTerms.map((term) {
              return Chip(
                label: Text(term),
                deleteIcon: const Icon(Icons.close, size: 18),
                onDeleted: () => _removeTerm(term),
                backgroundColor: colors.surfaceVariant,
                side: BorderSide.none,
              );
            }).toList(),
          ),
        ],
      ],
    );
  }
}

class _TagSelectionRow extends StatelessWidget {
  final String tagName;
  final String tagColor;
  final bool isSelected;
  final bool isFirst;
  final bool isLast;
  final VoidCallback onToggle;

  const _TagSelectionRow({
    required this.tagName,
    required this.tagColor,
    required this.isSelected,
    required this.isFirst,
    required this.isLast,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final tagColorParsed = Color(int.parse(tagColor.replaceFirst('#', '0xFF')));

    return InkWell(
      onTap: onToggle,
      borderRadius: BorderRadius.vertical(
        top: isFirst ? const Radius.circular(12) : Radius.zero,
        bottom: isLast ? const Radius.circular(12) : Radius.zero,
      ),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          border: !isLast ? Border(bottom: BorderSide(color: colors.border)) : null,
        ),
        child: Row(
          children: [
            // Color indicator
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: tagColorParsed,
                shape: BoxShape.circle,
              ),
            ),
            SizedBox(width: AppSpacing.md),
            // Tag name
            Expanded(
              child: Text(
                tagName,
                style: AppTypography.body.copyWith(color: colors.textPrimary),
              ),
            ),
            // Checkbox
            Icon(
              isSelected ? CupertinoIcons.checkmark_circle_fill : CupertinoIcons.circle,
              color: isSelected ? colors.primary : colors.textTertiary,
            ),
          ],
        ),
      ),
    );
  }
}
```

### 5.3 Edit Smart Folder Modal

**File: `lib/src/features/recipes/views/edit_smart_folder_modal.dart`** (new file)

Similar to add modal but pre-populated with existing settings and only allows editing tags/terms and filter logic (not folder type).

```dart
// Structure similar to add_smart_folder_modal.dart
// Key differences:
// - Pre-populate with existing folder settings
// - Disable folder type selector (show as read-only)
// - Update button instead of Create
// - Call updateSmartFolderSettings() instead of addSmartFolder()
```

### 5.4 Folder List - Add Context Menu for Edit

**File: `lib/src/features/recipes/widgets/folder_list.dart`**

Update `FolderCard` to include long-press context menu for smart folders:

```dart
// In the regular folder handling section, wrap FolderCard with GestureDetector:
GestureDetector(
  onLongPress: () {
    if (regularFolder.folderType != 0) {
      // Show context menu for smart folders
      showCupertinoModalPopup(
        context: context,
        builder: (context) => CupertinoActionSheet(
          actions: [
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.pop(context);
                showEditSmartFolderModal(context, regularFolder);
              },
              child: const Text('Edit Smart Folder'),
            ),
            CupertinoActionSheetAction(
              isDestructiveAction: true,
              onPressed: () {
                Navigator.pop(context);
                ref.read(recipeFolderNotifierProvider.notifier)
                    .deleteFolder(regularFolder.id);
              },
              child: const Text('Delete'),
            ),
          ],
          cancelButton: CupertinoActionSheetAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ),
      );
    }
  },
  child: FolderCard(...),
),
```

### 5.5 Folder Card - Visual Indicator for Smart Folders

**File: `lib/src/features/recipes/widgets/folder_card.dart`**

Add visual indicator (icon) for smart folders:

```dart
// Add optional folderType parameter
final int folderType;

// In build method, show indicator based on type:
if (folderType == 1) {
  // Tag-based smart folder - show tag icon
  Icon(CupertinoIcons.tag, size: 12, color: colors.textTertiary)
} else if (folderType == 2) {
  // Ingredient-based smart folder - show list icon
  Icon(CupertinoIcons.list_bullet, size: 12, color: colors.textTertiary)
}
```

### 5.6 Recipes Folder Page - Handle Smart Folder Recipe Loading

**File: `lib/src/features/recipes/views/recipes_folder_page.dart`**

Update to detect smart folders and load recipes accordingly:

```dart
@override
Widget build(BuildContext context, WidgetRef ref) {
  // Get folder details to check type
  final foldersAsync = ref.watch(recipeFolderNotifierProvider);

  // Find current folder
  final currentFolder = foldersAsync.whenOrNull(
    data: (folders) => folders.firstWhereOrNull((f) => f.id == folderId),
  );

  // For smart folders, use the smart folder recipes provider
  if (currentFolder != null && currentFolder.folderType != 0) {
    return _buildSmartFolderPage(context, ref, currentFolder);
  }

  // ... existing normal folder logic
}

Widget _buildSmartFolderPage(BuildContext context, WidgetRef ref, RecipeFolderEntry folder) {
  final recipesAsync = ref.watch(smartFolderRecipesProvider(folder));

  return AdaptiveSliverPage(
    title: title,
    // ... similar structure but using recipesAsync from smart folder provider
    slivers: [
      recipesAsync.when(
        loading: () => const SliverFillRemaining(
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (error, stack) => SliverFillRemaining(
          child: Center(child: Text('Error: $error')),
        ),
        data: (recipes) {
          if (recipes.isEmpty) {
            return SliverFillRemaining(
              child: Center(
                child: Text('No recipes match the smart folder criteria'),
              ),
            );
          }
          return RecipesList(recipes: recipes, currentPageTitle: title);
        },
      ),
    ],
  );
}
```

### 5.7 Folder Selection Modal - Filter Out Smart Folders

**File: `lib/src/features/recipes/widgets/folder_selection_pages.dart`**

Update to filter out smart folders from the selection list:

```dart
// In FolderSelectionPage build method, filter folders:
final foldersAsync = ref.watch(recipeFolderNotifierProvider);

foldersAsync.when(
  data: (folders) {
    // Filter out smart folders - recipes can only be directly assigned to normal folders
    final normalFolders = folders.where((f) => f.folderType == 0).toList();

    // ... render normalFolders list
  },
  // ...
);
```

---

## 6. Full Height Modal for Ingredient Mode

### 6.1 Dynamic Modal Height

The Wolt modal should expand to full height when in ingredient mode. Update the modal configuration:

```dart
// In AddSmartFolderForm, when _selectedType == 1 (ingredients):
// Wrap the ingredient section in a SizedBox that expands

// In the modal page builder, detect mode and set height:
static SliverWoltModalSheetPage build({
  required BuildContext context,
  int initialType = 0,
}) {
  return SliverWoltModalSheetPage(
    // ... existing config

    // For ingredient mode, we want taller modal
    // The form itself will handle the height expansion
    mainContentSliversBuilder: (context) => [
      SliverToBoxAdapter(
        child: AddSmartFolderForm(initialType: initialType),
      ),
    ],
  );
}

// In the form, when switching to ingredient mode:
Widget _buildIngredientSelection(AppColors colors) {
  // Use LayoutBuilder to get available height
  return LayoutBuilder(
    builder: (context, constraints) {
      // Calculate height to expand modal
      final screenHeight = MediaQuery.of(context).size.height;
      final minHeight = screenHeight * 0.6; // 60% of screen at minimum

      return ConstrainedBox(
        constraints: BoxConstraints(minHeight: minHeight),
        child: Column(
          // ... ingredient search and selection UI
        ),
      );
    },
  );
}
```

---

## 7. Recipe Count Provider Updates

### 7.1 Update Folder Count Provider for Smart Folders

**File: `lib/src/providers/recipe_provider.dart`**

Update `recipeFolderCountProvider` to also count recipes for smart folders:

```dart
final recipeFolderCountProvider = FutureProvider<Map<String, int>>((ref) async {
  final folders = await ref.watch(recipeFolderNotifierProvider.future);
  final folderRepo = ref.watch(recipeFolderRepositoryProvider);
  final recipeRepo = ref.watch(recipeRepositoryProvider);

  final Map<String, int> counts = {};

  for (final folder in folders) {
    if (folder.folderType == 0) {
      // Normal folder - count by folder assignment
      counts[folder.id] = await recipeRepo.getRecipeCountForFolder(folder.id);
    } else if (folder.folderType == 1) {
      // Tag smart folder
      final tags = folder.smartFilterTags != null
        ? (jsonDecode(folder.smartFilterTags!) as List).cast<String>()
        : <String>[];
      final recipes = await folderRepo.getRecipesForTagSmartFolder(
        tagNames: tags,
        matchAll: folder.filterLogic == 1,
      );
      counts[folder.id] = recipes.length;
    } else if (folder.folderType == 2) {
      // Ingredient smart folder
      final terms = folder.smartFilterTerms != null
        ? (jsonDecode(folder.smartFilterTerms!) as List).cast<String>()
        : <String>[];
      final recipes = await folderRepo.getRecipesForIngredientSmartFolder(
        terms: terms,
        matchAll: folder.filterLogic == 1,
      );
      counts[folder.id] = recipes.length;
    }
  }

  // Also calculate uncategorized count
  counts[kUncategorizedFolderId] = await recipeRepo.getUncategorizedRecipeCount();

  return counts;
});
```

---

## 8. Implementation Checklist

### Phase 1: Database Layer
- [ ] Update `recipe_folders.dart` Drift model with new columns
- [ ] Add converters for JSON string lists
- [ ] Update `schema.dart` PowerSync schema
- [ ] Update `postgres_powersync.sql` (no migration needed since app not released)
- [ ] Create `SmartFolderSettings` model
- [ ] Create `RecipeFolderEntryExtension` for type helpers

### Phase 2: Repository Layer
- [ ] Add `addSmartFolder()` to `RecipeFolderRepository`
- [ ] Add `updateSmartFolderSettings()` to `RecipeFolderRepository`
- [ ] Add `getRecipesForTagSmartFolder()` query
- [ ] Add `getRecipesForIngredientSmartFolder()` query
- [ ] Add `searchIngredientTerms()` query
- [ ] Create `IngredientTermSearchResult` model
- [ ] Create `TermSearchUtils` for Levenshtein deduplication

### Phase 3: Provider Layer
- [ ] Update `RecipeFolderNotifier` with smart folder methods
- [ ] Create `smartFolderRecipesProvider`
- [ ] Create `ingredientTermSearchProvider`
- [ ] Update `recipeFolderCountProvider` for smart folder counts

### Phase 4: UI - Creation Flow
- [ ] Update `recipes_root.dart` - replace + button with menu
- [ ] Create `add_smart_folder_modal.dart`
- [ ] Implement tag selection UI with colors
- [ ] Implement ingredient search with deduplication
- [ ] Implement selected terms pills UI
- [ ] Implement AND/OR toggle
- [ ] Handle full-height modal for ingredient mode

### Phase 5: UI - Display & Edit
- [ ] Update `folder_card.dart` with smart folder indicators
- [ ] Update `folder_list.dart` with long-press context menu
- [ ] Create `edit_smart_folder_modal.dart`
- [ ] Update `recipes_folder_page.dart` to handle smart folders

### Phase 6: UI - Folder Assignment Filtering
- [ ] Update `folder_selection_pages.dart` to filter out smart folders
- [ ] Update `FolderSelectionViewModel` if needed

### Phase 7: Testing & Polish
- [ ] Test normal folder creation still works
- [ ] Test tag-based smart folder creation
- [ ] Test ingredient-based smart folder creation
- [ ] Test AND vs OR logic for both types
- [ ] Test smart folder recipe loading
- [ ] Test edit smart folder flow
- [ ] Test folder assignment filtering
- [ ] Test recipe counts for smart folders
- [ ] Verify PowerSync sync works correctly

---

## 9. Key Design Decisions

1. **Store tag/ingredient names as TEXT, not IDs**: This ensures smart folders remain valid even if the underlying tags are deleted or renamed. The trade-off is that if a user renames a tag, the smart folder won't automatically update.

2. **Immutable folder type**: Once created, a folder's type (normal/smart-tag/smart-ingredient) cannot be changed. This simplifies the data model and prevents edge cases.

3. **Levenshtein deduplication**: When searching ingredients, multiple recipes may have the same term. We deduplicate by showing the best match (closest Levenshtein distance to search query) while storing the canonical term string.

4. **Full-height modal for ingredients**: The ingredient search mode requires more vertical space for search results and selected pills, so the modal expands.

5. **Long-press for edit**: Smart folders use long-press context menu for editing (similar to iOS patterns) rather than inline edit buttons, keeping the folder card clean.

6. **Virtual "Uncategorized" folder unchanged**: The existing uncategorized folder concept remains unchanged - it shows recipes with no folder assignments, independent of smart folders.

---

## 10. SQL Query Examples

### Tag-Based Smart Folder Query (OR logic)
```sql
WITH folder_tags AS (
  SELECT id, name FROM recipe_tags
  WHERE deleted_at IS NULL AND name IN ('Breakfast', 'Quick')
),
recipe_tag_matches AS (
  SELECT DISTINCT r.id as recipe_id, ft.name as matched_tag
  FROM recipes r, json_each(r.tag_ids) as tag_id, folder_tags ft
  WHERE tag_id.value = ft.id AND r.deleted_at IS NULL
)
SELECT r.* FROM recipes r
WHERE r.id IN (SELECT recipe_id FROM recipe_tag_matches)
```

### Ingredient-Based Smart Folder Query (AND logic)
```sql
WITH matched_recipes AS (
  SELECT DISTINCT rit.recipe_id, rit.term as matched_term
  FROM recipe_ingredient_terms rit
  WHERE LOWER(rit.term) IN (LOWER('chicken'), LOWER('garlic'))
)
SELECT r.* FROM recipes r
WHERE r.deleted_at IS NULL
AND r.id IN (
  SELECT recipe_id FROM matched_recipes
  GROUP BY recipe_id
  HAVING COUNT(DISTINCT LOWER(matched_term)) >= 2
)
```

---

## 11. File Summary

### New Files
- `lib/src/models/smart_folder_settings.dart`
- `lib/src/models/ingredient_term_search_result.dart`
- `lib/src/extensions/folder_type_extension.dart`
- `lib/src/providers/smart_folder_provider.dart`
- `lib/src/utils/term_search_utils.dart`
- `lib/src/features/recipes/views/add_smart_folder_modal.dart`
- `lib/src/features/recipes/views/edit_smart_folder_modal.dart`

### Modified Files
- `lib/database/models/recipe_folders.dart`
- `lib/database/models/converters.dart`
- `lib/database/schema.dart`
- `ddls/postgres_powersync.sql`
- `lib/src/repositories/recipe_folder_repository.dart`
- `lib/src/providers/recipe_folder_provider.dart`
- `lib/src/providers/recipe_provider.dart`
- `lib/src/features/recipes/views/recipes_root.dart`
- `lib/src/features/recipes/views/recipes_folder_page.dart`
- `lib/src/features/recipes/widgets/folder_list.dart`
- `lib/src/features/recipes/widgets/folder_card.dart`
- `lib/src/features/recipes/widgets/folder_selection_pages.dart`