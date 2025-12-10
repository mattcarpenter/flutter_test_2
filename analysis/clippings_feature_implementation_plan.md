# Clippings Feature Implementation Plan

## Overview

The Clippings feature provides a lightweight note-taking experience similar to Apple Notes, allowing users to quickly capture recipe-related information without creating a fully-structured recipe. This enables rapid capture of partial ingredient lists, cooking techniques, or other culinary notes for future AI-powered conversion.

### Key Characteristics
- **Notes-like UX**: Simple, immediate editing (no separate view/edit modes)
- **First line as title**: Auto-derived title from first line of content
- **Rich text support**: Basic formatting via flutter_quill (bullets, checkboxes, links)
- **Auto-save with debounce**: No save button, changes persist automatically
- **PowerSync synced**: Full offline support with cloud synchronization

---

## Phase 1: Database Layer

### 1.1 PostgreSQL DDL (`ddls/postgres_powersync.sql`)

Add the following table definition:

```sql
-- CLIPPINGS
CREATE TABLE public.clippings (
    id uuid NOT NULL DEFAULT extensions.uuid_generate_v4(),
    title text NULL,
    content text NULL,
    user_id uuid NOT NULL,
    household_id uuid NULL,
    created_at bigint NULL,
    updated_at bigint NULL,
    deleted_at bigint NULL,
    CONSTRAINT clippings_pkey PRIMARY KEY (id),
    CONSTRAINT clippings_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users (id) ON DELETE CASCADE,
    CONSTRAINT clippings_household_id_fkey FOREIGN KEY (household_id) REFERENCES public.households (id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS clippings_user_idx ON public.clippings (user_id);
CREATE INDEX IF NOT EXISTS clippings_household_idx ON public.clippings (household_id);
CREATE INDEX IF NOT EXISTS clippings_updated_at_idx ON public.clippings (updated_at DESC);
```

**Field Notes:**
- `title`: Extracted from first line of content, stored separately for efficient list display
- `content`: Quill Delta JSON stored as text (recommended over HTML/Markdown per flutter_quill best practices)
- `user_id`: Required ownership field
- `household_id`: Optional, enables household sharing
- `deleted_at`: Soft delete support
- Additional index on `updated_at` for efficient sorting by recently modified

### 1.2 PowerSync Sync Rules (`ddls/sync-rules.yaml`)

Add after existing bucket definitions:

```yaml
clippings_belongs_to_user:
  parameters: SELECT request.user_id() as user_id
  data:
    - SELECT * FROM public.clippings WHERE user_id = bucket.user_id

clippings_belongs_to_household:
  parameters: SELECT household_id FROM household_members WHERE user_id = request.user_id() AND is_active = 1
  data:
    - SELECT * FROM public.clippings WHERE household_id = bucket.household_id
```

### 1.3 RLS Policies (`ddls/policies_powersync.sql`)

Add after existing policy definitions:

```sql
-- RLS policies for clippings
ALTER TABLE clippings ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view clippings"
    ON clippings
    FOR SELECT
    USING (
        auth.uid() = user_id
            OR (household_id IS NOT NULL AND is_household_member(household_id, auth.uid()))
    );

CREATE POLICY "Users can insert clippings"
    ON clippings
    FOR INSERT
    WITH CHECK (
        auth.uid() = user_id
            OR (household_id IS NOT NULL AND is_household_member(household_id, auth.uid()))
    );

CREATE POLICY "Users can update clippings"
    ON clippings
    FOR UPDATE
    USING (
        auth.uid() = user_id
            OR (household_id IS NOT NULL AND is_household_member(household_id, auth.uid()))
    )
    WITH CHECK (
        household_id IS NULL OR is_household_member(household_id, auth.uid())
    );

CREATE POLICY "Users can delete clippings"
    ON clippings
    FOR DELETE
    USING (
        auth.uid() = user_id
            OR (household_id IS NOT NULL AND is_household_member(household_id, auth.uid()))
    );
```

### 1.4 Drift Schema (`lib/database/schema.dart`)

Add table name constant at top of file (around line 24):

```dart
const clippingsTable = 'clippings';
```

Add to Schema object in the `const Schema([...])` block:

```dart
Table(clippingsTable, [
  Column.text('title'),
  Column.text('content'),
  Column.text('user_id'),
  Column.text('household_id'),
  Column.integer('created_at'),
  Column.integer('updated_at'),
  Column.integer('deleted_at'),
]),
```

### 1.5 Drift Table Model

Create new file: `lib/database/models/clippings.dart`

```dart
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

@DataClassName('ClippingEntry')
class Clippings extends Table {
  // Primary key with client-side UUID generation
  TextColumn get id => text().clientDefault(() => const Uuid().v4())();

  @override
  Set<Column> get primaryKey => {id};

  // Content fields
  TextColumn get title => text().nullable()();
  TextColumn get content => text().nullable()();  // Quill Delta JSON

  // Ownership fields
  TextColumn get userId => text().nullable()();
  TextColumn get householdId => text().nullable()();

  // Timestamps
  IntColumn get createdAt => integer().nullable()();
  IntColumn get updatedAt => integer().nullable()();
  IntColumn get deletedAt => integer().nullable()();
}
```

### 1.6 Database Registration (`lib/database/database.dart`)

1. Add import at top:
```dart
import 'models/clippings.dart';
```

2. Add `Clippings` to the `@DriftDatabase` annotation tables list.

---

## Phase 2: Data Access Layer

### 2.1 Repository (`lib/src/repositories/clippings_repository.dart`)

Create new file following the pantry_repository.dart pattern:

```dart
import 'dart:async';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../database/database.dart';
import '../services/logging/app_logger.dart';

class ClippingsRepository {
  final AppDatabase _db;

  ClippingsRepository(this._db);

  /// Watch all non-deleted clippings
  Stream<List<ClippingEntry>> watchClippings() {
    return (_db.select(_db.clippings)
          ..where((c) => c.deletedAt.isNull())
          ..orderBy([
            (c) => OrderingTerm(expression: c.updatedAt, mode: OrderingMode.desc)
          ]))
        .watch();
  }

  /// Get a single clipping by ID
  Future<ClippingEntry?> getClipping(String id) async {
    return (_db.select(_db.clippings)..where((c) => c.id.equals(id)))
        .getSingleOrNull();
  }

  /// Create a new clipping
  Future<String> addClipping({
    required String userId,
    String? householdId,
    String? title,
    String? content,
  }) async {
    final newId = const Uuid().v4();
    final now = DateTime.now().millisecondsSinceEpoch;

    await _db.into(_db.clippings).insert(ClippingsCompanion(
      id: Value(newId),
      title: Value(title),
      content: Value(content),
      userId: Value(userId),
      householdId: Value(householdId),
      createdAt: Value(now),
      updatedAt: Value(now),
    ));

    AppLogger.debug('Created clipping: $newId');
    return newId;
  }

  /// Update an existing clipping
  Future<void> updateClipping({
    required String id,
    String? title,
    String? content,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;

    await (_db.update(_db.clippings)..where((c) => c.id.equals(id))).write(
      ClippingsCompanion(
        title: Value(title),
        content: Value(content),
        updatedAt: Value(now),
      ),
    );

    AppLogger.debug('Updated clipping: $id');
  }

  /// Soft delete a clipping
  Future<void> deleteClipping(String id) async {
    final now = DateTime.now().millisecondsSinceEpoch;

    await (_db.update(_db.clippings)..where((c) => c.id.equals(id))).write(
      ClippingsCompanion(
        deletedAt: Value(now),
      ),
    );

    AppLogger.debug('Soft deleted clipping: $id');
  }

  /// Bulk soft delete multiple clippings
  Future<void> deleteMultipleClippings(List<String> ids) async {
    if (ids.isEmpty) return;

    final now = DateTime.now().millisecondsSinceEpoch;

    await (_db.update(_db.clippings)..where((c) => c.id.isIn(ids))).write(
      ClippingsCompanion(
        deletedAt: Value(now),
      ),
    );

    AppLogger.debug('Soft deleted ${ids.length} clippings');
  }
}

/// Provider for ClippingsRepository
final clippingsRepositoryProvider = Provider<ClippingsRepository>((ref) {
  return ClippingsRepository(appDb);
});
```

### 2.2 Provider (`lib/src/providers/clippings_provider.dart`)

Create new file following the pantry_provider.dart pattern:

```dart
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../database/database.dart';
import '../repositories/clippings_repository.dart';
import '../services/logging/app_logger.dart';

class ClippingsNotifier extends StateNotifier<AsyncValue<List<ClippingEntry>>> {
  final ClippingsRepository _repository;
  late final StreamSubscription<List<ClippingEntry>> _subscription;

  ClippingsNotifier(this._repository) : super(const AsyncValue.loading()) {
    _subscription = _repository.watchClippings().listen(
      (clippings) {
        state = AsyncValue.data(clippings);
      },
      onError: (error, stack) {
        AppLogger.error('Error watching clippings', error, stack);
        state = AsyncValue.error(error, stack);
      },
    );
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  Future<String> addClipping({
    required String userId,
    String? householdId,
    String? title,
    String? content,
  }) async {
    return _repository.addClipping(
      userId: userId,
      householdId: householdId,
      title: title,
      content: content,
    );
  }

  Future<void> updateClipping({
    required String id,
    String? title,
    String? content,
  }) async {
    await _repository.updateClipping(
      id: id,
      title: title,
      content: content,
    );
  }

  Future<void> deleteClipping(String id) async {
    await _repository.deleteClipping(id);
  }

  Future<void> deleteMultipleClippings(List<String> ids) async {
    await _repository.deleteMultipleClippings(ids);
  }
}

/// Main provider for clippings list
final clippingsProvider = StateNotifierProvider<ClippingsNotifier, AsyncValue<List<ClippingEntry>>>((ref) {
  return ClippingsNotifier(ref.watch(clippingsRepositoryProvider));
});
```

### 2.3 Filter/Sort Provider (`lib/src/providers/clippings_filter_sort_provider.dart`)

Create new file for sorting state:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum ClippingSortOption {
  recentlyModified,
  recentlyCreated,
  alphabetical,
}

enum SortDirection { ascending, descending }

class ClippingsFilterSortState {
  final ClippingSortOption sortOption;
  final SortDirection sortDirection;
  final String searchQuery;

  const ClippingsFilterSortState({
    this.sortOption = ClippingSortOption.recentlyModified,
    this.sortDirection = SortDirection.descending,
    this.searchQuery = '',
  });

  ClippingsFilterSortState copyWith({
    ClippingSortOption? sortOption,
    SortDirection? sortDirection,
    String? searchQuery,
  }) {
    return ClippingsFilterSortState(
      sortOption: sortOption ?? this.sortOption,
      sortDirection: sortDirection ?? this.sortDirection,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

class ClippingsFilterSortNotifier extends Notifier<ClippingsFilterSortState> {
  static const _sortOptionKey = 'clippings_sort_option';
  static const _sortDirectionKey = 'clippings_sort_direction';

  @override
  ClippingsFilterSortState build() {
    _loadState();
    return const ClippingsFilterSortState();
  }

  Future<void> _loadState() async {
    final prefs = await SharedPreferences.getInstance();
    final sortIndex = prefs.getInt(_sortOptionKey) ?? 0;
    final dirIndex = prefs.getInt(_sortDirectionKey) ?? 1;

    state = state.copyWith(
      sortOption: ClippingSortOption.values[sortIndex],
      sortDirection: SortDirection.values[dirIndex],
    );
  }

  Future<void> _saveState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_sortOptionKey, state.sortOption.index);
    await prefs.setInt(_sortDirectionKey, state.sortDirection.index);
  }

  void updateSortOption(ClippingSortOption option) {
    state = state.copyWith(sortOption: option);
    _saveState();
  }

  void updateSortDirection(SortDirection direction) {
    state = state.copyWith(sortDirection: direction);
    _saveState();
  }

  void toggleSortDirection() {
    final newDirection = state.sortDirection == SortDirection.ascending
        ? SortDirection.descending
        : SortDirection.ascending;
    updateSortDirection(newDirection);
  }

  void updateSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void clearSearch() {
    state = state.copyWith(searchQuery: '');
  }
}

final clippingsFilterSortProvider =
    NotifierProvider<ClippingsFilterSortNotifier, ClippingsFilterSortState>(
  ClippingsFilterSortNotifier.new,
);
```

### 2.4 Filter/Sort Extensions (`lib/src/features/clippings/models/clippings_filter_sort.dart`)

Create new file:

```dart
import '../../../../database/database.dart';
import '../../../providers/clippings_filter_sort_provider.dart';

extension ClippingsFiltering on List<ClippingEntry> {
  List<ClippingEntry> applySearch(String query) {
    if (query.isEmpty) return this;

    final lowerQuery = query.toLowerCase();
    return where((clipping) {
      final title = clipping.title?.toLowerCase() ?? '';
      final content = clipping.content?.toLowerCase() ?? '';
      return title.contains(lowerQuery) || content.contains(lowerQuery);
    }).toList();
  }
}

extension ClippingsSorting on List<ClippingEntry> {
  List<ClippingEntry> applySorting(
    ClippingSortOption option,
    SortDirection direction,
  ) {
    final sorted = List<ClippingEntry>.from(this);

    switch (option) {
      case ClippingSortOption.recentlyModified:
        sorted.sort((a, b) {
          final aTime = a.updatedAt ?? 0;
          final bTime = b.updatedAt ?? 0;
          return direction == SortDirection.descending
              ? bTime.compareTo(aTime)
              : aTime.compareTo(bTime);
        });
        break;
      case ClippingSortOption.recentlyCreated:
        sorted.sort((a, b) {
          final aTime = a.createdAt ?? 0;
          final bTime = b.createdAt ?? 0;
          return direction == SortDirection.descending
              ? bTime.compareTo(aTime)
              : aTime.compareTo(bTime);
        });
        break;
      case ClippingSortOption.alphabetical:
        sorted.sort((a, b) {
          final aTitle = a.title?.toLowerCase() ?? '';
          final bTitle = b.title?.toLowerCase() ?? '';
          return direction == SortDirection.ascending
              ? aTitle.compareTo(bTitle)
              : bTitle.compareTo(aTitle);
        });
        break;
    }

    return sorted;
  }
}
```

---

## Phase 3: Feature Structure

### 3.1 Directory Structure

Create the following directory structure:

```
lib/src/features/clippings/
├── views/
│   ├── clippings_root.dart          # Main list page
│   └── clipping_editor_page.dart    # Editor page (full screen, not modal)
├── widgets/
│   ├── clipping_card.dart           # List item card
│   ├── clipping_list.dart           # List container
│   └── clippings_sort_menu.dart     # Sort dropdown menu
└── models/
    └── clippings_filter_sort.dart   # Filter/sort extensions (created above)
```

---

## Phase 4: UI Components

### 4.1 Clippings List Page (`lib/src/features/clippings/views/clippings_root.dart`)

Key aspects:
- Use `AdaptiveSliverPage` as container (like pantry_root.dart)
- Header with Sort button (left) + Add button (right)
- Grid/list of clipping cards
- Empty state when no clippings

```dart
// Structure outline
class ClippingsTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clippingsAsyncValue = ref.watch(clippingsProvider);
    final filterSortState = ref.watch(clippingsFilterSortProvider);

    return AdaptiveSliverPage(
      title: 'Clippings',
      trailing: AdaptivePullDownButton(
        items: [/* Add clipping action */],
        child: /* Add button icon */,
      ),
      slivers: [
        // Sort header (SliverPersistentHeader)
        _buildSortHeader(context, ref, filterSortState),

        // Clippings list
        clippingsAsyncValue.when(
          loading: () => /* Loading state */,
          error: (e, st) => /* Error state */,
          data: (clippings) {
            var filtered = clippings.applySearch(filterSortState.searchQuery);
            var sorted = filtered.applySorting(
              filterSortState.sortOption,
              filterSortState.sortDirection,
            );
            return ClippingsList(clippings: sorted);
          },
        ),
      ],
    );
  }
}
```

### 4.2 Clipping Card (`lib/src/features/clippings/widgets/clipping_card.dart`)

Design specifications:
- Similar layout to FolderCard (Row with preview + text)
- **Preview area (left)**: Shows first few lines of content in small text
  - Background: `AppColors.of(context).surfaceElevated`
  - Text: `AppTypography.caption` with `AppColors.of(context).textSecondary`
  - Max 3-4 lines with overflow clipping
  - Rounded corners (8px)
- **Text area (right)**:
  - Title: 1-2 lines, `AppTypography.body` with primary text color
  - Subtitle: "Modified X ago" in secondary color
- Context menu: Edit, Delete
- Tap navigates to editor page

### 4.3 Sort Menu (`lib/src/features/clippings/widgets/clippings_sort_menu.dart`)

Simple adaptive pull-down menu with sort options:
- Recently Modified (default)
- Recently Created
- Alphabetical (A-Z / Z-A)

Use `AdaptivePullDownButton` wrapped in `AppButton` with `mutedOutline` style.

### 4.4 Clipping Editor Page (`lib/src/features/clippings/views/clipping_editor_page.dart`)

This is the core editor experience. Key requirements:

#### Header Bar
- **No large title** (use standard app bar height)
- **Leading**: Back button (automatic via navigation)
- **Trailing (focused)**: "Done" text button - unfocuses input, dismisses keyboard
- **Trailing (not focused)**: "..." AppCircleButton with overflow menu
  - Delete clipping
  - Share (future)

#### Title Field
- First line of editor acts as title
- Larger text style (`AppTypography.h4` or similar)
- No rich text formatting (plain text only)
- Hitting Enter moves cursor to content area

#### Content Area (flutter_quill)
- Rich text editor using `QuillEditor`
- Minimal toolbar (appears above keyboard when focused):
  - Bold, Italic
  - Bullet list, Numbered list
  - Checkbox/todo
  - Link
- No image/video support
- Store as Quill Delta JSON

#### Auto-Save with Debounce
- **Debounce duration**: 1000ms (1 second)
- On any text change, reset debounce timer
- When timer fires, save to database
- Also save immediately on:
  - Page pop/back navigation
  - App going to background
- Use `Timer` class for debouncing (see recipe_provider.dart pattern)

#### Implementation Pattern

```dart
class ClippingEditorPage extends ConsumerStatefulWidget {
  final String? clippingId;  // null for new clipping

  @override
  ConsumerState createState() => _ClippingEditorPageState();
}

class _ClippingEditorPageState extends ConsumerState<ClippingEditorPage> {
  late TextEditingController _titleController;
  late QuillController _contentController;
  late FocusNode _titleFocusNode;
  late FocusNode _contentFocusNode;

  Timer? _saveDebounceTimer;
  bool _isDirty = false;
  bool _isSaving = false;
  String? _clippingId;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _loadClipping();
  }

  void _onTitleChanged() {
    _markDirty();
  }

  void _onContentChanged() {
    _markDirty();
  }

  void _markDirty() {
    _isDirty = true;
    _saveDebounceTimer?.cancel();
    _saveDebounceTimer = Timer(const Duration(milliseconds: 1000), _saveChanges);
  }

  Future<void> _saveChanges() async {
    if (!_isDirty || _isSaving) return;

    setState(() => _isSaving = true);

    try {
      final title = _extractTitle();
      final content = jsonEncode(_contentController.document.toDelta().toJson());

      if (_clippingId == null) {
        // Create new clipping
        _clippingId = await ref.read(clippingsProvider.notifier).addClipping(
          userId: /* current user id */,
          title: title,
          content: content,
        );
      } else {
        // Update existing
        await ref.read(clippingsProvider.notifier).updateClipping(
          id: _clippingId!,
          title: title,
          content: content,
        );
      }

      _isDirty = false;
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  String _extractTitle() {
    final titleText = _titleController.text.trim();
    if (titleText.isNotEmpty) {
      return titleText;
    }
    // Extract from content (first few words)
    final plainText = _contentController.document.toPlainText().trim();
    final words = plainText.split(' ').take(6).join(' ');
    return words.isEmpty ? 'Untitled' : words;
  }

  @override
  void dispose() {
    _saveDebounceTimer?.cancel();
    // Ensure final save before dispose
    if (_isDirty) {
      _saveChanges();
    }
    _titleController.dispose();
    _contentController.dispose();
    _titleFocusNode.dispose();
    _contentFocusNode.dispose();
    super.dispose();
  }
}
```

---

## Phase 5: Navigation Integration

### 5.1 Add Menu Item (`lib/src/widgets/menu/menu.dart`)

Add after Pantry menu item (around line 84):

```dart
MenuItem(
  index: 5,  // New index for Clippings
  title: 'Clippings',
  icon: CupertinoIcons.doc_text,  // or CupertinoIcons.square_list
  isActive: selectedIndex == 5,
  color: primaryColor,
  textColor: textColor,
  activeTextColor: activeTextColor,
  backgroundColor: backgroundColor,
  onTap: onMenuItemClick,
),
```

### 5.2 Update Index Mapping (`lib/src/mobile/main_page_shell.dart`)

Update `_selectedIndexFromLocation()`:

```dart
if (location.startsWith('/clippings')) return 5;
if (location.startsWith('/labs')) return 6;  // Shift up
if (location.startsWith('/household')) return 9;  // Shift up
if (location.startsWith('/settings')) return 10;  // Shift up
if (location.startsWith('/auth')) return 11;  // Shift up
```

### 5.3 Add Routes (`lib/src/mobile/adaptive_app.dart`)

1. Add import:
```dart
import '../features/clippings/views/clippings_root.dart';
import '../features/clippings/views/clipping_editor_page.dart';
```

2. Add navigator key:
```dart
final _clippingsNavKey = GlobalKey<NavigatorState>(debugLabel: 'clippingsNavKey');
```

3. Add ShellRoute after Pantry shell:
```dart
// TAB 5 SHELL: Clippings
ShellRoute(
  navigatorKey: _clippingsNavKey,
  pageBuilder: (context, state, child) {
    return CustomTransitionPage<void>(
      key: state.pageKey,
      child: child,
      transitionDuration: const Duration(milliseconds: 400),
      reverseTransitionDuration: const Duration(milliseconds: 400),
      transitionsBuilder: (context, animation, secondaryAnimation, child) =>
          CupertinoTabPageTransition(animation: animation, child: child),
    );
  },
  routes: [
    GoRoute(
      path: '/clippings',
      routes: [
        GoRoute(
          path: ':id',
          pageBuilder: (context, state) => _platformPage(
            state: state,
            child: ClippingEditorPage(
              clippingId: state.pathParameters['id'],
            ),
          ),
        ),
        GoRoute(
          path: 'new',
          pageBuilder: (context, state) => _platformPage(
            state: state,
            child: const ClippingEditorPage(clippingId: null),
          ),
        ),
      ],
      pageBuilder: (context, state) => _platformPage(
        state: state,
        child: const ClippingsTab(),
      ),
    ),
  ],
),
```

---

## Phase 6: flutter_quill Integration

### 6.1 Add Dependency

Add to `pubspec.yaml`:

```yaml
dependencies:
  flutter_quill: ^11.5.0
```

Run `flutter pub get`.

### 6.2 Quill Configuration

```dart
// Import with alias to avoid conflicts
import 'package:flutter_quill/flutter_quill.dart' as quill;

// Initialize controller
quill.QuillController _contentController = quill.QuillController.basic();

// Load existing content
void _loadContent(String? deltaJson) {
  if (deltaJson != null && deltaJson.isNotEmpty) {
    try {
      final delta = quill.Delta.fromJson(jsonDecode(deltaJson));
      _contentController = quill.QuillController(
        document: quill.Document.fromDelta(delta),
        selection: const TextSelection.collapsed(offset: 0),
      );
    } catch (e) {
      AppLogger.error('Failed to parse Quill delta', e);
      _contentController = quill.QuillController.basic();
    }
  }
}

// Build editor
quill.QuillEditor.basic(
  controller: _contentController,
  config: quill.QuillEditorConfig(
    placeholder: 'Start typing...',
    padding: EdgeInsets.all(AppSpacing.lg),
    autoFocus: false,
    expands: true,
    scrollable: true,
  ),
)

// Build minimal toolbar (shown above keyboard)
quill.QuillSimpleToolbar(
  controller: _contentController,
  config: quill.QuillSimpleToolbarConfig(
    showBoldButton: true,
    showItalicButton: true,
    showListBullets: true,
    showListNumbers: true,
    showListCheck: true,
    showLink: true,
    // Disable all other buttons
    showUnderLineButton: false,
    showStrikeThrough: false,
    showColorButton: false,
    showBackgroundColorButton: false,
    showClearFormat: false,
    showAlignmentButtons: false,
    showHeaderStyle: false,
    showCodeBlock: false,
    showQuote: false,
    showIndent: false,
    showDividers: false,
    showFontFamily: false,
    showFontSize: false,
    showSearchButton: false,
    showSubscript: false,
    showSuperscript: false,
    showInlineCode: false,
    showUndo: false,
    showRedo: false,
  ),
)
```

### 6.3 Title + Content Layout

The editor page needs a custom layout where:
1. Title field (plain TextField) is at top
2. Quill editor fills remaining space below
3. Toolbar appears above keyboard when focused

```dart
@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: _buildAppBar(context),
    body: SafeArea(
      child: Column(
        children: [
          // Title field
          Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 0
            ),
            child: TextField(
              controller: _titleController,
              focusNode: _titleFocusNode,
              style: AppTypography.h4.copyWith(
                color: AppColors.of(context).textPrimary,
              ),
              decoration: InputDecoration(
                hintText: 'Title',
                hintStyle: AppTypography.h4.copyWith(
                  color: AppColors.of(context).textTertiary,
                ),
                border: InputBorder.none,
              ),
              textInputAction: TextInputAction.next,
              onSubmitted: (_) {
                _contentFocusNode.requestFocus();
              },
            ),
          ),

          // Divider
          Divider(
            height: 1,
            color: AppColors.of(context).border,
            indent: AppSpacing.lg,
            endIndent: AppSpacing.lg,
          ),

          // Quill editor
          Expanded(
            child: quill.QuillEditor.basic(
              controller: _contentController,
              focusNode: _contentFocusNode,
              config: quill.QuillEditorConfig(
                placeholder: 'Start typing...',
                padding: EdgeInsets.all(AppSpacing.lg),
                expands: true,
                scrollable: true,
              ),
            ),
          ),

          // Toolbar (visible when content focused)
          if (_isContentFocused)
            quill.QuillSimpleToolbar(
              controller: _contentController,
              config: _toolbarConfig,
            ),
        ],
      ),
    ),
  );
}
```

---

## Phase 7: Implementation Checklist

### Database Layer
- [ ] Add `clippings` table to `ddls/postgres_powersync.sql`
- [ ] Add sync rules to `ddls/sync-rules.yaml`
- [ ] Add RLS policies to `ddls/policies_powersync.sql`
- [ ] Add table constant to `lib/database/schema.dart`
- [ ] Add Table definition to Schema object in `lib/database/schema.dart`
- [ ] Create `lib/database/models/clippings.dart`
- [ ] Add import and table to `lib/database/database.dart`
- [ ] Run `flutter pub run build_runner build` to generate Drift code

### Data Access Layer
- [ ] Create `lib/src/repositories/clippings_repository.dart`
- [ ] Create `lib/src/providers/clippings_provider.dart`
- [ ] Create `lib/src/providers/clippings_filter_sort_provider.dart`

### Feature Structure
- [ ] Create `lib/src/features/clippings/` directory structure
- [ ] Create `lib/src/features/clippings/models/clippings_filter_sort.dart`

### Dependencies
- [ ] Add `flutter_quill: ^11.5.0` to `pubspec.yaml`
- [ ] Run `flutter pub get`

### UI Components
- [ ] Create `lib/src/features/clippings/views/clippings_root.dart`
- [ ] Create `lib/src/features/clippings/views/clipping_editor_page.dart`
- [ ] Create `lib/src/features/clippings/widgets/clipping_card.dart`
- [ ] Create `lib/src/features/clippings/widgets/clipping_list.dart`
- [ ] Create `lib/src/features/clippings/widgets/clippings_sort_menu.dart`

### Navigation
- [ ] Add menu item to `lib/src/widgets/menu/menu.dart`
- [ ] Update index mapping in `lib/src/mobile/main_page_shell.dart`
- [ ] Add routes to `lib/src/mobile/adaptive_app.dart`

### Testing
- [ ] Test database operations (CRUD)
- [ ] Test sync rules work correctly
- [ ] Test editor auto-save debouncing
- [ ] Test title extraction from first line
- [ ] Test Quill Delta JSON storage/retrieval
- [ ] Test navigation flow (list -> editor -> back)
- [ ] Test empty state handling
- [ ] Test delete functionality

---

## Technical Decisions & Trade-offs

### Why Quill Delta JSON over HTML/Markdown?
Per flutter_quill best practices, storing as Delta JSON provides:
- Lossless round-trip (no conversion artifacts)
- Smaller storage footprint
- Direct compatibility with QuillController
- No dependency on HTML/Markdown converters

### Why separate title field?
- Enables efficient list display without parsing content
- Allows plain text title (no accidental rich text)
- Matches iOS Notes behavior where title is distinct
- Simplifies search indexing

### Why 1 second debounce?
- Balances responsiveness with sync efficiency
- Prevents excessive PowerSync writes during rapid typing
- Similar to standard auto-save patterns (Google Docs uses ~1-3 seconds)

### Why not use Wolt Modal for editor?
- Full-screen editor provides better writing experience
- Modal height constraints would limit content visibility
- Back navigation is more natural for document editing
- Matches iOS Notes UX pattern

---

## Future Enhancements (Out of Scope)

1. **AI Integration**: Convert clippings to recipes, shopping lists
2. **Tags/Categories**: Organize clippings with labels
3. **Search**: Full-text search across all clippings
4. **Sharing**: Share clippings with household members
5. **Import**: Paste detection for automatic clipping creation
6. **Export**: Export as text, PDF, or other formats