import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:shared_preferences/shared_preferences.dart';
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
    final repoUser = await ref.watch(authRepositoryProvider).getCurrentUser();

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

      // 🔒 ১. স্ট্যাটাস চেক (অ্যাডমিন এপ্রুভাল সিস্টেম)
      final String status = userData['status'] ?? 'approved';
      if (status == 'rejected') {
        await fb_auth.FirebaseAuth.instance.signOut();
        return null;
      }

      // 🔒 ২. অ্যাপ ওপেন হওয়ার সময় ব্লক স্ট্যাটাস চেক
      final bool isBlocked = userData['isBlocked'] == true;
      if (isBlocked) {
        await fb_auth.FirebaseAuth.instance.signOut();
        return null;
      }

      // ⏰ ৩. অ্যাপ ওপেন হওয়ার সময় প্ল্যান এক্সপায়ারি চেক (এডমিন বাদে সাধারণ ইউজারদের জন্য)
      final String role = userData['role'] ?? 'user';
      if (role != 'admin' && userData['expiryDate'] is Timestamp) {
        final Timestamp expiryTimestamp = userData['expiryDate'] as Timestamp;
        final DateTime expiryDate = expiryTimestamp.toDate();
        final DateTime today = DateTime.now();

        final difference = DateTime(
          expiryDate.year,
          expiryDate.month,
          expiryDate.day,
        ).difference(DateTime(today.year, today.month, today.day)).inDays;

        final bool isSubscribed = userData['isSubscribed'] == true;

        if (difference < 0 || !isSubscribed) {
          await fb_auth.FirebaseAuth.instance.signOut();
          return null; // প্ল্যান শেষ হলে অটোমেটিক লগআউট ও লক স্টেট
        }
      }
    }
    return repoUser;
  }

  // 🎯 সুরক্ষিত লগইন মেথড (স্ট্যাটাস, ব্লক এবং প্ল্যান এক্সপায়ারি ভ্যালিডেশন সহ)
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

        // 🚨 ২. অ্যাডমিন এপ্রুভাল স্ট্যাটাস চেক
        final String status = userData['status'] ?? 'approved';
        if (status == 'rejected') {
          await fb_auth.FirebaseAuth.instance.signOut();
          state = const AsyncValue.data(null);
          return 'account-rejected'; // 👈 কাস্টম এরর কোড (রিজেক্টেড মেম্বারশিপ)
        }

        // 🚨 ৩. অ্যাকাউন্ট এডমিন ব্লক করেছে কি না চেক
        final bool isBlocked = userData['isBlocked'] == true;
        if (isBlocked) {
          await fb_auth.FirebaseAuth.instance.signOut();
          state = const AsyncValue.data(null);
          return 'account-blocked';
        }

        // 🚨 ৪. মেম্বারশিপ প্ল্যান এক্সপায়ার হয়েছে কি না চেক (এডমিন বাদে সাধারণ মেম্বারদের জন্য)
        final String role = userData['role'] ?? 'user';
        if (role != 'admin' && userData['expiryDate'] is Timestamp) {
          final Timestamp expiryTimestamp = userData['expiryDate'] as Timestamp;
          final DateTime expiryDate = expiryTimestamp.toDate();
          final DateTime today = DateTime.now();

          final difference = DateTime(
            expiryDate.year,
            expiryDate.month,
            expiryDate.day,
          ).difference(DateTime(today.year, today.month, today.day)).inDays;

          final bool isSubscribed = userData['isSubscribed'] == true;

          if (difference < 0 || !isSubscribed) {
            await fb_auth.FirebaseAuth.instance.signOut();
            state = const AsyncValue.data(null);
            return 'plan-expired';
          }
        }
      }

      state = AsyncValue.data(user);
      return null;
    } catch (error) {
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

  // 📝 নতুন মেম্বার রেজিস্টার করার মেথড (Phone, Gym ID & Pending Status সহ)
  Future<String?> signUp({
    required String name,
    required String email,
    required String password,
    required String phone,
  }) async {
    try {
      final bool isLimitReached = await isUserLimitReached();
      if (isLimitReached) {
        return 'limit-reached';
      }

      final userCredential = await fb_auth.FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      final uid = userCredential.user?.uid;
      if (uid != null) {
        final String generatedGymId =
            'GYM-${DateTime.now().millisecondsSinceEpoch.toString().substring(9)}';

        await FirebaseFirestore.instance.collection('users').doc(uid).set({
          'uid': uid,
          'name': name,
          'email': email,
          'phone': phone,
          'role': 'user',
          'status': 'pending', // 👈 pending, approved, rejected
          'isBlocked': false,
          'isSubscribed': false,
          'gymId': generatedGymId,
          'joiningDate': FieldValue.serverTimestamp(),
          'createdAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        // রেজিস্টার করার সাথে সাথে সাইনআউট (অ্যাডমিন এপ্রুভালের জন্য অপেক্ষা)
        await fb_auth.FirebaseAuth.instance.signOut();
        return null; // রেজিস্ট্রেশন সফল ও পেন্ডিং এপ্রুভাল
      }
      return 'registration-failed';
    } catch (error) {
      return error.toString();
    }
  }

  Future<bool> isUserLimitReached() async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'user')
          .where('status', isEqualTo: 'approved')
          .get();

      return querySnapshot.docs.length >= 100;
    } catch (e) {
      return false;
    }
  }

  Future<void> logout() async {
    state = const AsyncValue.loading();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      await ref.read(authRepositoryProvider).signOut();
      await fb_auth.FirebaseAuth.instance.signOut();
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}
