import 'package:firebase_auth/firebase_auth.dart';

class ErrorHandler {
  static String getAuthErrorMessage(dynamic error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'invalid-email':
          return 'The email address is badly formatted.';
        case 'user-not-found':
          return 'No user found for that email.';
        case 'wrong-password':
          return 'Wrong password provided for that user.';
        case 'email-already-in-use':
          return 'An account already exists for that email.';
        case 'weak-password':
          return 'The password provided is too weak (min 6 characters).';
        case 'operation-not-allowed':
          return 'Operation not allowed. Please contact support.';
        case 'user-disabled':
          return 'This user account has been disabled.';
        case 'too-many-requests':
          return 'Too many requests. Please try again later.';
        default:
          return error.message ?? 'An unexpected authentication error occurred.';
      }
    }
    return error.toString();
  }
}
