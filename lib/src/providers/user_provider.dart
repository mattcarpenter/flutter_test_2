// Provide the BaseRepository instance (singleton)
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:recipe_app/src/repositories/user_repository.dart';

import '../repositories/base_repository.dart';

final baseRepositoryProvider = Provider<BaseRepository>((ref) {
  return BaseRepository();
});

// Provide UserRepository using BaseRepository
final userRepositoryProvider = Provider<UserRepository>((ref) {
  final baseRepo = ref.watch(baseRepositoryProvider);
  return UserRepository(baseRepo);
});
