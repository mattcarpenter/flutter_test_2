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
flutter drive --driver test/driver/integration_test.dart --target=test/integration/sample/<test_file>.test.dart

# Run specific integration test examples
flutter drive --driver test/driver/integration_test.dart --target=test/integration/sample/recipes.test.dart
flutter drive --driver test/driver/integration_test.dart --target=test/integration/sample/pantry_recipe_match.test.dart
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
   - Models defined in `database/models/` directory
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
   - Denormalized into dedicated tables for query efficiency
   - Enables smart recipe filtering based on pantry contents

3. **Wolt Bottom Sheets**:
   - Used throughout the app for modal interactions
   - Multi-page navigation within sheets
   - Consistent design system for sheet components

4. **Adaptive UI**:
   - `AdaptiveSliverPage` for handling platform differences
   - Responsive layouts based on screen size
   - Platform-specific interaction patterns