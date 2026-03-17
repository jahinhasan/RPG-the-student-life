import 'package:flutter/material.dart';
import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'theme/app_theme.dart';
import 'firebase_options.dart';
import 'routes.dart';
import 'providers/auth_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/student_home_screen.dart';
import 'screens/teacher_dashboard_screen.dart';
import 'screens/admin_panel_screen.dart';
import 'screens/role_selection_screen.dart';
import 'screens/student_onboarding_screen.dart';

void main() async {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    try {
      debugPrint("Initializing Firebase...");
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      debugPrint("Firebase initialized successfully.");
    } catch (e) {
      debugPrint("Firebase initialization failed: $e");
    }

    runApp(const ProviderScope(child: RpgApp()));
  }, (error, stack) {
    debugPrint("Uncaught error in main: $error");
    debugPrint(stack.toString());
  });
}

class RpgApp extends ConsumerWidget {
  const RpgApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final userRole = ref.watch(userRoleProvider);
    final splashFinished = ref.watch(splashFinishedProvider);

    return MaterialApp(
      title: 'RPG Student Life',
      theme: AppTheme.darkTheme,
      home: !splashFinished 
        ? const SplashScreen()
        : authState.when(
              data: (user) {
                if (user == null) return const RoleSelectionScreen();
                
                return userRole.when(
                  data: (role) {
                    if (role == 'teacher') return const TeacherDashboardScreen();
                    if (role == 'admin') return const AdminPanelScreen();
                    if (role == 'student') {
                      final onboarding = ref.watch(studentOnboardingCompletedProvider);
                      return onboarding.when(
                        data: (completed) => completed
                            ? const StudentHomeScreen()
                            : const StudentOnboardingScreen(),
                        loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
                        error: (_, __) => const StudentOnboardingScreen(),
                      );
                    }
                    // Avoid logging out UI on transient/null role reads for signed-in users.
                    return const Scaffold(body: Center(child: CircularProgressIndicator()));
                  },
                  loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
                  error: (e, stack) => const Scaffold(body: Center(child: CircularProgressIndicator())),
                );
              },
              loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
              error: (e, stack) => const SplashScreen(),
            ),
      routes: AppRoutes.routes,
      debugShowCheckedModeBanner: false,
    );
  }
}
