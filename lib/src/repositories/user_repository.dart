import 'base_repository.dart';
import 'package:brick_core/query.dart';
import '../models/user.model.dart';

class UserRepository {
  final BaseRepository _baseRepository;

  UserRepository(this._baseRepository);

  Future<User> getUser(String userId) async {
    final users = await _baseRepository.get<User>(query: Query(where: [const Where('id').isExactly(userId)]));
    return users.first;
  }
}
