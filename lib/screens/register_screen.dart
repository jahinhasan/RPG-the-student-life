import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import '../utils/error_handler.dart';
import '../routes.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  String _selectedRole = 'student';
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _handleRegister() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final name = _nameController.text.trim();

    if (email.isEmpty || password.isEmpty || name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all fields')));
      return;
    }

    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password must be at least 6 characters long')));
      return;
    }

    setState(() => _isLoading = true);
    
    try {
      final authService = ref.read(authServiceProvider);
      await authService.register(
        email,
        password,
        _selectedRole,
        name,
      );

      if (mounted) {
        if (_selectedRole == 'student') {
          Navigator.pushReplacementNamed(context, '/studentHome');
        } else {
          Navigator.pushReplacementNamed(context, '/teacherDashboard');
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

  @override
  Widget build(BuildContext context) {
    final gradientColors = _selectedRole == 'student'
        ? const [Color(0xFF3B82F6), Color(0xFF1D4ED8)]
        : const [Color(0xFFF59E0B), Color(0xFFD97706)];
    final accentColor = _selectedRole == 'student' ? AppTheme.studentAccent : AppTheme.teacherAccent;

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
                    _selectedRole == 'student' ? LucideIcons.graduationCap : LucideIcons.shield,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Create Account',
                  style: GoogleFonts.poppins(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 32),
                
                // Role Picker
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedRole = 'student'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _selectedRole == 'student' ? AppTheme.studentAccent.withValues(alpha: 0.2) : AppTheme.cardColor,
                            border: Border.all(color: _selectedRole == 'student' ? AppTheme.studentAccent : const Color(0xFF374151)),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(child: Text('Student', style: GoogleFonts.poppins(color: _selectedRole == 'student' ? AppTheme.studentAccent : AppTheme.textGray))),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedRole = 'teacher'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _selectedRole == 'teacher' ? AppTheme.teacherAccent.withValues(alpha: 0.2) : AppTheme.cardColor,
                            border: Border.all(color: _selectedRole == 'teacher' ? AppTheme.teacherAccent : const Color(0xFF374151)),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(child: Text('Teacher', style: GoogleFonts.poppins(color: _selectedRole == 'teacher' ? AppTheme.teacherAccent : AppTheme.textGray))),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                TextField(
                  controller: _nameController,
                  style: GoogleFonts.poppins(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: 'Full Name',
                    prefixIcon: Icon(LucideIcons.user, color: AppTheme.textGray),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _emailController,
                  style: GoogleFonts.poppins(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: 'Email address',
                    prefixIcon: Icon(LucideIcons.mail, color: AppTheme.textGray),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  style: GoogleFonts.poppins(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: 'Password',
                    prefixIcon: Icon(LucideIcons.lock, color: AppTheme.textGray),
                  ),
                  obscureText: true,
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleRegister,
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
                            'Create Account',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Already have an account? ",
                      style: GoogleFonts.poppins(color: AppTheme.textGray),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pushNamedAndRemoveUntil(
                        context,
                        AppRoutes.initial,
                        (route) => false,
                      ),
                      child: Text(
                        'Log in',
                        style: GoogleFonts.poppins(color: accentColor),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
