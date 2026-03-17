import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../theme/app_theme.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  void _handleRoleSelect(BuildContext context, String role) {
    Navigator.pushNamed(context, '/login', arguments: role);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
            child: Column(
              children: [
                // Header
                Column(
                  children: [
                    Icon(LucideIcons.zap, color: AppTheme.studentAccent, size: 48),
                    const SizedBox(height: 20),
                    Text(
                      'RPG Student Life',
                      style: GoogleFonts.poppins(
                        fontSize: 36,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Choose your path and start your adventure',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: AppTheme.textGray,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
                const SizedBox(height: 60),

                // Student Role Card
                _buildRoleCard(
                  context: context,
                  role: 'student',
                  title: 'Student Path',
                  subtitle: 'Level up through learning\n& complete missions',
                  icon: LucideIcons.book,
                  gradientColors: const [Color(0xFF667EEA), Color(0xFF764BA2)],
                  accentColor: AppTheme.studentAccent,
                  features: ['Track GPA', 'Complete Missions', 'Battle Arena', 'Leaderboard'],
                ),
                const SizedBox(height: 24),

                // Teacher Role Card
                _buildRoleCard(
                  context: context,
                  role: 'teacher',
                  title: 'Teacher Path',
                  subtitle: 'Guide students & manage\nclassroom gamification',
                  icon: LucideIcons.users,
                  gradientColors: const [Color(0xFFFFA500), Color(0xFFFF6B6B)],
                  accentColor: AppTheme.teacherAccent,
                  features: ['Manage Classes', 'Set Missions', 'Track Progress', 'Leaderboard'],
                ),

                const SizedBox(height: 24),

                _buildRoleCard(
                  context: context,
                  role: 'admin',
                  title: 'Admin Path',
                  subtitle: 'Configure hierarchy,\nmanage platform rules',
                  icon: LucideIcons.shieldCheck,
                  gradientColors: const [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
                  accentColor: const Color(0xFF8B5CF6),
                  features: ['Manage Hierarchy', 'Assign Teachers', 'Configure XP Rules', 'System Analytics'],
                ),

                const SizedBox(height: 40),

                // Footer Info
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1F2937),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF374151), width: 1),
                  ),
                  child: Row(
                    children: [
                      Icon(LucideIcons.info, color: AppTheme.textGray, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'You can switch roles anytime from settings',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: AppTheme.textGray,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleCard({
    required BuildContext context,
    required String role,
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Color> gradientColors,
    required Color accentColor,
    required List<String> features,
  }) {
    return GestureDetector(
      onTap: () => _handleRoleSelect(context, role),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradientColors,
          ),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: gradientColors.first.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Decorative elements
            Positioned(
              top: -30,
              right: -30,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.1),
                ),
              ),
            ),
            Positioned(
              bottom: -20,
              left: -20,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon and title row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.3),
                            width: 1.5,
                          ),
                        ),
                        child: Icon(
                          icon,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 18),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: GoogleFonts.poppins(
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              subtitle,
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: Colors.white.withValues(alpha: 0.85),
                                fontWeight: FontWeight.w500,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Features list
                  Column(
                    children: features
                        .map((feature) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Row(
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.white.withValues(alpha: 0.8),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    feature,
                                    style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      color: Colors.white.withValues(alpha: 0.9),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ))
                        .toList(),
                  ),

                  const SizedBox(height: 20),

                  // CTA Button
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.4),
                        width: 1.5,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        'START HERE →',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
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
  }
}
