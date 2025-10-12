# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Common Commands

### Setup and Environment

```bash
# Install Flutter dependencies
flutter pub get
```

### Running the App

```bash
# Run the app in debug mode
flutter run

# Run the app on a specific device
flutter run -d <device_id>

# Run the app with release configuration
flutter run --release
```

### Testing

```bash
# Run all tests
flutter test

# Run a specific test file
flutter test test/path/to/test_file.dart

# Run integration tests
flutter drive --driver test/driver/integration_test.dart --target=test/integration/sample/<test_file>_test.dart

# Run specific integration test examples
flutter drive --driver test/driver/integration_test.dart --target=test/integration/sample/recipes_test.dart
flutter drive --driver test/driver/integration_test.dart --target=test/integration/sample/pantry_recipe_match_test.dart
```

### Code Generation

```bash
# Run build runner for code generation (for Drift, Riverpod, JSON serialization)
flutter pub run build_runner build

# Watch for changes and run code generation
flutter pub run build_runner watch
```

### Linting and Analysis

```bash
# Analyze the project for issues
flutter analyze

# Format the code
flutter format .
```

## Design System and Theming

**IMPORTANT**: Always use the centralized design system constants instead of hardcoding values.

### Theme Constants

1. **Spacing**: Use `AppSpacing` constants from `lib/src/theme/spacing.dart`
   ```dart
   import '../theme/spacing.dart';
   
   // Instead of: EdgeInsets.all(16)
   // Use: EdgeInsets.all(AppSpacing.lg)
   
   // Available: AppSpacing.xs (4px), .sm (8px), .md (12px), .lg (16px), .xl (24px), .xxl (32px)
   ```

2. **Colors**: Use `AppColors` and `AppColorSwatches` from `lib/src/theme/colors.dart`
   ```dart
   import '../theme/colors.dart';
   
   // Theme-aware colors (adapt to light/dark mode):
   AppColors.of(context).textSecondary
   AppColors.of(context).border
   
   // Fixed color swatches:
   AppColorSwatches.neutral[400]
   AppColorSwatches.primary[500]
   ```

3. **Typography**: Use `AppTypography` constants from `lib/src/theme/typography.dart`
   ```dart
   import '../theme/typography.dart';
   
   // Instead of: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)
   // Use: AppTypography.h5
   
   // Available: h1-h5, body, bodyLarge, bodySmall, label, caption, etc.
   ```

### Design System Rules

- **Never hardcode spacing values** - always use AppSpacing constants
- **Never hardcode colors** - use AppColors for theme-aware colors or AppColorSwatches for fixed colors  
- **Prefer semantic typography** - use AppTypography over custom TextStyle when possible
- **Follow existing patterns** - examine similar components before creating new styling

## Bottom Sheet (Wolt Modal) Design Guidelines

We use two types of Wolt modal sheets depending on content requirements:

### 1. WoltModalSheetPage (Simple/Short Content)

**When to use:**
- Simple forms with minimal scrolling
- Short content that fits on screen
- Single-page modals without complex scrolling behavior

**Configuration:**
```dart
WoltModalSheetPage(
  navBarHeight: 55,
  backgroundColor: AppColors.of(context).background,
  surfaceTintColor: Colors.transparent,
  hasTopBarLayer: false,
  isTopBarLayerAlwaysVisible: false,
  trailingNavBarWidget: Padding(
    padding: EdgeInsets.only(right: AppSpacing.lg),
    child: AppCircleButton(
      icon: AppCircleButtonIcon.close,
      variant: AppCircleButtonVariant.neutral,
      onPressed: () => Navigator.of(context).pop(),
    ),
  ),
  child: Padding(
    padding: EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Modal Title', style: AppTypography.h4.copyWith(
          color: AppColors.of(context).textPrimary,
        )),
        SizedBox(height: AppSpacing.lg),
        // Form content here
      ],
    ),
  ),
)
```

**Key points:**
- Title is placed in the content area (not using `pageTitle`)
- `hasTopBarLayer: false` - no built-in header border
- Use `AppCircleButton` with `neutral` variant for close button

**Example:** `lib/src/features/recipes/views/add_folder_modal.dart`

### 2. SliverWoltModalSheetPage (Scrollable Content)

**When to use:**
- Long scrollable content with multiple sections
- Complex layouts requiring Sliver widgets
- Modals with sticky action bars at bottom
- Content that needs scroll-aware header behavior

**Configuration:**
```dart
SliverWoltModalSheetPage(
  navBarHeight: 55,
  backgroundColor: AppColors.of(context).background,
  surfaceTintColor: Colors.transparent,
  hasTopBarLayer: true,
  isTopBarLayerAlwaysVisible: false,  // Border appears only when scrolling
  topBarTitle: ModalSheetTitle('Modal Title'),
  hasSabGradient: true,  // Gradient above sticky action bar
  trailingNavBarWidget: Padding(
    padding: EdgeInsets.only(right: AppSpacing.lg),
    child: AppCircleButton(
      icon: AppCircleButtonIcon.close,
      variant: AppCircleButtonVariant.neutral,
      onPressed: () => Navigator.of(context).pop(),
    ),
  ),
  mainContentSliversBuilder: (context) => [
    // Sliver widgets here
    SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: Text('Content'),
      ),
    ),
  ],
  stickyActionBar: Container(
    // Optional sticky button at bottom
    padding: EdgeInsets.all(AppSpacing.lg),
    child: AppButton(text: 'Submit', onPressed: () {}),
  ),
)
```

**Key points:**
- Title uses `topBarTitle: ModalSheetTitle('Title')` - **NOT** in content area
- `hasTopBarLayer: true` - enables Wolt's scroll-aware header
- **`isTopBarLayerAlwaysVisible: false`** - Border only appears when content scrolls under header (preferred for better UX)
- Uses `mainContentSliversBuilder` instead of `child`
- `hasSabGradient: true` shows gradient above sticky action bar

**Examples:**
- `lib/src/features/recipes/widgets/filter_sort/unified_sort_filter_sheet.dart`
- `lib/src/features/shopping_list/views/update_pantry_modal.dart`

### Important: isTopBarLayerAlwaysVisible Setting

**Always use `isTopBarLayerAlwaysVisible: false` for SliverWoltModalSheetPage:**

- `false` (preferred): Border appears only when scrolling - provides visual feedback that content is scrolling under header
- `true` (avoid): Border is always visible, even without scrolling - looks cluttered

### Shared Design Rules

**Form Elements:**
- Input fields: `AppTextFieldSimple` with 8px border radius
- Primary button: `AppButtonVariants.primaryFilled` with:
  - `size: AppButtonSize.large` (52px height)
  - `shape: AppButtonShape.square` (8px radius to match inputs)
  - `fullWidth: true`
- Button state: Disabled when input is empty (shows 50% opacity)

**Visual Consistency:**
- Border radius: 8px for both inputs and buttons (matching radius)
- Close button uses neutral gray colors (not primary)
- Always use `AppSpacing` constants for padding/margins

## Architecture Overview

### Application Structure

This is a Flutter recipe management app with support for multiple platforms (mobile, desktop). The codebase follows a feature-based architecture pattern.

Key architectural aspects:

1. **Database Layer**:
   - Uses Drift (SQLite wrapper) for local database
   - PowerSync for data synchronization
   - Supabase for backend services (auth, storage, etc.)

2. **State Management**:
   - Riverpod for state management
   - Repository pattern for data access
   - Provider pattern for dependency injection

3. **Multi-platform Support**:
   - Mobile-specific code in `lib/src/mobile/`
   - macOS-specific code in `lib/src/macos/`
   - Windows-specific code in `lib/src/windows/`
   - Adaptive widgets for cross-platform compatibility

4. **Feature Organization**:
   - Feature modules in `lib/src/features/`
   - Each feature contains views, widgets, models, and utils
   - Core functionality shared across features in `lib/src/`

5. **Database Architecture**:
   - Row-Level Security (RLS) in Supabase for data access control
   - Data sharing via households and direct user shares
   - Recipes organized into folders with sharing capabilities
   - See `adr/db.md` for detailed database architecture decisions

### Key Components

1. **Database Models**:
   - Models defined in `lib/database/models/` directory
   - Uses Drift for type-safe SQLite access
   - Recipes, folders, ingredients, steps as core models
   - Sharing models for collaborative features
   - Household models for group management
   - JSON storage for complex nested data (ingredients and steps are stored as JSON in the 'data' column)

2. **Domain Model and Term System**:
   - Core entities (Recipes, Folders, Ingredients, etc.) stored in SQLite
   - Recipe ingredients and pantry items have associated "terms" used for matching
   - Terms are the building blocks for matching ingredients with pantry items
   - Terms are stored directly in the recipe.ingredients array and pantry items
   - Terms are denormalized into separate tables (not managed by Drift) for efficient querying using SQLite triggers
   - Term canonicalization process converts user input into standardized terms via API calls
   - Recipe-pantry matching determines which recipes can be made with on-hand ingredients

3. **Term Canonicalization**:
   - Implemented in `ingredient_canonicalization_service.dart`
   - Processes raw ingredient or pantry item names
   - Generates standardized terms for matching
   - Uses queue system for processing when offline
   - Enables smart recipe-pantry matching

4. **Providers**:
   - Centralized in the `lib/src/providers/` directory
   - Implement business logic and state management
   - Connect repositories with UI components
   - Use Riverpod for reactive state management
   - Provider hierarchy for derived state (e.g., recipe matches)

5. **Synchronization**:
   - PowerSync for offline-first capabilities
   - Upload queues for handling offline changes
   - Term materialization and canonicalization for consistent data

6. **UI Components**:
   - Adaptive components for cross-platform rendering
   - Custom navigation system with sidebar on larger devices
   - Wolt modal sheets for complex bottom sheet interactions
   - Modal sheets and forms for data entry

7. **Routing**:
   - GoRouter for declarative routing
   - Main routes defined in `lib/src/mobile/adaptive_app.dart`
   - Windows routes in `lib/src/windows/core/router.dart`
   - Adaptive navigation patterns based on device type
   - Shell routes for persistent navigation elements

8. **Adaptive UI Structure**:
   - `AdaptiveSliverPage` and `AdaptiveSheetPage` for cross-platform layout
   - Handles platform differences (iOS/Android/desktop)
   - Manages navigation bar styling, padding, and scrolling behavior
   - Adapts to different screen sizes and orientations

9. **Recipe Features**:
   - Recipe management (create, update, delete)
   - Folder organization
   - Filtering and sorting
   - Cooking mode
   - Pantry matching

10. **Filter and Sort System**:
    - Unified filter and sort provider
    - Declarative filtering approach
    - Support for multiple contexts (recipe search, folder view, pantry match)

## Data Flow

1. **Repository Layer**: Data access abstraction for database operations
2. **Provider Layer**: Business logic and state management using Riverpod
3. **Feature Components**: UI rendering and user interaction
4. **Term Processing**: Canonicalization and materialization of terms for matching

## Important Implementation Details

1. **JSON Storage in Drift**:
   - Complex nested data (ingredients, steps) stored in 'data' column of type JSONB
   - Custom converters transform between Dart objects and JSON

2. **Term System**:
   - Terms are the foundation for ingredient-pantry matching
   - Generated through canonicalization process
   - Denormalized into dedicated tables (not managed by Drift, so exist in real text columns instead of embedded within the data column as JSONB) for query efficiency
   - Enables smart recipe filtering based on pantry contents

3. **Wolt Bottom Sheets**:
   - Used throughout the app for modal interactions
   - Multi-page navigation within sheets
   - Consistent design system for sheet components

4. **Adaptive UI**:
   - `AdaptiveSliverPage` for handling platform differences
   - Responsive layouts based on screen size
   - Platform-specific interaction patterns

## Claude Code Specific Guidance

You have access to "memory", an MCP server exposing a vector-enhanced knowledge graph for remembering project information across conversations.

Follow these guidelines for each interaction:

1. **Memory Retrieval**:
    - Always start by saying "Checking project memory..." and search your knowledge graph for relevant information
    - Use semantic search to find related concepts, even if terminology differs
    - Look for architectural decisions, constraints, and previous solutions

2. **Information Capture**:
    - Continuously identify and store new information in these categories:
      a) **Technical Details**: Components, services, APIs, databases, file locations
      b) **Architectural Decisions**: Technology choices, design patterns, trade-offs made
      c) **Constraints & Requirements**: Performance targets, security needs, compliance rules
      d) **Project Context**: Team preferences, deadlines, stakeholder requirements
      e) **Operational Knowledge**: Deployment configs, monitoring alerts, known issues
      f) **Historical Context**: Bug fixes, optimizations, failed approaches

3. **Entity Creation Strategy**:
    - Create entities for recurring system components, decisions, and requirements
    - Use appropriate development-focused entity types (component, decision, constraint, etc.)
    - Connect related entities with "relates_to" relationships
    - Store specifics in observations with timestamps and file references

4. **Semantic Organization**:
    - Include file paths and line numbers in observations when relevant
    - Add temporal context ("as of", "since", "currently") to track evolution
    - Capture both successful solutions and approaches that didn't work
    - Link business requirements to technical implementations

5. **Memory Maintenance**:
    - Update observations when implementation details change
    - Preserve historical context rather than overwriting
    - Use semantic search to find related existing entities before creating new ones

Example entity creation:
- Entity: "JWT_Authentication_Decision" (type: decision)
- Observations: ["Chose JWT over sessions for mobile app compatibility", "Implemented in src/auth/jwt.ts:45", "Considered security implications of stateless tokens", "Team preferred this for microservices architecture"]
