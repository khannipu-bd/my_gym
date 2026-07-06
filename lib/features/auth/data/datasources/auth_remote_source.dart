import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthRemoteSource {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<UserCredential> signIn(String email, String password) async {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<DocumentSnapshot> getUserDoc(String uid) async {
    return await _firestore.collection('users').doc(uid).get();
  }

  User? get currentFirebaseUser => _auth.currentUser;

  Future<void> logOut() async {
    await _auth.signOut();
  }
}
