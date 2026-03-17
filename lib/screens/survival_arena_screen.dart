import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_theme.dart';

class SurvivalArenaScreen extends StatelessWidget {
  const SurvivalArenaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgColor,
      appBar: AppBar(
        backgroundColor: AppTheme.cardColor,
        title: Text('Survival Arena', style: GoogleFonts.poppins()),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Survival Arena is ready for Unity integration.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 10),
              Text(
                'Your unified profile, XP, and role ability are now prepared in Firebase.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(color: AppTheme.textGray),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
