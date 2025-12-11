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
    String? userId,
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
final clippingsProvider =
    StateNotifierProvider<ClippingsNotifier, AsyncValue<List<ClippingEntry>>>(
        (ref) {
  return ClippingsNotifier(ref.watch(clippingsRepositoryProvider));
});
