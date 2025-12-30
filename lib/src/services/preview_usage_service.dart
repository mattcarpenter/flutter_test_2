import 'package:shared_preferences/shared_preferences.dart';

/// Tracks daily preview usage for NON-ENTITLED USERS ONLY.
///
/// This is a client-side optimization to skip the loading modal and go straight
/// to the paywall when a non-entitled user has used their daily preview quota.
///
/// IMPORTANT: This service is NEVER consulted for Plus users. The entitlement
/// check (effectiveHasPlusProvider) happens FIRST, and entitled users bypass
/// this tracking entirely - they always get full extraction.
///
/// The usage counter persists across app launches and resets at midnight.
/// Old entries are cleaned up after 7 days.
///
/// Note: Share previews, clipping previews, and photo previews have SEPARATE quotas.
/// Users get 5/day for text-based previews (share, clipping) and 2/day for photos.
class PreviewUsageService {
  static const _recipeKeyPrefix = 'recipe_preview_usage_';
  static const _shoppingListKeyPrefix = 'shopping_list_preview_usage_';
  static const _shareRecipeKeyPrefix = 'share_recipe_preview_usage_';
  static const _photoRecipeKeyPrefix = 'photo_recipe_preview_usage_';
  static const _ideaGenerationKeyPrefix = 'idea_generation_usage_';
  static const int dailyLimit = 5;
  static const int photoDailyLimit = 2; // Stricter limit for photos (more expensive)
  static const int ideaDailyLimit = 10; // Generous limit for AI recipe ideas

  final SharedPreferences _prefs;

  PreviewUsageService(this._prefs);

  /// Returns the current date as YYYY-MM-DD string.
  String _today() => DateTime.now().toIso8601String().substring(0, 10);

  // ============================================================================
  // Recipe Preview Usage
  // ============================================================================

  /// Gets the number of recipe previews used today.
  int getRecipeUsageToday() {
    final key = '$_recipeKeyPrefix${_today()}';
    return _prefs.getInt(key) ?? 0;
  }

  /// Returns true if user has remaining recipe previews today.
  bool hasRecipePreviewsRemaining() {
    return getRecipeUsageToday() < dailyLimit;
  }

  /// Increments the recipe usage count for today.
  Future<void> incrementRecipeUsage() async {
    final key = '$_recipeKeyPrefix${_today()}';
    final current = _prefs.getInt(key) ?? 0;
    await _prefs.setInt(key, current + 1);

    // Clean up old entries (keep only last 7 days)
    await _cleanupOldEntries(_recipeKeyPrefix);
  }

  // ============================================================================
  // Shopping List Preview Usage
  // ============================================================================

  /// Gets the number of shopping list previews used today.
  int getShoppingListUsageToday() {
    final key = '$_shoppingListKeyPrefix${_today()}';
    return _prefs.getInt(key) ?? 0;
  }

  /// Returns true if user has remaining shopping list previews today.
  bool hasShoppingListPreviewsRemaining() {
    return getShoppingListUsageToday() < dailyLimit;
  }

  /// Increments the shopping list usage count for today.
  Future<void> incrementShoppingListUsage() async {
    final key = '$_shoppingListKeyPrefix${_today()}';
    final current = _prefs.getInt(key) ?? 0;
    await _prefs.setInt(key, current + 1);

    // Clean up old entries (keep only last 7 days)
    await _cleanupOldEntries(_shoppingListKeyPrefix);
  }

  // ============================================================================
  // Share Recipe Preview Usage (separate quota from clipping previews)
  // ============================================================================

  /// Gets the number of share recipe previews used today.
  int getShareRecipeUsageToday() {
    final key = '$_shareRecipeKeyPrefix${_today()}';
    return _prefs.getInt(key) ?? 0;
  }

  /// Returns true if user has remaining share recipe previews today.
  bool hasShareRecipePreviewsRemaining() {
    return getShareRecipeUsageToday() < dailyLimit;
  }

  /// Increments the share recipe usage count for today.
  Future<void> incrementShareRecipeUsage() async {
    final key = '$_shareRecipeKeyPrefix${_today()}';
    final current = _prefs.getInt(key) ?? 0;
    await _prefs.setInt(key, current + 1);

    // Clean up old entries (keep only last 7 days)
    await _cleanupOldEntries(_shareRecipeKeyPrefix);
  }

  // ============================================================================
  // Photo Recipe Preview Usage (stricter quota - 2/day vs 5/day for text)
  // ============================================================================

  /// Gets the number of photo recipe previews used today.
  int getPhotoRecipeUsageToday() {
    final key = '$_photoRecipeKeyPrefix${_today()}';
    return _prefs.getInt(key) ?? 0;
  }

  /// Returns true if user has remaining photo recipe previews today.
  bool hasPhotoRecipePreviewsRemaining() {
    return getPhotoRecipeUsageToday() < photoDailyLimit;
  }

  /// Increments the photo recipe usage count for today.
  Future<void> incrementPhotoRecipeUsage() async {
    final key = '$_photoRecipeKeyPrefix${_today()}';
    final current = _prefs.getInt(key) ?? 0;
    await _prefs.setInt(key, current + 1);

    // Clean up old entries (keep only last 7 days)
    await _cleanupOldEntries(_photoRecipeKeyPrefix);
  }

  // ============================================================================
  // AI Recipe Idea Generation Usage (10/day for free users)
  // ============================================================================

  /// Gets the number of AI recipe ideas generated today.
  int getIdeaUsageToday() {
    final key = '$_ideaGenerationKeyPrefix${_today()}';
    return _prefs.getInt(key) ?? 0;
  }

  /// Returns true if user has remaining idea generations today.
  bool hasIdeaGenerationsRemaining() {
    return getIdeaUsageToday() < ideaDailyLimit;
  }

  /// Returns the number of remaining idea generations today.
  int getRemainingIdeaGenerations() {
    return ideaDailyLimit - getIdeaUsageToday();
  }

  /// Increments the idea generation usage count for today.
  Future<void> incrementIdeaUsage() async {
    final key = '$_ideaGenerationKeyPrefix${_today()}';
    final current = _prefs.getInt(key) ?? 0;
    await _prefs.setInt(key, current + 1);

    // Clean up old entries (keep only last 7 days)
    await _cleanupOldEntries(_ideaGenerationKeyPrefix);
  }

  // ============================================================================
  // Cleanup
  // ============================================================================

  /// Removes entries older than 7 days for a given prefix.
  Future<void> _cleanupOldEntries(String prefix) async {
    final keys = _prefs.getKeys().where((k) => k.startsWith(prefix)).toList();

    final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));

    for (final key in keys) {
      final dateStr = key.replaceFirst(prefix, '');
      try {
        final date = DateTime.parse(dateStr);
        if (date.isBefore(sevenDaysAgo)) {
          await _prefs.remove(key);
        }
      } catch (_) {
        // Invalid date format, remove the key
        await _prefs.remove(key);
      }
    }
  }
}
