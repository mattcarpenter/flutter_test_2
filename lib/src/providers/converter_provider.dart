import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../database/database.dart';
import '../../database/powersync.dart';
import '../repositories/converter_repository.dart';

/// Manages the list of unit converters.
class ConverterNotifier
    extends StateNotifier<AsyncValue<List<ConverterEntry>>> {
  final ConverterRepository _repo;
  late final StreamSubscription<List<ConverterEntry>> _sub;

  ConverterNotifier(this._repo) : super(const AsyncValue.loading()) {
    _sub = _repo.watchConverters().listen(
          (items) => state = AsyncValue.data(items),
      onError: (e, st) => state = AsyncValue.error(e, st),
    );
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }

  Future<String> addConverter({
    required String term,
    required String fromUnit,
    required String toBaseUnit,
    required double conversionFactor,
    bool isApproximate = false,
    String? notes,
    required String userId,
    String? householdId,
  }) =>
      _repo.addConverter(
        term: term,
        fromUnit: fromUnit,
        toBaseUnit: toBaseUnit,
        conversionFactor: conversionFactor,
        isApproximate: isApproximate,
        notes: notes,
        userId: userId,
        householdId: householdId,
      );

  Future<void> updateConverter({
    required String id,
    String? term,
    String? fromUnit,
    String? toBaseUnit,
    double? conversionFactor,
    bool? isApproximate,
    String? notes,
  }) =>
      _repo.updateConverter(
        id: id,
        term: term,
        fromUnit: fromUnit,
        toBaseUnit: toBaseUnit,
        conversionFactor: conversionFactor,
        isApproximate: isApproximate,
        notes: notes,
      );

  Future<void> deleteConverter(String id) =>
      _repo.deleteConverter(id);

  Future<ConverterEntry?> findBestConverter({
    required String term,
    required String unit,
  }) =>
      _repo.findBestConverter(term: term, unit: unit);
}

/// Expose the [ConverterRepository].
final converterRepositoryProvider =
Provider<ConverterRepository>((ref) => ConverterRepository(appDb));

/// Expose the global converters list.
final convertersProvider =
StateNotifierProvider<ConverterNotifier, AsyncValue<List<ConverterEntry>>>(
      (ref) {
    final repo = ref.watch(converterRepositoryProvider);
    return ConverterNotifier(repo);
  },
);

/// Provider that watches converters for a specific term
final convertersForTermProvider = 
    StreamProvider.family<List<ConverterEntry>, String>((ref, term) {
  final repo = ref.watch(converterRepositoryProvider);
  return repo.watchConvertersForTerm(term);
});