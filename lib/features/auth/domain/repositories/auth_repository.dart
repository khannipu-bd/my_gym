import '../entities/user_entity.dart';

abstract class AuthRepository {
  Future<UserEntity?> loginWithEmailAndPassword(String email, String password);
  Future<UserEntity?> getCurrentUser();
  Future<void> signOut();
}
