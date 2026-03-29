import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:rpg_student_life/theme/app_theme.dart';
import 'package:rpg_student_life/routes.dart';
import 'package:rpg_student_life/services/auth_service.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppTheme.bgColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Settings', style: GoogleFonts.poppins(fontSize: 20)),
        backgroundColor: AppTheme.cardColor,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            _buildSettingTile(
              icon: LucideIcons.user,
              title: 'Edit Profile',
              onTap: () => Navigator.pushNamed(context, AppRoutes.editProfile),
            ),
            const SizedBox(height: 8),
            _buildSettingTile(
              icon: LucideIcons.bell,
              title: 'Notifications',
              onTap: () => Navigator.pushNamed(context, AppRoutes.notifications),
            ),
            const SizedBox(height: 8),
            _buildSettingTile(
              icon: LucideIcons.moon,
              title: 'Dark Mode',
              isToggle: true,
              toggleValue: true,
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Dark mode is enabled by default in this build.')),
                );
              },
            ),
            const SizedBox(height: 8),
            _buildSettingTile(
              icon: LucideIcons.helpCircle,
              title: 'Help & Support',
              onTap: () => _showHelpSheet(context),
            ),
            
            const SizedBox(height: 32),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.cardColor,
                border: Border.all(color: const Color(0xFF1F2937)),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Text('Student Life RPG', style: GoogleFonts.poppins(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  const Text('Version 1.0.0', style: TextStyle(color: AppTheme.textGray, fontSize: 14)),
                  const SizedBox(height: 4),
                  const Text('Level Up Your Academic Journey', style: TextStyle(color: Colors.white54, fontSize: 12)),
                ],
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  await ref.read(authServiceProvider).signOut();
                  if (context.mounted) {
                    Navigator.pushNamedAndRemoveUntil(context, AppRoutes.initial, (route) => false);
                  }
                },
                icon: const Icon(LucideIcons.logOut, color: Colors.white),
                label: Text('Logout', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEF4444), // red
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  void _showHelpSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppTheme.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Help & Support',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Common actions you can use right now in Student Life RPG:',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 16),
                _buildHelpRow(LucideIcons.user, 'Profile', 'Update your personal details and academic info.'),
                _buildHelpRow(LucideIcons.map, 'World Map', 'Open unlocked zones and complete objectives for XP.'),
                _buildHelpRow(LucideIcons.gamepad2, 'Mini Games', 'Play challenge modes to earn extra rewards.'),
                _buildHelpRow(LucideIcons.bell, 'Notifications', 'Review recent activity and system updates.'),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Close',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHelpRow(IconData icon, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.bgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppTheme.studentAccent, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingTile({required IconData icon, required String title, required VoidCallback onTap, bool isToggle = false, bool toggleValue = false}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          border: Border.all(color: const Color(0xFF1F2937)),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: AppTheme.bgColor,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppTheme.textGray, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(title, style: GoogleFonts.poppins(color: Colors.white, fontSize: 15)),
            ),
            if (isToggle)
              Switch(
                value: toggleValue,
                onChanged: (_) {},
                activeThumbColor: AppTheme.studentAccent,
              )
            else
              const Icon(LucideIcons.chevronRight, color: AppTheme.textGray, size: 20),
          ],
        ),
      ),
    );
  }
}
