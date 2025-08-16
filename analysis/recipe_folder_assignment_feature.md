# Recipe Folder Assignment Feature - Implementation Plan

## Overview
Add folder assignment functionality to the recipe editor form, allowing users to view and manage which folders a recipe belongs to directly from the recipe editing interface.

## Current System Analysis

### Data Model
- **Recipes Table**: Contains `folderIds` column (TEXT, nullable) with `StringListTypeConverter()` 
- **Recipe Folders Table**: Stores folder metadata (name, userId, householdId, etc.)
- **Folder Assignment**: Stored as JSON array in `recipe.folderIds` field
- **Relationship**: Many-to-many via the `folderIds` array on recipes

### Existing Infrastructure
- **RecipeRepository**: Already has `addFolderToRecipe()` and `removeFolderFromRecipe()` methods
- **RecipeNotifier**: Exposes `addFolderAssignment()` and `removeFolderAssignment()` methods  
- **RecipeFolderRepository**: Manages folder CRUD operations
- **RecipeFolderProvider**: Reactive folder list management
- **Add Folder Modal**: Existing modal for creating new folders (`showAddFolderModal()`)

## Feature Requirements

### UI Components Needed

#### 1. Folder Assignment Row Widget
**Location**: In recipe metadata section, after servings/prep time/cook time
**Design**: 
- Left side: "Folders" label
- Right side: "{N} selected >" text with chevron
- Tappable area that opens folder selection modal
- Style: Consistent with existing AppTextFieldCondensed grouped appearance

#### 2. Folder Selection Modal
**Type**: Wolt bottom sheet modal
**Content**:
- Header: "Recipe Folders" with close button
- Scrollable list of folders with checkboxes (CheckboxListTile)
- "Add Folder" button at bottom to create new folders
- Real-time folder selection updates
- Apply/Save button to confirm changes

### Technical Implementation

#### 1. New Components to Create

##### `FolderAssignmentRow` Widget
```dart
// lib/src/features/recipes/widgets/recipe_editor_form/items/folder_assignment_row.dart
```
- Display current folder count
- Handle tap to open modal
- Integrate with AppTextFieldGroup styling
- Accept `currentFolderIds` and `onFolderIdsChanged` callback

##### `FolderSelectionModal` 
```dart
// lib/src/features/recipes/widgets/folder_selection_modal.dart
```
- Wolt modal sheet implementation
- Folder list with checkboxes
- Add folder integration
- State management for selection changes

##### `FolderCheckboxList` Widget
```dart
// lib/src/features/recipes/widgets/folder_checkbox_list.dart
```
- Reusable component for folder selection with checkboxes
- Handles folder loading states
- Manages selection state

#### 2. Integration Points

##### Recipe Editor Form Integration
- Add `FolderAssignmentRow` to `RecipeMetadataSection`
- Pass current `_recipe.folderIds` to the row widget
- Handle folder ID updates in form state
- Ensure folder changes are saved with recipe

##### State Management
- Use existing `recipeFolderNotifierProvider` for folder list
- Create local state for tracking selection changes in modal
- Update recipe form state when folder assignments change

#### 3. Data Flow

```
RecipeEditorForm -> FolderAssignmentRow -> FolderSelectionModal -> FolderCheckboxList
                                                                 -> AddFolderModal
```

1. **Display**: Recipe editor shows current folder count in assignment row
2. **Open Modal**: Tapping row opens folder selection modal
3. **Select Folders**: User toggles folder checkboxes in modal
4. **Add New Folder**: User can tap "Add Folder" to create new folder
5. **Apply Changes**: Modal updates recipe's folderIds and closes
6. **Save Recipe**: Form saves updated recipe with new folder assignments

## Implementation Details

### 1. FolderAssignmentRow Widget

**Props**:
- `List<String> currentFolderIds` - Currently assigned folder IDs
- `ValueChanged<List<String>> onFolderIdsChanged` - Callback for changes
- `bool grouped` - For AppTextFieldGroup integration

**State**:
- Track folder count display
- Handle loading state when fetching folder names

**Styling**:
- Match AppTextFieldCondensed appearance
- Use AppTypography and AppColors
- Proper grouped styling for integration

### 2. FolderSelectionModal Implementation

**Modal Structure**:
```dart
WoltModalSheetPage(
  hasTopBarLayer: true,
  topBarTitle: Text('Recipe Folders'),
  leadingNavBarWidget: IconButton(Icons.close),
  child: Column([
    FolderCheckboxList(),
    AddFolderButton(),
    ApplyButton(),
  ])
)
```

**State Management**:
- Local state for checkbox selections
- Watch `recipeFolderNotifierProvider` for folder list
- Handle async folder creation from add folder modal

### 3. Folder Display Logic

**Folder Name Resolution**:
- Use `recipeFolderNotifierProvider` to get folder details
- Map folder IDs to folder names for display
- Handle cases where folder might be deleted
- Show loading state while resolving names

**Count Display**:
- "No folders" when folderIds is empty
- "1 folder >" when single folder
- "{N} folders >" for multiple folders

### 4. Integration with Recipe Form

**RecipeMetadataSection Changes**:
```dart
// Add to the timing group
AppTextFieldGroup(
  variant: AppTextFieldVariant.outline,
  children: [
    AppDurationPickerCondensed(...), // Prep Time
    AppDurationPickerCondensed(...), // Cook Time  
    AppTextFieldCondensed(...),      // Servings
    FolderAssignmentRow(             // NEW: Folder Assignment
      currentFolderIds: widget.recipe.folderIds ?? [],
      onFolderIdsChanged: widget.onFolderIdsChanged,
      grouped: true,
    ),
  ],
)
```

**Recipe Form State Updates**:
- Add folder ID change handler in RecipeEditorForm
- Update local recipe state when folders change
- Ensure folder changes are included in save operation

### 5. Error Handling

**Edge Cases**:
- Handle deleted folders gracefully
- Manage network errors during folder fetching
- Handle concurrent folder modifications
- Validate folder permissions (user/household access)

**Loading States**:
- Show loading spinner while fetching folders
- Disable interaction during save operations
- Provide feedback for long-running operations

## Design System Compliance

### Typography
- Use `AppTypography.fieldInput` for folder names
- Use `AppTypography.caption` for count display
- Consistent with existing form field typography

### Colors
- Use `AppColors.of(context).textPrimary` for folder names
- Use `AppColors.of(context).textSecondary` for counts
- Follow checkbox styling from existing filter implementations

### Spacing
- Use `AppSpacing` constants throughout
- Match existing grouped field spacing
- Consistent modal padding with existing modals

### Interaction Patterns
- Follow existing Wolt modal patterns
- Use consistent button styling (AppButton system)
- Match existing checkbox interaction patterns

## Technical Considerations

### Performance
- Efficient folder name resolution (avoid N+1 queries)
- Proper dispose of controllers and subscriptions
- Optimized list rendering for large folder counts

### Accessibility
- Proper semantic labels for folder selection
- Screen reader support for folder counts
- Keyboard navigation support

### Data Consistency
- Ensure folder assignments are saved atomically with recipe
- Handle concurrent edits gracefully
- Validate folder existence before assignment

### Offline Support
- Work with PowerSync offline capabilities
- Queue folder changes when offline
- Sync folder assignments when connection restored

## Implementation Order

1. **Create FolderAssignmentRow widget** - Basic display and tap handling
2. **Create FolderSelectionModal** - Modal structure and folder list
3. **Implement folder checkbox list** - Selection logic and state management
4. **Integrate with recipe form** - Connect to recipe editor state
5. **Add folder creation integration** - Connect with existing add folder modal
6. **Testing and refinement** - Edge cases and polish

## Dependencies

### Existing Providers/Repositories
- `recipeFolderNotifierProvider` - For folder list
- `recipeNotifierProvider` - For folder assignment methods
- `recipeFolderRepositoryProvider` - For folder operations

### Existing Widgets/Components
- `AppTextFieldGroup` - For grouped styling
- `AppTextFieldCondensed` - For styling reference
- `showAddFolderModal` - For folder creation
- Wolt modal system - For modal implementation

### New Dependencies
- None required - all functionality available in existing system

## Success Criteria

1. **Functional**: Users can view and modify folder assignments from recipe editor
2. **Reactive**: Folder list updates immediately when folders are added/removed
3. **Consistent**: UI matches existing design system patterns
4. **Performant**: Fast loading and smooth interactions
5. **Accessible**: Proper screen reader and keyboard support
6. **Robust**: Handles edge cases and errors gracefully

This implementation will provide a seamless folder management experience within the recipe editor, leveraging the existing infrastructure while maintaining consistency with the app's design system and interaction patterns.