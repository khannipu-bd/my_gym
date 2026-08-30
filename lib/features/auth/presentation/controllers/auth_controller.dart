import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
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
    final repoUser = await ref.read(authRepositoryProvider).getCurrentUser();

    if (repoUser != null) {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(repoUser.uid)
          .get();

      if (!userDoc.exists) {
        await fb_auth.FirebaseAuth.instance.signOut();
        return null;
      }

      final userData = userDoc.data() as Map<String, dynamic>;

      // 🔒 ১. অ্যাপ ওপেন হওয়ার সময় ব্লক স্ট্যাটাস চেক
      final bool isBlocked = userData['isBlocked'] ?? false;
      if (isBlocked) {
        await fb_auth.FirebaseAuth.instance.signOut();
        return null;
      }

      // ⏰ ২. অ্যাপ ওপেন হওয়ার সময় প্ল্যান এক্সপায়ারি চেক (এডমিন বাদে সাধারণ ইউজারদের জন্য)
      final String role = userData['role'] ?? 'user';
      if (role != 'admin' && userData['expiryDate'] != null) {
        final Timestamp expiryTimestamp = userData['expiryDate'];
        final DateTime expiryDate = expiryTimestamp.toDate();
        final DateTime today = DateTime.now();

        final difference = DateTime(
          expiryDate.year,
          expiryDate.month,
          expiryDate.day,
        ).difference(DateTime(today.year, today.month, today.day)).inDays;

        final bool isSubscribed = userData['isSubscribed'] ?? false;

        if (difference < 0 || !isSubscribed) {
          await fb_auth.FirebaseAuth.instance.signOut();
          return null; // প্ল্যান শেষ হলে অটোমেটিক লগআউট ও লক স্টেট
        }
      }
    }
    return repoUser;
  }

  // 🎯 সুরক্ষিত লগইন মেথড (ব্লক এবং প্ল্যান এক্সপায়ারি ভ্যালিডেশন সহ)
  Future<String?> login(String email, String password) async {
    try {
      // ১. ফায়ারবেস অথেন্টিকেশন ভেরিফিকেশন
      final user = await ref
          .read(authRepositoryProvider)
          .loginWithEmailAndPassword(email, password);

      if (user != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (!userDoc.exists) {
          await fb_auth.FirebaseAuth.instance.signOut();
          state = const AsyncValue.data(null);
          return 'user-not-found';
        }

        final userData = userDoc.data() as Map<String, dynamic>;

        // 🚨 ২. অ্যাকাউন্ট এডমিন ব্লক করেছে কি না চেক
        final bool isBlocked = userData['isBlocked'] ?? false;
        if (isBlocked) {
          await fb_auth.FirebaseAuth.instance.signOut();
          state = const AsyncValue.data(null);
          return 'account-blocked'; // 👈 কাস্টম এরর কোড (LoginView-তে ক্যাচ করার জন্য)
        }

        // 🚨 ৩. মেম্বারশিপ প্ল্যান এক্সপায়ার হয়েছে কি না চেক (এডমিন বাদে সাধারণ মেম্বারদের জন্য)
        final String role = userData['role'] ?? 'user';
        if (role != 'admin' && userData['expiryDate'] != null) {
          final Timestamp expiryTimestamp = userData['expiryDate'];
          final DateTime expiryDate = expiryTimestamp.toDate();
          final DateTime today = DateTime.now();

          // দিন হিসাব (শুধু ডেট টু ডেট তুলনা করার জন্য)
          final difference = DateTime(
            expiryDate.year,
            expiryDate.month,
            expiryDate.day,
          ).difference(DateTime(today.year, today.month, today.day)).inDays;

          final bool isSubscribed = userData['isSubscribed'] ?? false;

          if (difference < 0 || !isSubscribed) {
            await fb_auth.FirebaseAuth.instance.signOut();
            state = const AsyncValue.data(null);
            return 'plan-expired'; // 👈 কাস্টম এরর কোড (LoginView-তে ক্যাচ করার জন্য)
          }
        }
      }

      // সবকিছু পাস হলে মেইন ডাটা স্টেট আপডেট হবে
      state = AsyncValue.data(user);
      return null;
    } catch (error) {
      // 🔒 মেইন ডাটা স্টেট আগের অবস্থায় অপরিবর্তিত রাখা হলো
      final errString = error.toString().toLowerCase();

      if (errString.contains('invalid-credential') ||
          errString.contains('wrong-password') ||
          errString.contains('user-not-found') ||
          errString.contains('invalid-email-or-password')) {
        return 'wrong-password';
      } else if (errString.contains('network-request-failed') ||
          errString.contains('network_error')) {
        return 'network-request-failed';
      } else if (errString.contains('invalid-email')) {
        return 'invalid-email';
      }

      return error.toString();
    }
  }

  // 📝 নতুন মেম্বার রেজিস্টার করার মেথড (Gym ID ও Joining Date সহ)
  Future<String?> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      // লিমিট চেক করা
      final bool isLimitReached = await isUserLimitReached();
      if (isLimitReached) {
        return 'limit-reached';
      }

      // ফায়ারবেস অথেন্টিকেশনে নতুন ইউজার তৈরি
      final userCredential = await fb_auth.FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      final uid = userCredential.user?.uid;
      if (uid != null) {
        // 🆔 ইউনিক Gym ID জেনারেট করা (যেমন: GYM-4821)
        final String generatedGymId =
            'GYM-${DateTime.now().millisecondsSinceEpoch.toString().substring(9)}';

        // Firestore-এ ইউজার ডাটা সেভ
        await FirebaseFirestore.instance.collection('users').doc(uid).set({
          'name': name,
          'email': email,
          'role': 'user',
          'isBlocked': false,
          'isSubscribed': false,
          'gymId': generatedGymId, // 👈 অটোমেটিক Gym ID
          'joiningDate': FieldValue.serverTimestamp(), // 👈 জয়েন করার তারিখ
        }, SetOptions(merge: true));

        await fb_auth.FirebaseAuth.instance.signOut();
        return null; // রেজিস্ট্রেশন সফল
      }
      return 'registration-failed';
    } catch (error) {
      return error.toString();
    }
  }

  // 🛑 ফায়ারস্টোরে মোট মেম্বার বা ইউজারের সংখ্যা চেক করার জন্য
  Future<bool> isUserLimitReached() async {
    try {
      // 'users' কালেকশনে যাদের রোল 'user' বা সাধারণ মেম্বার, শুধু তাদের গণনা করবে (এডমিন বাদ দিয়ে)
      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'user')
          .get();

      // যদি মেম্বার সংখ্যা ১০০ বা তার বেশি হয়, তবে true পাঠাবে
      return querySnapshot.docs.length >= 100;
    } catch (e) {
      return false; // কোনো এরর হলে সেফটি হিসেবে রেজিস্ট্রেশন ব্লক করবে না
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
