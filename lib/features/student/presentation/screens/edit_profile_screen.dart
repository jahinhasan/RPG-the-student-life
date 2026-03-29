import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:rpg_student_life/services/xp_service.dart';
import 'package:rpg_student_life/theme/app_theme.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _studentIdCtrl = TextEditingController();
  final _departmentCtrl = TextEditingController();
  final _batchCtrl = TextEditingController();
  final _sectionCtrl = TextEditingController();

  bool _initialized = false;
  bool _saving = false;

  @override
  void dispose() {
    _fullNameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _studentIdCtrl.dispose();
    _departmentCtrl.dispose();
    _batchCtrl.dispose();
    _sectionCtrl.dispose();
    super.dispose();
  }

  void _hydrateControllers(Map<String, dynamic> stats) {
    if (_initialized) {
      return;
    }

    _fullNameCtrl.text = (stats['name'] ?? '') as String;
    _emailCtrl.text = (stats['email'] ?? '') as String;
    _phoneCtrl.text = (stats['phoneNumber'] ?? '') as String;
    _studentIdCtrl.text = (stats['studentId'] ?? '') as String;
    _departmentCtrl.text = (stats['department'] ?? '') as String;
    _batchCtrl.text = (stats['batch'] ?? '') as String;
    _sectionCtrl.text = (stats['section'] ?? '') as String;
    _initialized = true;
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      await ref.read(xpServiceProvider).saveUserProfile(
            fullName: _fullNameCtrl.text.trim(),
            email: _emailCtrl.text.trim(),
            phoneNumber: _phoneCtrl.text.trim(),
        studentId: _studentIdCtrl.text.trim(),
        department: _departmentCtrl.text.trim(),
        batch: _batchCtrl.text.trim(),
        section: _sectionCtrl.text.trim().toUpperCase(),
          );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully.')),
      );
      Navigator.pop(context);
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save profile: $error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userStatsAsync = ref.watch(userStatsProvider);

    return Scaffold(
      backgroundColor: AppTheme.bgColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Edit Profile', style: GoogleFonts.poppins(fontSize: 20)),
        backgroundColor: AppTheme.cardColor,
        elevation: 0,
      ),
      body: userStatsAsync.when(
        data: (stats) {
          if (stats == null) {
            return const Center(
              child: Text('No profile data found', style: TextStyle(color: Colors.white70)),
            );
          }

          _hydrateControllers(stats);

          final title = (stats['title'] ?? 'Novice Scholar') as String;
          final level = (stats['level'] ?? 1).toString();

          return SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 32),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF1E3A8A), Color(0xFF111827)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      border: Border(bottom: BorderSide(color: Color(0xFF1F2937))),
                    ),
                    child: Column(
                      children: [
                        Stack(
                          children: [
                            const CircleAvatar(
                              radius: 48,
                              backgroundColor: AppTheme.studentAccent,
                              child: Icon(LucideIcons.user, size: 48, color: Colors.white),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppTheme.studentAccent,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: const Color(0xFF111827), width: 3),
                                ),
                                child: const Icon(LucideIcons.camera, size: 16, color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _fullNameCtrl.text.isEmpty ? 'Student' : _fullNameCtrl.text,
                          style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.w600, color: Colors.white),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '$title • Level $level',
                          style: const TextStyle(color: AppTheme.teacherAccent, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        _buildSection(
                          'Personal Information',
                          Column(
                            children: [
                              _buildTextField(
                                'Full Name',
                                _fullNameCtrl,
                                validator: (value) {
                                  final text = value?.trim() ?? '';
                                  if (text.isEmpty) {
                                    return 'Enter your full name';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              _buildTextField(
                                'Email',
                                _emailCtrl,
                                keyboardType: TextInputType.emailAddress,
                                validator: (value) {
                                  final text = value?.trim() ?? '';
                                  if (text.isEmpty) {
                                    return 'Enter your email';
                                  }
                                  if (!text.contains('@')) {
                                    return 'Enter a valid email';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              _buildTextField(
                                'Phone Number',
                                _phoneCtrl,
                                keyboardType: TextInputType.phone,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildSection(
                          'Academic Information',
                          Column(
                            children: [
                              _buildTextField(
                                'Student ID',
                                _studentIdCtrl,
                              ),
                              const SizedBox(height: 16),
                              _buildTextField(
                                'Department',
                                _departmentCtrl,
                                validator: (value) {
                                  final text = value?.trim() ?? '';
                                  if (text.isEmpty) {
                                    return 'Enter your department';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildTextField(
                                      'Batch',
                                      _batchCtrl,
                                      keyboardType: TextInputType.text,
                                      validator: (value) {
                                        final text = value?.trim() ?? '';
                                        if (text.isEmpty) {
                                          return 'Batch required';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: _buildTextField(
                                      'Section',
                                      _sectionCtrl,
                                      keyboardType: TextInputType.text,
                                      validator: (value) {
                                        final text = value?.trim() ?? '';
                                        if (text.isEmpty) {
                                          return 'Section required';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _saving ? null : _handleSave,
                            icon: _saving
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : const Icon(LucideIcons.save, color: Colors.white),
                            label: Text(
                              _saving ? 'Saving...' : 'Save Changes',
                              style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF10B981),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Text('Error: $error', style: const TextStyle(color: Colors.white)),
        ),
      ),
    );
  }

  Widget _buildSection(String title, Widget child) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        border: Border.all(color: const Color(0xFF1F2937)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(fontSize: 18, color: Colors.white, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppTheme.textGray, fontSize: 14)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          keyboardType: keyboardType,
          validator: validator,
          decoration: InputDecoration(
            filled: true,
            fillColor: AppTheme.bgColor,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF374151))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF374151))),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.studentAccent, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
      ],
    );
  }
}
