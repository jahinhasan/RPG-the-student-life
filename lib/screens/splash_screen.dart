import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import '../providers/auth_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        debugPrint("SplashScreen: Setting splashFinished to true...");
        ref.read(splashFinishedProvider.notifier).setFinished();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 128,
              height: 128,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(color: const Color(0xFF3B82F6).withValues(alpha: 0.5), blurRadius: 32)
                ],
              ),
              child: const Icon(LucideIcons.graduationCap, color: Colors.white, size: 64),
            ),
            const SizedBox(height: 24),
            Text('Student Life RPG', style: GoogleFonts.poppins(fontSize: 32, fontWeight: FontWeight.normal, color: Colors.white)),
            const SizedBox(height: 12),
            const Text('Level Up Your Academic Journey', style: TextStyle(color: AppTheme.textGray, fontSize: 18)),
            const SizedBox(height: 48),
            // Simple generic loading indicator to emulate the dotted pulse
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(width: 8, height: 8, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF3B82F6)))),
                SizedBox(width: 8),
                SizedBox(width: 8, height: 8, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF3B82F6)))),
                SizedBox(width: 8),
                SizedBox(width: 8, height: 8, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF3B82F6)))),
              ],
            )
          ],
        ),
      ),
    );
  }
}
