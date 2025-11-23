# Settings Epic Implementation Plan

This document outlines the comprehensive implementation plan for the Settings feature expansion.

---

## Table of Contents

1. [Executive Summary](#executive-summary)
2. [Technical Architecture](#technical-architecture)
3. [Settings Hierarchy](#settings-hierarchy)
4. [Implementation Details by Feature](#implementation-details-by-feature)
5. [UI/UX Patterns](#uiux-patterns)
6. [Implementation Phases](#implementation-phases)
7. [File Structure](#file-structure)
8. [Testing Strategy](#testing-strategy)

---

## Executive Summary

### Goals
- Implement a comprehensive settings system with JSON-based local persistence
- Enable reactive UI updates when settings change (no app restart required)
- Support hierarchical settings pages (main → sub-pages → detail pages)
- Implement custom folder sorting with drag-and-drop reordering
- Enable user-selectable theme mode (Light/Dark/Auto)

### Key Technical Decisions
- **Storage**: JSON file via `path_provider` (not SQLite/Supabase)
- **State Management**: Riverpod for reactive settings access
- **Persistence**: Immediate save on change (no "Save" buttons)
- **Scope**: All settings are LOCAL only (not synced to cloud)

---

## Technical Architecture

### 1. Settings Storage Layer

**File Location**: App's documents directory via `path_provider`

```dart
// lib/src/features/settings/services/settings_storage_service.dart

class SettingsStorageService {
  static const String _fileName = 'app_settings.json';

  Future<File> get _settingsFile async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/$_fileName');
  }

  Future<Map<String, dynamic>> loadSettings() async {
    // Load JSON, return defaults if file doesn't exist
  }

  Future<void> saveSettings(Map<String, dynamic> settings) async {
    // Atomic write to JSON file
  }
}
```

**JSON Schema**:
```json
{
  "version": 1,
  "homeScreen": "recipes",
  "layout": {
    "showFolders": "all",
    "showFoldersCount": 6,
    "folderSortOption": "alphabetical",
    "customFolderOrder": ["folder-id-1", "folder-id-2"]
  },
  "appearance": {
    "themeMode": "auto",
    "recipeFontSize": "medium"
  }
}
```

### 2. Settings Provider Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    UI Layer (Widgets)                        │
│  SettingsPage, SubPages, Recipe Views, etc.                 │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│              Provider Layer (Riverpod)                       │
│  settingsProvider - Main state notifier                     │
│  themeModeProvider - Derived provider for theme             │
│  homeScreenProvider - Derived provider for home screen      │
│  folderSortProvider - Derived provider for folder sorting   │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│              Service Layer                                   │
│  SettingsStorageService - JSON file read/write              │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│              Storage (JSON File)                             │
│  ~/Documents/app_settings.json                              │
└─────────────────────────────────────────────────────────────┘
```

### 3. Settings State Model

```dart
// lib/src/features/settings/models/app_settings.dart

@freezed
class AppSettings with _$AppSettings {
  const factory AppSettings({
    @Default('recipes') String homeScreen,
    @Default(LayoutSettings()) LayoutSettings layout,
    @Default(AppearanceSettings()) AppearanceSettings appearance,
  }) = _AppSettings;

  factory AppSettings.fromJson(Map<String, dynamic> json) =>
      _$AppSettingsFromJson(json);
}

@freezed
class LayoutSettings with _$LayoutSettings {
  const factory LayoutSettings({
    @Default('all') String showFolders,      // 'all' or 'firstN'
    @Default(6) int showFoldersCount,         // N when showFolders is 'firstN'
    @Default('alphabetical') String folderSortOption,
    @Default([]) List<String> customFolderOrder,
  }) = _LayoutSettings;
}

@freezed
class AppearanceSettings with _$AppearanceSettings {
  const factory AppearanceSettings({
    @Default('auto') String themeMode,       // 'light', 'dark', 'auto'
    @Default('medium') String recipeFontSize, // 'small', 'medium', 'large'
  }) = _AppearanceSettings;
}
```

### 4. Main Settings Provider

```dart
// lib/src/features/settings/providers/app_settings_provider.dart

@riverpod
class AppSettingsNotifier extends _$AppSettingsNotifier {
  late SettingsStorageService _storageService;

  @override
  Future<AppSettings> build() async {
    _storageService = ref.read(settingsStorageServiceProvider);
    return await _storageService.loadSettings();
  }

  Future<void> updateHomeScreen(String value) async {
    final current = await future;
    final updated = current.copyWith(homeScreen: value);
    state = AsyncData(updated);
    await _storageService.saveSettings(updated);
  }

  Future<void> updateThemeMode(String value) async {
    // Similar pattern
  }

  // Additional update methods...
}

// Derived providers for specific settings
@riverpod
ThemeMode themeMode(ThemeModeRef ref) {
  final settings = ref.watch(appSettingsNotifierProvider);
  return settings.maybeWhen(
    data: (s) => switch (s.appearance.themeMode) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    },
    orElse: () => ThemeMode.system,
  );
}
```

---

## Settings Hierarchy

### Visual Structure

```
Settings (Main Page)
├── Home Screen → [recipes|shopping|meal plan|pantry] (Detail Page)
├── [space]
├── Layout & Appearance → (Sub Page)
│   ├── Recipes Page (Section Header)
│   │   ├── Show Folders → [all|first N] (Detail Page)
│   │   └── Sort Folders → [option + custom reorder] (Detail Page)
│   ├── Color Theme (Section Header)
│   │   └── Theme → [Light|Dark|Auto] (Detail Page)
│   └── Recipes (Section Header)
│       └── Font Size → [small|medium|large] (Detail Page)
├── [space]
├── Manage Tags → (Existing Page)
├── [space]
├── Account → (Existing Page)
├── [space]
├── Import Recipes → (Placeholder Page)
├── Export Recipes → (Placeholder Page)
├── [space]
├── Help → (Placeholder Page)
├── Support → (Placeholder Page)
├── [space]
├── Privacy Policy → (Placeholder Page)
├── Terms of Use → (Placeholder Page)
└── Acknowledgements → (Placeholder Page)
```

---

## Implementation Details by Feature

### 1. Home Screen Selection

**Purpose**: User selects which tab opens when app launches

**Options**:
- Recipes (default)
- Shopping
- Meal Plan
- Pantry

**Implementation**:

1. **Settings UI**: Detail page with radio-style selection list
2. **Storage**: `homeScreen` field in JSON (`"recipes"`, `"shopping"`, `"meal_plans"`, `"pantry"`)
3. **Integration Point**: `adaptive_app.dart` line 295

```dart
// Current (hardcoded):
initialLocation: '/recipes',

// Updated (dynamic):
final homeScreen = ref.read(homeScreenProvider);
final initialLocation = switch (homeScreen) {
  'shopping' => '/shopping',
  'meal_plans' => '/meal_plans',
  'pantry' => '/pantry',
  _ => '/recipes',
};
```

**Note**: This setting only affects cold app launch. The router is created once, so changes require app restart to take effect (acceptable UX for this setting).

---

### 2. Layout & Appearance Sub-Page

**Purpose**: Container page grouping visual/layout preferences

**Implementation**: Standard sub-settings page with three `SettingsGroup` sections

---

### 3. Show Folders Setting

**Purpose**: Control how many folders display on Recipes page

**Options**:
- All folders
- First N folders (user-configurable N, default 6)

**Implementation**:

1. **Detail Page UI**:
   - Two options: "All" or "First N"
   - When "First N" selected, show number picker/stepper (range: 3-20)

2. **Integration Point**: `folder_list.dart` line 64-68

```dart
// Apply folder limit based on setting
final showFolders = ref.watch(showFoldersProvider);
final showCount = ref.watch(showFoldersCountProvider);

List<dynamic> displayFolders = [
  _createUncategorizedFolder(),
  ...folders,
];

if (showFolders == 'firstN') {
  // Keep uncategorized + first N-1 folders (to total N)
  displayFolders = displayFolders.take(showCount).toList();
}
```

3. **UI Note**: If limited, show "Show All" link at bottom of folder grid

---

### 4. Sort Folders Setting (Complex)

**Purpose**: Control folder display order with custom drag-and-drop option

**Options**:
- Alphabetical (A-Z)
- Alphabetical (Z-A)
- Newest First
- Oldest First
- Custom (drag-and-drop)

**Implementation**:

1. **Detail Page Structure**:
   ```
   ┌─────────────────────────────────────┐
   │ Sort Folders              [Done]    │
   ├─────────────────────────────────────┤
   │ ○ Alphabetical (A-Z)               │
   │ ○ Alphabetical (Z-A)               │
   │ ○ Newest First                     │
   │ ○ Oldest First                     │
   │ ● Custom                           │
   ├─────────────────────────────────────┤
   │ DRAG TO REORDER (only if Custom)   │
   ├─────────────────────────────────────┤
   │ ≡ Uncategorized            📁      │
   │ ≡ Favorites                📁      │
   │ ≡ Quick Meals              📁      │
   │ ≡ Holiday Recipes          📁      │
   └─────────────────────────────────────┘
   ```

2. **Custom Sort Logic**:

   **IMPORTANT**: The custom order list in settings is NOT the source of truth for which folders exist. It only determines sort order.

   ```dart
   List<RecipeFolderEntry> applySortOrder(
     List<RecipeFolderEntry> folders,
     String sortOption,
     List<String> customOrder,
   ) {
     switch (sortOption) {
       case 'alphabetical_asc':
         return folders..sort((a, b) => a.name.compareTo(b.name));
       case 'alphabetical_desc':
         return folders..sort((a, b) => b.name.compareTo(a.name));
       case 'newest':
         return folders..sort((a, b) => b.createdAt.compareTo(a.createdAt));
       case 'oldest':
         return folders..sort((a, b) => a.createdAt.compareTo(b.createdAt));
       case 'custom':
         return _applyCustomOrder(folders, customOrder);
     }
   }

   List<RecipeFolderEntry> _applyCustomOrder(
     List<RecipeFolderEntry> folders,
     List<String> customOrder,
   ) {
     // Folders in customOrder maintain their position
     // New folders (not in customOrder) go to the bottom
     final orderedFolders = <RecipeFolderEntry>[];
     final folderMap = {for (var f in folders) f.id: f};

     // Add folders in custom order
     for (final id in customOrder) {
       if (folderMap.containsKey(id)) {
         orderedFolders.add(folderMap.remove(id)!);
       }
     }

     // Append remaining (new) folders at bottom
     orderedFolders.addAll(folderMap.values);

     return orderedFolders;
   }
   ```

3. **Drag-and-Drop Implementation**:
   - Use `ReorderableListView` or `flutter_reorderable_list` package
   - Only enabled when "Custom" is selected
   - On reorder complete, save the new ID order to settings
   - Include visual drag handle (≡ icon)

4. **Integration Point**: Create new `sortedFoldersProvider` that watches both folders and settings

---

### 5. Theme Mode Setting

**Purpose**: Allow user to override system theme

**Options**:
- Light
- Dark
- Auto (system default)

**Implementation**:

1. **Current State Analysis**:
   - `adaptive_app.dart` currently reads `platformBrightness` directly
   - Does NOT use `themeMode` parameter on `MaterialApp`
   - Theme infrastructure exists but isn't connected

2. **Required Changes**:

   **a. Create Theme Provider**:
   ```dart
   @riverpod
   ThemeMode appThemeMode(AppThemeModeRef ref) {
     final settings = ref.watch(appSettingsNotifierProvider);
     return settings.maybeWhen(
       data: (s) => switch (s.appearance.themeMode) {
         'light' => ThemeMode.light,
         'dark' => ThemeMode.dark,
         _ => ThemeMode.system,
       },
       orElse: () => ThemeMode.system,
     );
   }
   ```

   **b. Update `adaptive_app.dart`**:
   ```dart
   // In build method, watch the theme provider
   final themeMode = ref.watch(appThemeModeProvider);

   // For iOS (CupertinoApp doesn't have themeMode)
   // Need to wrap with Theme widget or handle differently
   if (Platform.isIOS) {
     // Option 1: Use brightness override
     final brightness = switch (themeMode) {
       ThemeMode.light => Brightness.light,
       ThemeMode.dark => Brightness.dark,
       ThemeMode.system => MediaQuery.of(context).platformBrightness,
     };
     return CupertinoApp.router(
       theme: brightness == Brightness.dark
           ? AppTheme.cupertinoDarkTheme
           : AppTheme.cupertinoLightTheme,
       // ...
     );
   } else {
     return MaterialApp.router(
       themeMode: themeMode,  // <-- Key addition
       theme: AppTheme.materialLightTheme,
       darkTheme: AppTheme.materialDarkTheme,
       // ...
     );
   }
   ```

3. **Reactive Updates**: Because we use `ref.watch()`, theme changes will trigger immediate rebuild of the app shell with new theme.

4. **Detail Page UI**: Simple radio-style list with three options

---

### 6. Recipe Font Size Setting

**Purpose**: Scale text size in recipe ingredients and steps

**Options**:
- Small
- Medium (default)
- Large

**Implementation**:

1. **Scale Factors**:
   ```dart
   double getFontScaleFactor(String size) {
     return switch (size) {
       'small' => 0.85,
       'large' => 1.15,
       _ => 1.0,  // medium
     };
   }
   ```

2. **Affected Areas** (recipe detail page):
   - Ingredients list text
   - Steps text
   - NOT metadata (prep time, servings, etc.) - keep standard size

3. **Integration**:
   ```dart
   // In recipe detail widget
   final fontScale = ref.watch(recipeFontScaleProvider);

   Text(
     ingredient.name,
     style: AppTypography.body.copyWith(
       fontSize: AppTypography.body.fontSize! * fontScale,
     ),
   )
   ```

4. **Detail Page UI**: Simple radio-style list with three options

---

### 7. Placeholder Pages

These pages show "Coming Soon" or minimal content for now:

- Import Recipes
- Export Recipes
- Help
- Support
- Privacy Policy
- Terms of Use
- Acknowledgements

**Implementation**: Simple `AdaptiveSliverPage` with centered message/icon

```dart
class PlaceholderSettingsPage extends ConsumerWidget {
  final String title;
  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AdaptiveSliverPage(
      title: title,
      slivers: [
        SliverFillRemaining(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 64, color: AppColors.of(context).textTertiary),
                SizedBox(height: AppSpacing.lg),
                Text(message, style: AppTypography.body),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
```

---

## UI/UX Patterns

### Settings Row Types

| Type | Use Case | Trailing Widget |
|------|----------|-----------------|
| Navigation Row | Push to detail page | Current value + Chevron |
| Toggle Row | Boolean on/off | CupertinoSwitch |
| Action Row | Trigger action | None or Icon |
| Destructive Row | Dangerous action | Red text |

### Selection Page Pattern (for all detail pages)

```dart
// Radio-style selection list
class SelectionSettingsPage<T> extends ConsumerWidget {
  final String title;
  final List<SelectionOption<T>> options;
  final T currentValue;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AdaptiveSliverPage(
      title: title,
      slivers: [
        SliverToBoxAdapter(
          child: SettingsGroup(
            children: options.map((option) =>
              SettingsRow(
                title: option.label,
                subtitle: option.description,
                trailing: currentValue == option.value
                    ? Icon(CupertinoIcons.checkmark, color: colors.primary)
                    : null,
                onTap: () {
                  onChanged(option.value);
                  Navigator.pop(context);
                },
              ),
            ).toList(),
          ),
        ),
      ],
    );
  }
}
```

### Spacing Between Groups

```dart
// Standard spacing between SettingsGroup widgets
SizedBox(height: AppSpacing.xl),  // 24px
```

---

## Implementation Phases

### Phase 1: Foundation (Settings Infrastructure)
**Priority: High | Effort: Medium**

1. Create `SettingsStorageService` with JSON read/write
2. Create `AppSettings` model with Freezed
3. Create `AppSettingsNotifier` provider
4. Add derived providers for individual settings
5. Create base `SelectionSettingsPage` widget
6. Create `PlaceholderSettingsPage` widget

**Deliverables**:
- Working settings persistence
- Provider architecture ready for consumption

---

### Phase 2: Theme Mode
**Priority: High | Effort: Medium**

1. Create Theme detail page with Light/Dark/Auto selection
2. Create `appThemeModeProvider` derived provider
3. Update `adaptive_app.dart` to watch theme provider
4. Handle CupertinoApp theme switching (iOS-specific)
5. Test instant theme switching without restart

**Deliverables**:
- Working theme selection with instant preview
- Persisted theme preference

---

### Phase 3: Main Settings Page Structure
**Priority: High | Effort: Low**

1. Update `settings_page.dart` with full hierarchy
2. Add all navigation rows with current values displayed
3. Add spacing between groups
4. Create routes for all new pages

**Deliverables**:
- Complete settings page UI (navigation only)
- All routes configured

---

### Phase 4: Home Screen Setting
**Priority: Medium | Effort: Low**

1. Create Home Screen detail page
2. Integrate with router `initialLocation`
3. Show informational note about restart requirement

**Deliverables**:
- Working home screen preference
- App launches to preferred tab

---

### Phase 5: Layout & Appearance Sub-Page
**Priority: Medium | Effort: Low**

1. Create Layout & Appearance page with three sections
2. Add navigation rows to detail pages
3. Display current values in trailing widgets

**Deliverables**:
- Working sub-page navigation

---

### Phase 6: Show Folders Setting
**Priority: Medium | Effort: Medium**

1. Create Show Folders detail page with All/First N options
2. Add number picker when First N selected
3. Integrate with `folder_list.dart`
4. Add "Show All" link when folders are limited

**Deliverables**:
- Folder count limiting works
- User can configure N value

---

### Phase 7: Sort Folders Setting (Complex)
**Priority: Medium | Effort: High**

1. Create Sort Folders detail page with sort options
2. Implement sort logic for each option
3. Add drag-and-drop list for custom order
4. Create `sortedFoldersProvider` combining folders + sort settings
5. Handle new folders appearing at bottom of custom list
6. Integrate with folder display

**Deliverables**:
- All sort options working
- Custom drag-and-drop reordering
- New folders handled correctly

---

### Phase 8: Recipe Font Size Setting
**Priority: Low | Effort: Medium**

1. Create Font Size detail page
2. Create `recipeFontScaleProvider`
3. Identify all text elements in recipe detail to scale
4. Apply scaling to ingredients and steps
5. Test all three sizes

**Deliverables**:
- Font scaling in recipe view
- Three size options working

---

### Phase 9: Placeholder Pages
**Priority: Low | Effort: Low**

1. Create all placeholder pages using template
2. Add routes
3. Use appropriate icons for each

**Deliverables**:
- All pages navigable
- Clean "Coming Soon" experience

---

## File Structure

```
lib/src/features/settings/
├── models/
│   └── app_settings.dart              # Freezed settings model
│   └── app_settings.freezed.dart      # Generated
│   └── app_settings.g.dart            # Generated JSON
├── services/
│   └── settings_storage_service.dart  # JSON file persistence
├── providers/
│   ├── app_settings_provider.dart     # Main settings state
│   ├── app_settings_provider.g.dart   # Generated
│   ├── tag_management_provider.dart   # Existing
│   ├── theme_provider.dart            # Derived theme provider
│   └── folder_sort_provider.dart      # Derived folder sort provider
├── views/
│   ├── settings_page.dart             # Main settings (update existing)
│   ├── manage_tags_page.dart          # Existing
│   ├── layout_appearance_page.dart    # Sub-page
│   ├── home_screen_page.dart          # Detail page
│   ├── show_folders_page.dart         # Detail page
│   ├── sort_folders_page.dart         # Detail page with drag-drop
│   ├── theme_mode_page.dart           # Detail page
│   ├── recipe_font_size_page.dart     # Detail page
│   └── placeholder_page.dart          # Reusable placeholder
└── widgets/
    ├── settings_group.dart            # Existing
    ├── settings_row.dart              # Existing
    ├── tag_management_row.dart        # Existing
    └── selection_list.dart            # Reusable selection widget
```

---

## Testing Strategy

### Unit Tests

1. **Settings Storage Service**
   - Load from non-existent file returns defaults
   - Save and load roundtrip preserves all values
   - Invalid JSON handled gracefully

2. **Folder Sort Logic**
   - Each sort option produces correct order
   - Custom sort handles missing folders
   - New folders appear at bottom of custom list

3. **Settings Provider**
   - Initial load populates state
   - Updates persist and emit new state
   - Derived providers return correct values

### Integration Tests

1. **Theme Switching**
   - Select Dark → UI updates immediately
   - Select Light → UI updates immediately
   - Restart app → preference retained

2. **Home Screen**
   - Set to Pantry → restart → opens to Pantry
   - Set to Shopping → restart → opens to Shopping

3. **Folder Display**
   - Set Show Folders to First 3 → only 3 shown
   - Set Sort to Z-A → folders in reverse alpha order
   - Custom sort with drag → order persists

### Manual Testing Checklist

- [ ] All settings pages navigate correctly
- [ ] Back navigation returns to correct parent page
- [ ] Current values display correctly in settings rows
- [ ] Theme changes are instant (no restart)
- [ ] Settings persist after app kill
- [ ] Settings persist after device restart
- [ ] Custom folder sort handles newly created folders
- [ ] Font size scaling looks good at all three sizes

---

## Dependencies

### Required Packages (already in project)
- `riverpod` / `flutter_riverpod` - State management
- `freezed` / `freezed_annotation` - Model generation
- `json_annotation` / `json_serializable` - JSON serialization
- `path_provider` - File system access

### Potentially Needed
- No new packages anticipated. `ReorderableListView` is built into Flutter.

---

## Open Questions / Decisions Needed

1. **Font Size Scope**: Should metadata (prep time, servings, etc.) also scale, or just ingredients/steps?
   - **Recommendation**: Just ingredients and steps

2. **Show Folders Default N**: What should the default count be for "First N"?
   - **Recommendation**: 6 folders

3. **Custom Sort Persistence**: If user switches from Custom to Alphabetical and back, should custom order be preserved?
   - **Recommendation**: Yes, preserve the custom order array

4. **Theme on iOS**: CupertinoApp doesn't have `themeMode`. Two options:
   - A) Manually compute brightness and pass appropriate theme
   - B) Wrap in MaterialApp and override Cupertino theme from Material
   - **Recommendation**: Option A (simpler, matches current pattern)

5. **Placeholder Content**: Should placeholder pages have any content or just icons?
   - **Recommendation**: Icon + "Coming Soon" text + brief description of future feature

---

## Appendix: Current vs. Target State

| Setting | Current State | Target State |
|---------|---------------|--------------|
| Home Screen | Hardcoded `/recipes` | User-selectable |
| Theme Mode | System only | Light/Dark/Auto |
| Show Folders | All folders | All or First N |
| Sort Folders | Database order | Multiple options + custom |
| Recipe Font Size | Fixed | Small/Medium/Large |
| Import/Export | N/A | Placeholder pages |
| Help/Support | N/A | Placeholder pages |
| Legal Pages | N/A | Placeholder pages |