import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../services/preview_usage_service.dart';

/// Provider for the PreviewUsageService.
///
/// This service is ONLY used for non-entitled users to track their
/// daily preview quota. Plus users bypass this tracking entirely.
final previewUsageServiceProvider =
    FutureProvider<PreviewUsageService>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return PreviewUsageService(prefs);
});

/// Whether the user has remaining recipe previews today.
///
/// Only checked for non-entitled users.
final hasRecipePreviewsRemainingProvider = FutureProvider<bool>((ref) async {
  final service = await ref.watch(previewUsageServiceProvider.future);
  return service.hasRecipePreviewsRemaining();
});

/// Whether the user has remaining shopping list previews today.
///
/// Only checked for non-entitled users.
final hasShoppingListPreviewsRemainingProvider =
    FutureProvider<bool>((ref) async {
  final service = await ref.watch(previewUsageServiceProvider.future);
  return service.hasShoppingListPreviewsRemaining();
});
