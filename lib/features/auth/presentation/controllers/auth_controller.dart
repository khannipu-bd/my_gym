//auth controller
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../data/datasources/auth_remote_source.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';

part 'auth_controller.g.dart';

@riverpod
AuthRepository authRepository(AuthRepositoryRef ref) {
  return AuthRepositoryImpl(AuthRemoteSource());
}

@riverpod
class AuthController extends _$AuthController {
  @override
  FutureOr<UserEntity?> build() async {
    return ref.read(authRepositoryProvider).getCurrentUser();
  }

  // 🎯 মেইন ট্রিক: এই ফাংশনটি এখন সরাসরি String রিটার্ন করবে (এরর হলে মেসেজ, সাকসেস হলে null)
  // এটি করার ফলে রিভারপডের গ্লোবাল স্টেট কখনো 'Error' স্টেটে যাবে না, ফলে স্ক্রিন সাদা হওয়ার সুযোগই নেই!
  Future<String?> login(String email, String password) async {
    state = const AsyncValue.loading();

    try {
      final user = await ref
          .read(authRepositoryProvider)
          .loginWithEmailAndPassword(email, password);

      state = AsyncValue.data(user);
      return null; // কোনো এরর নেই, সাকসেস
    } catch (error) {
      // 🔒 এরর হলেও মেইন স্টেটকে সেফ রাখা হলো যাতে লগইন পেজ গায়েব না হয়
      state = const AsyncValue.data(null);

      // এরর মেসেজটি সরাসরি স্ট্রিং আকারে UI-তে রিটার্ন করে দেওয়া হলো
      return error.toString();
    }
  }

  Future<void> logout() async {
    state = const AsyncValue.loading();
    try {
      await ref.read(authRepositoryProvider).signOut();
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}
