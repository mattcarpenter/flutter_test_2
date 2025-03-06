import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../database/database.dart';
import '../../database/powersync.dart';
import '../repositories/household_repository.dart';

/// The HouseholdNotifier manages a list of HouseholdEntry objects.
class HouseholdNotifier extends StateNotifier<AsyncValue<List<HouseholdEntry>>> {
  final HouseholdRepository _repository;
  late final StreamSubscription<List<HouseholdEntry>> _subscription;

  HouseholdNotifier(this._repository) : super(const AsyncValue.loading()) {
    // Listen to the stream of households from Drift.
    _subscription = _repository.watchHouseholds().listen(
          (households) {
        state = AsyncValue.data(households);
      },
      onError: (error, stack) {
        state = AsyncValue.error(error, stack);
      },
    );
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  /// Adds a new household.
  Future<void> addHousehold({
    required String name,
    required String userId,
  }) async {
    try {
      final companion = HouseholdsCompanion.insert(
        name: name,
        userId: userId,
      );
      await _repository.addHousehold(companion);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Deletes a household by its id.
  Future<void> deleteHousehold(String id) async {
    try {
      await _repository.deleteHousehold(id);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

/// Provider to expose the HouseholdNotifier.
final householdNotifierProvider = StateNotifierProvider<HouseholdNotifier, AsyncValue<List<HouseholdEntry>>>(
      (ref) {
    final repository = ref.watch(householdRepositoryProvider);
    return HouseholdNotifier(repository);
  },
);

/// Provider for the HouseholdRepository.
/// Assumes you have an instance of your Drift database (appDb).
final householdRepositoryProvider = Provider<HouseholdRepository>(
      (ref) => HouseholdRepository(appDb),
);
