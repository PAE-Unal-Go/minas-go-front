import '../repositories/map_repository.dart';

class GetUserTotalPoints {
  final MapRepository repository;
  const GetUserTotalPoints(this.repository);

  Future<int> call(String userId) {
    return repository.getUserTotalPoints(userId);
  }
}
