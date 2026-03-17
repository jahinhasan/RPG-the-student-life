import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

class AuthService {
  FirebaseAuth get _auth => FirebaseAuth.instance;
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  AuthService();

  Stream<User?> get authStateChanges {
    return _auth.authStateChanges();
  }

  Future<UserCredential?> signIn(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = credential.user?.uid;
      if (uid != null) {
        final role = await getUserRole(uid);
        if (role == 'student') {
          await _ensureGameProfile(uid);
        }
      }

      return credential;
    } catch (e) {
      rethrow;
    }
  }

  Future<UserCredential?> signInWithGoogle({required String role}) async {
    try {
      UserCredential credential;

      if (kIsWeb) {
        final googleProvider = GoogleAuthProvider();
        credential = await _auth.signInWithPopup(googleProvider);
      } else {
        final googleUser = await GoogleSignIn().signIn();
        if (googleUser == null) {
          return null;
        }

        final googleAuth = await googleUser.authentication;
        final authCredential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        credential = await _auth.signInWithCredential(authCredential);
      }

      final user = credential.user;
      if (user == null) return credential;

      await _ensureUserDocument(
        uid: user.uid,
        email: user.email ?? '',
        name: user.displayName ?? 'Student',
        role: role,
        photoUrl: user.photoURL,
      );

      if (role == 'student') {
        await _ensureGameProfile(user.uid);
      }

      return credential;
    } catch (e) {
      rethrow;
    }
  }

  Future<UserCredential?> register(String email, String password, String role, String name) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    
    if (credential.user != null) {
      try {
        await _ensureUserDocument(
          uid: credential.user!.uid,
          email: email,
          role: role,
          name: name,
          photoUrl: credential.user!.photoURL,
        );

        if (role == 'student') {
          await _ensureGameProfile(credential.user!.uid);
        }

        debugPrint('User profile saved to Firestore.');
      } catch (e) {
        debugPrint('Warning: Could not save user profile to Firestore: $e');
      }
    }
    return credential;
  }

  Future<void> _ensureUserDocument({
    required String uid,
    required String email,
    required String role,
    required String name,
    String? photoUrl,
  }) async {
    final userRef = _firestore.collection('users').doc(uid);
    final existing = await userRef.get();

    final payload = <String, dynamic>{
      'email': email,
      'role': role,
      'name': name,
      'photoURL': photoUrl ?? '',
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (!existing.exists) {
      payload.addAll({
        'studentId': '',
        'department': '',
        'batch': '',
        'section': '',
        'academicLevel': '',
        'term': '',
        'playstyle': '',
        'xp': 0,
        'coins': 0,
        'level': 1,
        'profileCompleted': role == 'student' ? false : true,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    await userRef.set(payload, SetOptions(merge: true));
  }

  Future<void> _ensureGameProfile(String uid) async {
    final profileRef = _firestore.collection('game_profiles').doc(uid);
    final existing = await profileRef.get();
    if (existing.exists) {
      return;
    }

    await profileRef.set({
      'arena_rank': 'bronze',
      'quiz_score': 0,
      'exploration_progress': 0,
      'survival_kills': 0,
      'wins': 0,
      'losses': 0,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<bool> isStudentOnboardingComplete(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (!doc.exists) return false;
      final data = doc.data() ?? <String, dynamic>{};
      return data['profileCompleted'] == true;
    } catch (_) {
      return false;
    }
  }

  Future<void> completeStudentOnboarding({
    required String uid,
    required String name,
    required String studentId,
    required String department,
    required String batch,
    required String section,
    required String academicLevel,
    required String term,
    required String playstyle,
  }) async {
    await _firestore.collection('users').doc(uid).set({
      'name': name,
      'studentId': studentId,
      'department': department,
      'batch': batch,
      'section': section,
      'academicLevel': academicLevel,
      'term': term,
      'playstyle': playstyle.toLowerCase(),
      'xp': 0,
      'coins': 0,
      'profileCompleted': true,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await _ensureGameProfile(uid);
  }

  Future<String?> getUserRole(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return doc.data()?['role'] as String?;
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching role: $e');
      return null;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}
