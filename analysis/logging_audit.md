# Logging Audit Report

**Generated:** 2025-11-27
**Scope:** Inventory of all logging statements in the codebase with recommendations for migration to AppLogger

---

## Executive Summary

| Category | Count | Action |
|----------|-------|--------|
| `print()` statements | 24 | Migrate or remove |
| `debugPrint()` statements | 99 | Migrate or remove |
| `Logger` package (PowerSync) | 24 | Keep (separate concern) |
| `AppLogger` usage | 16 | Already migrated |
| **Total statements** | **163** | |

### Key Findings

1. **Auth Service is extremely chatty** - 37 debug statements with emoji markers, token dumps, and step-by-step flow tracing leftover from OAuth troubleshooting
2. **Subscription Service is verbose** - 43 statements tracking every RevenueCat interaction
3. **Household management logs full HTTP request/response bodies** - potential data exposure
4. **Queue managers have extensive DEBUG blocks** - useful during development but noisy in production
5. **Test files have 24 leftover debug prints** - should be cleaned up

---

## Detailed Inventory

### 1. Authentication Service
**File:** `lib/src/services/auth_service.dart`
**Statement Count:** 37
**Severity:** HIGH - needs significant cleanup

#### Current State
The auth service has extensive debugging from OAuth implementation troubleshooting:

```dart
// Examples of chatty/debug leftovers:
debugPrint('🔥 GOOGLE SIGN-IN CALLED #$_signInCallCount');  // Line 170
debugPrint('🚀 Attempting lightweight authentication...');   // Line 177
debugPrint('🚀 About to call authenticate()...');           // Line 181
debugPrint('✅ authenticate() completed, user: ${googleUser.displayName}');  // Line 184

// TOKEN DEBUG BLOCK - SECURITY CONCERN
debugPrint('=== TOKEN DEBUG INFO ===');                      // Line 238
debugPrint('Access Token (first 50 chars): ${accessToken.substring(0, 50)}...'); // Line 239
debugPrint('ID Token (first 50 chars): ${idToken.substring(0, 50)}...');         // Line 240
debugPrint('ID Token Payload: $decoded');                    // Line 253
debugPrint('=== END TOKEN DEBUG ===');                       // Line 258
```

#### Recommendations

| Line(s) | Current | Recommendation |
|---------|---------|----------------|
| 84 | `debugPrint('🔧 GoogleSignIn initialized...')` | **Remove** - initialization success is implicit |
| 170 | `debugPrint('🔥 GOOGLE SIGN-IN CALLED #$_signInCallCount')` | **Remove** - call counting is debug-only |
| 174, 177, 181, 184, 186 | Step-by-step flow markers | **Remove** - too granular for production |
| 192, 203, 206, 209, 212, 219-220 | Token availability checks | **Remove** - internal state, not actionable |
| 238-258 | Token debug block | **REMOVE IMMEDIATELY** - exposes sensitive token data |
| 130, 133, 158, 161, 267, 270, 355, 358, 381, 384, 395, 398, 419, 422 | Error handlers | **Migrate to AppLogger.error()** |
| 235 | `'Got tokens, attempting Supabase authentication'` | **Migrate to AppLogger.debug()** - useful for troubleshooting |
| 282, 297, 316, 332 | Apple Sign-In flow milestones | **Migrate to AppLogger.info()** - keep 1-2 key milestones |

**Suggested final state:** ~5-6 AppLogger calls (sign-in started, sign-in succeeded/failed, sign-out)

---

### 2. Subscription Service
**File:** `lib/src/services/subscription_service.dart`
**Statement Count:** 43
**Severity:** MEDIUM - reduce verbosity

#### Current State
Every RevenueCat interaction is logged in detail:

```dart
debugPrint('SubscriptionService.hasPlus: Starting check for user: ${user?.id}');
debugPrint('SubscriptionService.hasPlus: No current user, returning false');
debugPrint('SubscriptionService.hasPlus: Checking cached subscriptions...');
debugPrint('SubscriptionService.hasPlus: Database check - found ${_cachedSubscriptions.length}...');
debugPrint('SubscriptionService.hasPlus: Database check passed, returning true');
// ... continues for every code path
```

#### Recommendations

| Category | Lines | Recommendation |
|----------|-------|----------------|
| Initialization | 130, 139, 145, 147 | **Keep 2**: init started, init complete/failed |
| hasPlus() checks | 165-225 (12 statements) | **Remove all** - too granular, not actionable |
| Paywall operations | 299, 302, 312, 324 | **Keep**: result is useful for analytics |
| Restore purchases | 355, 359, 371, 383 | **Keep 2**: started, result |
| User sync | 395-416 | **Remove** - internal operation |
| Cache refresh | 427-440, 501-520 | **Remove** - internal operation |

**Suggested final state:** ~8-10 AppLogger calls focusing on user-visible operations

---

### 3. Subscription Provider
**File:** `lib/src/providers/subscription_provider.dart`
**Statement Count:** 12
**Severity:** LOW - straightforward migration

#### Recommendations

| Line | Current | Recommendation |
|------|---------|----------------|
| 32 | Auth state changed | **Remove** - already logged elsewhere |
| 66 | State update with details | **Migrate to AppLogger.debug()** |
| 68, 72, 89, 114, 151, 172 | Error handlers | **Migrate to AppLogger.error()** |
| 181 | Disposing | **Remove** - not useful |
| 196, 200, 266 | Stream/provider debug | **Remove** - too granular |

---

### 4. Household Management
**Files:** `lib/src/providers/household_provider.dart`, `lib/src/services/household_management_service.dart`
**Statement Count:** 31 combined
**Severity:** HIGH - logs sensitive data

#### Security Concerns

```dart
// These log full request/response bodies including auth tokens:
print('HOUSEHOLD API: Auth token: ${authToken.substring(0, 20)}...');  // Line 128
print('HOUSEHOLD API: Request body: ${json.encode(requestBody)}');     // Line 135
print('HOUSEHOLD API: Response body: ${response.body}');               // Line 148
```

#### Recommendations

| File | Lines | Recommendation |
|------|-------|----------------|
| household_provider.dart | 51-82 | **Remove** "HOUSEHOLD DEBUG" block - development only |
| household_provider.dart | 145 | **Migrate to AppLogger.warning()** |
| household_provider.dart | 209, 214, 217 | **Keep 2 as AppLogger.info/error** |
| household_provider.dart | 261-282 | **Keep 2 as AppLogger.info/error** |
| household_management_service.dart | 124-159 | **Remove all** - logs auth tokens and full payloads |
| household_management_service.dart | 191-202 | **Remove all** - logs full response bodies |

---

### 5. Queue Managers
**Files:** Multiple `*_queue_manager.dart` files
**Statement Count:** ~40 combined
**Severity:** MEDIUM - verbose but useful structure

#### Files Affected
- `lib/src/managers/ingredient_term_queue_manager.dart` (18 statements)
- `lib/src/managers/pantry_item_term_queue_manager.dart` (10 statements)
- `lib/src/managers/shopping_list_item_term_queue_manager.dart` (7 statements)
- `lib/src/managers/upload_queue_manager.dart` (11 statements)

#### Current Pattern
```dart
debugPrint('Processing ingredient term queue...');
debugPrint('DEBUG: Current ingredients before processing:');
debugPrint('  - ${ing.name} (ID: ${ing.id})');
debugPrint('DEBUG: Processing entry for ingredient ID: $ingredientId');
// ... extensive state dumps
```

#### Recommendations

| Category | Recommendation |
|----------|----------------|
| Connectivity status | **Keep as AppLogger.info()** - useful for debugging sync issues |
| "Processing X queue..." | **Keep as AppLogger.debug()** |
| "DEBUG:" prefixed blocks | **Remove entirely** - development only |
| Individual item logging | **Remove** - too granular |
| Error handlers | **Migrate to AppLogger.error()** |
| Scheduling messages | **Remove** - internal timing |

**Suggested pattern per queue manager:** 3-4 AppLogger calls (queue processing started, completed, errors)

---

### 6. PowerSync / Database
**File:** `lib/database/powersync.dart`
**Statement Count:** 25 (24 Logger + 1 print)
**Severity:** LOW - keep as-is

#### Assessment
The PowerSync connector uses the Dart `logging` package appropriately for its domain:
- Token refresh lifecycle
- Auth state changes
- Data sync errors
- Upload queue management

**Recommendation:** Leave the `Logger` package usage in powersync.dart unchanged. This is a separate concern from application logging and integrates with PowerSync's logging conventions.

**One change:** Line 268 uses `print()` - migrate to the existing `log` instance:
```dart
// Current:
print('Opening database at $databasePath');
// Change to:
log.info('Opening database at $databasePath');
```

---

### 7. Recipe & UI Components
**Statement Count:** ~25 scattered across files
**Severity:** LOW-MEDIUM

#### Files Affected
| File | Count | Category |
|------|-------|----------|
| `recipe_provider.dart` | 4 | Ingredient matching debug |
| `recipe_filter_sort.dart` | 2 | Filter operation tracing |
| `recipes_folder_page.dart` | 5 | Filter state changes |
| `recipe_ingredients_view.dart` | 6 | Match bottom sheet debug |
| `recipe_view.dart` | 2 | Provider refresh debug |
| `recipe_editor_form.dart` | 1 | Save error |
| `image_picker_section.dart` | 3 | Image cleanup errors |
| `ingredient_matches_bottom_sheet.dart` | 2 | Term addition errors |

#### Recommendations

| Category | Files | Recommendation |
|----------|-------|----------------|
| Recipe import error | recipe_provider.dart:394 | **Migrate to AppLogger.error()** |
| Ingredient match debugging | recipe_provider.dart:633-639 | **Remove** - development debug |
| Filter operation tracing | recipe_filter_sort.dart, recipes_folder_page.dart | **Remove all** - UI state debug |
| Bottom sheet debugging | recipe_ingredients_view.dart | **Remove all** - development debug |
| Provider refresh | recipe_view.dart | **Remove all** - initialization debug |
| Save/edit errors | recipe_editor_form.dart, image_picker_section.dart, ingredient_matches_bottom_sheet.dart | **Migrate to AppLogger.error()** |

---

### 8. Other Application Files

| File | Line | Current | Recommendation |
|------|------|---------|----------------|
| `app_config.dart` | 21, 35 | Init start/complete | **Migrate to AppLogger.debug()** |
| `app_config.dart` | 31 | Error loading env | **Migrate to AppLogger.error()** |
| `app_config.dart` | 67 | Warning not initialized | **Migrate to AppLogger.warning()** |
| `auth_provider.dart` | 35 | Auth state changed | **Remove** - logged elsewhere |
| `settings_storage_service.dart` | 39, 60, 73 | Settings errors | **Migrate to AppLogger.error()** |
| `feature_flags.dart` | 137-153 | Feature gate debug | **Remove** - development only |
| `menu.dart` | 96, 110 | Labs access debug | **Remove** - development only |

---

### 9. Drag-and-Drop Debug (Meal Plans)
**Files:** `debug_drag_target.dart`, `meal_plan_item_with_handle.dart`
**Statement Count:** 11
**Severity:** LOW

These are clearly development debugging widgets:
```dart
print('=== DRAG STARTED ===');
print('Item: ${item.id}');
print('Source date: $dateString');
print('=== DRAG ENDED ===');
```

**Recommendation:** **Remove all** - these appear to be debug widgets that should not be in production code.

---

### 10. Test Files
**Directory:** `test/`
**Statement Count:** 39 (15 intentional, 24 leftover)

#### Intentional (Keep)
- Test utility setup/teardown logging in `supabase_admin.dart`
- Test milestone logging in `seed_recipes.test.dart`
- Login/logout flow logging in `test_utils.dart`

#### Leftover Debug (Remove)
| File | Count | Description |
|------|-------|-------------|
| `sub_recipe_pantry_match_test.dart` | 20 | Data inspection, timing, match details |
| `term_materialization_test.dart` | 3 | Term verification dumps |
| `test_utils.dart` | 3 | Provider state tracing |

---

## Migration Priority

### Phase 1: Security & Sensitive Data (Do First)
1. **Remove token debug block** in auth_service.dart (lines 238-258)
2. **Remove HTTP payload logging** in household_management_service.dart
3. **Remove auth token partial logging** (line 128)

### Phase 2: High-Volume Chatty Logs
1. Auth service emoji/flow markers (30+ statements)
2. Subscription service granular checks (25+ statements)
3. Queue manager DEBUG blocks (15+ statements)

### Phase 3: General Cleanup
1. Recipe/UI component debug statements
2. Provider debug statements
3. Test file debug leftovers

### Phase 4: Proper Instrumentation
1. Migrate error handlers to `AppLogger.error()`
2. Migrate key milestones to `AppLogger.info()`
3. Keep minimal `AppLogger.debug()` for troubleshooting

---

## Suggested Logging Patterns

### For Services
```dart
class SomeService {
  Future<void> performAction() async {
    AppLogger.info('Starting action');  // Entry point
    try {
      // ... do work
      AppLogger.info('Action completed successfully');  // Success
    } catch (e, stack) {
      AppLogger.error('Action failed', e, stack);  // Failure with context
      rethrow;
    }
  }
}
```

### For Providers
```dart
// Only log state changes that are meaningful to users/debugging
AppLogger.debug('User subscription status changed: $hasPlus');

// Always log errors
AppLogger.error('Failed to refresh subscription', e, stack);
```

### For Queue Managers
```dart
AppLogger.info('Processing upload queue: ${entries.length} items');
// ... process
AppLogger.info('Upload queue complete: ${successful}/${total} succeeded');
```

---

## Files Requiring Changes

| File | Remove | Migrate | Keep |
|------|--------|---------|------|
| `auth_service.dart` | 32 | 5 | 0 |
| `subscription_service.dart` | 35 | 8 | 0 |
| `subscription_provider.dart` | 7 | 5 | 0 |
| `household_provider.dart` | 15 | 3 | 0 |
| `household_management_service.dart` | 13 | 0 | 0 |
| `ingredient_term_queue_manager.dart` | 14 | 4 | 0 |
| `pantry_item_term_queue_manager.dart` | 7 | 3 | 0 |
| `shopping_list_item_term_queue_manager.dart` | 5 | 2 | 0 |
| `upload_queue_manager.dart` | 8 | 3 | 0 |
| `powersync.dart` | 0 | 1 | 24 |
| `recipe_provider.dart` | 3 | 1 | 0 |
| UI/widget files | 18 | 6 | 0 |
| `app_config.dart` | 0 | 4 | 0 |
| Other services | 3 | 3 | 0 |
| Test files | 24 | 0 | 15 |

**Totals:** Remove ~184, Migrate ~48, Keep ~39
