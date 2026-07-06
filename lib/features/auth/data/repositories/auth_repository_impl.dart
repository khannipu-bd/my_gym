import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteSource _remoteSource;

  AuthRepositoryImpl(this._remoteSource);

  @override
  Future<UserEntity?> loginWithEmailAndPassword(
    String email,
    String password,
  ) async {
    final credential = await _remoteSource.signIn(email, password);
    if (credential.user != null) {
      return await _getUserEntity(
        credential.user!.uid,
        credential.user!.email ?? email,
      );
    }
    return null;
  }

  @override
  Future<UserEntity?> getCurrentUser() async {
    final user = _remoteSource.currentFirebaseUser;
    if (user != null) {
      return await _getUserEntity(user.uid, user.email ?? '');
    }
    return null;
  }

  @override
  Future<void> signOut() async {
    await _remoteSource.logOut();
  }

  // হেল্পার মেথড: Firestore থেকে ডেটা এনে Entity-তে কনভার্ট করা (নিরাপদ উপায়ে)
  Future<UserEntity> _getUserEntity(String uid, String fallbackEmail) async {
    try {
      final doc = await _remoteSource.getUserDoc(uid);

      // যদি ফায়ারবেস ডেটাবেসে কোনো ডেটা না থাকে (doc.exists == false বা data == null)
      if (!doc.exists || doc.data() == null) {
        return UserEntity(
          uid: uid,
          email: fallbackEmail,
          name: 'New User',
          role: 'admin', // যেহেতু আপনি প্রথম ইউজার এবং অ্যাডমিন হতে চান
        );
      }

      final data = doc.data() as Map<String, dynamic>;
      return UserEntity(
        uid: uid,
        email: data['email'] ?? fallbackEmail,
        name: data['name'] ?? 'No Name',
        role: data['role'] ?? 'user', // ডেটাবেসে রোল না থাকলে ডিফল্ট 'user'
      );
    } catch (e) {
      // যেকোনো এরর হ্যান্ডেল করার জন্য যাতে অ্যাপ ব্ল্যাক স্ক্রিন না হয়
      return UserEntity(
        uid: uid,
        email: fallbackEmail,
        name: 'Error User',
        role: 'user',
      );
    }
  }
}
