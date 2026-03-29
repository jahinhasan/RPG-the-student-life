import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:rpg_student_life/services/auth_service.dart';
import 'package:rpg_student_life/theme/app_theme.dart';

class StudentOnboardingScreen extends ConsumerStatefulWidget {
  const StudentOnboardingScreen({super.key});

  @override
  ConsumerState<StudentOnboardingScreen> createState() => _StudentOnboardingScreenState();
}

class _StudentOnboardingScreenState extends ConsumerState<StudentOnboardingScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameCtrl = TextEditingController();
  final _studentIdCtrl = TextEditingController();
  final _departmentCtrl = TextEditingController();
  final _batchCtrl = TextEditingController();
  final _sectionCtrl = TextEditingController();
  final _levelCtrl = TextEditingController();
  final _termCtrl = TextEditingController();

  String _selectedPlaystyle = 'Scholar';
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    _nameCtrl.text = user?.displayName ?? '';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _studentIdCtrl.dispose();
    _departmentCtrl.dispose();
    _batchCtrl.dispose();
    _sectionCtrl.dispose();
    _levelCtrl.dispose();
    _termCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _saving = true);

    try {
      await ref.read(authServiceProvider).completeStudentOnboarding(
            uid: user.uid,
            name: _nameCtrl.text.trim(),
            studentId: _studentIdCtrl.text.trim(),
            department: _departmentCtrl.text.trim(),
            batch: _batchCtrl.text.trim(),
            section: _sectionCtrl.text.trim().toUpperCase(),
            academicLevel: _levelCtrl.text.trim(),
            term: _termCtrl.text.trim(),
            playstyle: _selectedPlaystyle,
          );

      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, '/studentHome', (route) => false);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to complete onboarding: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: AppTheme.cardColor,
        title: Text('Complete Your Profile', style: GoogleFonts.poppins()),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Academic Info',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              _input('Name', _nameCtrl),
              _input('Student ID', _studentIdCtrl),
              _input('Department', _departmentCtrl),
              _input('Batch', _batchCtrl),
              _input('Section', _sectionCtrl),
              _input('Level', _levelCtrl),
              _input('Term', _termCtrl),
              const SizedBox(height: 20),
              Text(
                'Game Preference',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedPlaystyle,
                dropdownColor: AppTheme.cardColor,
                style: const TextStyle(color: Colors.white),
                decoration: _decoration('Preferred Playstyle'),
                items: const [
                  DropdownMenuItem(value: 'Fighter', child: Text('Fighter')),
                  DropdownMenuItem(value: 'Scholar', child: Text('Scholar')),
                  DropdownMenuItem(value: 'Explorer', child: Text('Explorer')),
                  DropdownMenuItem(value: 'Tactical', child: Text('Tactical')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedPlaystyle = value);
                  }
                },
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saving ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.studentAccent,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text(
                          'Save & Continue',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _input(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        style: const TextStyle(color: Colors.white),
        decoration: _decoration(label),
        validator: (value) {
          if ((value ?? '').trim().isEmpty) {
            return '$label is required';
          }
          return null;
        },
      ),
    );
  }

  InputDecoration _decoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: AppTheme.textGray),
      filled: true,
      fillColor: AppTheme.cardColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    );
  }
}
