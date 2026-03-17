import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

final userRoleProvider = FutureProvider<String?>((ref) async {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return null;
  return ref.read(authServiceProvider).getUserRole(user.uid);
});

final studentOnboardingCompletedProvider = FutureProvider<bool>((ref) async {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return true;

  final role = await ref.read(authServiceProvider).getUserRole(user.uid);
  if (role != 'student') return true;

  return ref.read(authServiceProvider).isStudentOnboardingComplete(user.uid);
});

class SplashNotifier extends Notifier<bool> {
  @override
  bool build() => false;
  
  void setFinished() => state = true;
}

final splashFinishedProvider = NotifierProvider<SplashNotifier, bool>(SplashNotifier.new);
