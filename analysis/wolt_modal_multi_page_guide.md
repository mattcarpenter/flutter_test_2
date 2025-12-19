# Wolt Modal Multi-Page Bottom Sheet Guide

This guide documents the correct patterns for implementing multi-page bottom sheets using `wolt_modal_sheet` to avoid visual glitches like duplicate drag handles, height jumping, and jank during page transitions.

## Common Issues & Solutions

### Issue 1: Duplicate Drag Handle During Page Transitions

**Symptom:** When transitioning between pages, a duplicate horizontal gray drag handle appears briefly.

**Cause:** Using `SliverToBoxAdapter` to wrap content in `mainContentSliversBuilder` instead of returning Slivers directly.

**Wrong:**
```dart
mainContentSliversBuilder: (builderContext) => [
  SliverToBoxAdapter(  // ❌ Don't wrap in SliverToBoxAdapter
    child: MyContent(),
  ),
],
```

**Correct:**
```dart
mainContentSliversBuilder: (builderContext) => [
  Consumer(
    builder: (consumerContext, ref, child) {
      return MyContent();  // ✅ Content widget returns Slivers directly
    },
  ),
],
```

The content widget's `build()` method must return Sliver widgets:
```dart
@override
Widget build(BuildContext context) {
  return someAsyncValue.when(
    loading: () => const SliverFillRemaining(  // ✅ Sliver
      child: Center(child: CupertinoActivityIndicator()),
    ),
    error: (error, stack) => SliverFillRemaining(  // ✅ Sliver
      child: Center(child: Text('Error: $error')),
    ),
    data: (items) {
      final List<Widget> children = [...];  // Build your content
      return SliverList(  // ✅ Sliver
        delegate: SliverChildListDelegate(children),
      );
    },
  );
}
```

---

### Issue 2: Height Jumping/Jank During Page Transitions

**Symptom:** Modal height jumps dramatically when transitioning between pages, especially from a `SliverWoltModalSheetPage` to a `WoltModalSheetPage`.

**Cause:** Using `FutureBuilder` for async data instead of Riverpod's `AsyncValue.when()` pattern.

**Why it happens:** `FutureBuilder` creates an async rebuild cycle AFTER the initial layout. Wolt calculates height based on the loading state, then the future completes and triggers a rebuild with different content height.

**Wrong:**
```dart
data: (lists) {
  return FutureBuilder<List<Item>>(  // ❌ FutureBuilder causes async timing issues
    future: _itemsFuture,
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const SliverFillRemaining(...);
      }
      // ... rest of builder
    },
  );
},
```

**Correct:**
```dart
// 1. Create a Riverpod FutureProvider
final myItemsProvider = FutureProvider.family<List<Item>, String>((ref, param) async {
  // ... fetch data
});

// 2. Use nested AsyncValue.when() in build()
@override
Widget build(BuildContext context) {
  final listsAsync = ref.watch(shoppingListsProvider);
  final itemsAsync = ref.watch(myItemsProvider(param));  // ✅ Riverpod provider

  return listsAsync.when(
    loading: () => const SliverFillRemaining(...),
    error: (e, s) => SliverFillRemaining(...),
    data: (lists) {
      return itemsAsync.when(  // ✅ Nested AsyncValue.when()
        loading: () => const SliverFillRemaining(...),
        error: (e, s) => SliverFillRemaining(...),
        data: (items) {
          // Build actual content
          return SliverList(...);
        },
      );
    },
  );
}
```

---

### Issue 3: Height Jump When Navigating Back to Previous Page

**Symptom:** No jank going forward (Page 0 → Page 1), but height jumps when navigating back (Page 1 → Page 0).

**Cause:** Using `autoDispose` on the FutureProvider. When navigating away from Page 0, the widget stops watching the provider, triggering disposal. When returning, the provider re-fetches, showing a loading state briefly.

**Wrong:**
```dart
final myProvider = FutureProvider.autoDispose.family<...>(  // ❌ autoDispose
  (ref, param) async { ... },
);
```

**Correct:**
```dart
// Don't use autoDispose so data persists during page navigation
final myProvider = FutureProvider.family<...>(  // ✅ No autoDispose
  (ref, param) async { ... },
);
```

---

## Complete Pattern Checklist

When implementing a multi-page Wolt modal sheet:

1. **Page structure:**
   - Use `SliverWoltModalSheetPage` for pages with scrollable content
   - Use `WoltModalSheetPage` for simple pages without complex scrolling
   - Set `hasTopBarLayer: false` on all pages

2. **Content in `mainContentSliversBuilder`:**
   - Wrap content widget in `Consumer` for Riverpod access
   - Content widget must return Sliver widgets directly (not wrapped in `SliverToBoxAdapter`)
   - Use `SliverFillRemaining` for loading/error states
   - Use `SliverList` for list content

3. **Async data handling:**
   - Use Riverpod `FutureProvider` (NOT `FutureBuilder`)
   - Use nested `AsyncValue.when()` for multiple async dependencies
   - Do NOT use `autoDispose` if data needs to persist across page navigation

4. **Sticky action bar:**
   - Wrap in `Consumer` for Riverpod access
   - Use `Container` with background color matching modal
   - Include `SafeArea(top: false, ...)` for bottom safe area

## Reference Implementation

See `lib/src/features/meal_plans/views/add_to_shopping_list_modal.dart` for a working example of a multi-page Wolt modal sheet with proper Sliver handling and async data patterns.
