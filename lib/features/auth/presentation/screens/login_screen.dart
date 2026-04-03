import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rpg_student_life/theme/app_theme.dart';
import 'package:rpg_student_life/services/auth_service.dart';
import 'package:rpg_student_life/utils/error_handler.dart';
import 'package:rpg_student_life/routes.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin(String intendedRole) async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter email and password')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authService = ref.read(authServiceProvider);
      final cred = await authService.signIn(email, password);

      if (cred?.user != null) {
        final role = await authService.getUserRole(cred!.user!.uid);
        if (mounted) {
          if (role == 'teacher') {
            Navigator.pushReplacementNamed(context, '/teacherDashboard');
          } else if (role == 'admin') {
            Navigator.pushReplacementNamed(context, '/admin');
          } else {
            Navigator.pushReplacementNamed(context, '/studentHome');
          }
        }
      }
    } catch (e) {
      if (mounted) {
        final message = ErrorHandler.getAuthErrorMessage(e);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(message),
          backgroundColor: Colors.redAccent,
        ));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleGoogleLogin(String role) async {
    setState(() => _isLoading = true);
    try {
      final authService = ref.read(authServiceProvider);
      final cred = await authService.signInWithGoogle(role: role);
      if (cred?.user != null && mounted) {
        final userRole = await authService.getUserRole(cred!.user!.uid);
        if (userRole == 'teacher') {
          Navigator.pushReplacementNamed(context, '/teacherDashboard');
        } else if (userRole == 'admin') {
          Navigator.pushReplacementNamed(context, '/admin');
        } else {
          Navigator.pushReplacementNamed(context, AppRoutes.studentHome);
        }
      }
    } catch (e) {
      if (!mounted) return;
      final message = ErrorHandler.getAuthErrorMessage(e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final String role = ModalRoute.of(context)?.settings.arguments as String? ?? 'student';
    final isStudent = role == 'student';
    final isAdmin = role == 'admin';

    final gradientColors = isStudent
      ? const [Color(0xFF3B82F6), Color(0xFF1D4ED8)]
      : isAdmin
        ? const [Color(0xFF8B5CF6), Color(0xFF6D28D9)]
        : const [Color(0xFFF59E0B), Color(0xFFD97706)];
    final accentColor = isStudent
      ? AppTheme.studentAccent
      : isAdmin
        ? const Color(0xFF8B5CF6)
        : AppTheme.teacherAccent;

    return Scaffold(
      backgroundColor: AppTheme.bgColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: gradientColors,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: gradientColors[0].withValues(alpha: 0.5),
                        blurRadius: 16,
                      )
                    ],
                  ),
                  child: Icon(
                    isStudent
                        ? LucideIcons.graduationCap
                        : isAdmin
                            ? LucideIcons.shieldCheck
                            : LucideIcons.shield,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Welcome Back',
                  style: GoogleFonts.poppins(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Login as ${role[0].toUpperCase()}${role.substring(1)}',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: AppTheme.textGray,
                  ),
                ),
                const SizedBox(height: 48),
                TextField(
                  controller: _emailController,
                  style: GoogleFonts.poppins(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: 'Enter your email',
                    prefixIcon: Icon(LucideIcons.mail, color: AppTheme.textGray),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  style: GoogleFonts.poppins(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: 'Enter your password',
                    prefixIcon: Icon(LucideIcons.lock, color: AppTheme.textGray),
                  ),
                  obscureText: true,
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : () => _handleLogin(role),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentColor,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading 
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                            'Login',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
                if (!isAdmin) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _isLoading ? null : () => _handleGoogleLogin(role),
                      icon: const Icon(Icons.g_mobiledata, color: Colors.white),
                      label: Text(
                        'Continue with Google',
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF374151)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Don't have an account? ",
                      style: GoogleFonts.poppins(color: AppTheme.textGray),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pushNamed(context, '/register'),
                      child: Text(
                        'Create account',
                        style: GoogleFonts.poppins(color: accentColor),
                      ),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () => Navigator.pushNamedAndRemoveUntil(
                    context,
                    AppRoutes.initial,
                    (route) => false,
                  ),
                  child: Text(
                    'Change role',
                    style: GoogleFonts.poppins(color: const Color(0xFF6B7280)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
