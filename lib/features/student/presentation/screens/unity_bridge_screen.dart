import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:rpg_student_life/services/unity_bridge_service.dart';
import 'package:rpg_student_life/theme/app_theme.dart';

class UnityBridgeScreen extends ConsumerStatefulWidget {
  const UnityBridgeScreen({super.key});

  @override
  ConsumerState<UnityBridgeScreen> createState() => _UnityBridgeScreenState();
}

class _UnityBridgeScreenState extends ConsumerState<UnityBridgeScreen> {
  static const _gameModes = <String>[
    'battle_arena',
    'rpg_world',
    'quiz_battle',
    'survival_arena',
  ];

  static const _pageBg = Color(0xFF0B1D2A);
  static const _cardBase = Color(0xFF132F3E);
  static const _accent = Color(0xFF00C6FF);

  String _selectedMode = _gameModes.first;
  String _payloadText = '';
  Map<String, dynamic> _payloadData = const <String, dynamic>{};
  bool _loading = true;
  bool _launching = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPayload();
  }

  Future<void> _loadPayload() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final service = ref.read(unityBridgeServiceProvider);
      final payload = await service.buildLaunchPayload(gameMode: _selectedMode);
      final pretty = service.toPrettyJson(payload);

      if (!mounted) return;
      setState(() {
        _payloadData = payload;
        _payloadText = pretty;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _copyPayload() async {
    if (_payloadText.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: _payloadText));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Payload copied to clipboard.')),
    );
  }

  Future<void> _launchUnity() async {
    if (_loading) return;

    setState(() => _launching = true);
    try {
      final service = ref.read(unityBridgeServiceProvider);
      final uri = await service.buildUnityLaunchUri(gameMode: _selectedMode);
      final didLaunch = await launchUrl(uri, mode: LaunchMode.externalApplication);

      if (!mounted) return;

      if (!didLaunch) {
        await Clipboard.setData(ClipboardData(text: uri.toString()));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unity app not found. Launch link copied to clipboard.'),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to launch Unity: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _launching = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pageBg,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Text(
          'Unity Launch Bridge',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Stack(
        children: [
          Positioned(
            top: -120,
            right: -80,
            child: _GlowBlob(color: _accent.withValues(alpha: 0.28), size: 280),
          ),
          Positioned(
            bottom: -140,
            left: -80,
            child: _GlowBlob(
              color: const Color(0xFF10B981).withValues(alpha: 0.18),
              size: 300,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Transform(
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.001)
                    ..rotateX(0.03)
                    ..rotateY(-0.03),
                  alignment: Alignment.center,
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF0F2027),
                          Color(0xFF203A43),
                          Color(0xFF2C5364),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.55),
                          blurRadius: 20,
                          offset: const Offset(10, 10),
                        ),
                        BoxShadow(
                          color: Colors.white.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(-5, -5),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Unity Game Mode',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 20,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          decoration: BoxDecoration(
                            color: _cardBase.withValues(alpha: 0.75),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                          ),
                          child: DropdownButtonFormField<String>(
                            value: _selectedMode,
                            dropdownColor: _cardBase,
                            iconEnabledColor: Colors.white70,
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide.none,
                              ),
                              isDense: true,
                            ),
                            items: _gameModes
                                .map((mode) => DropdownMenuItem(value: mode, child: Text(mode)))
                                .toList(),
                            onChanged: (value) {
                              if (value == null) return;
                              setState(() => _selectedMode = value);
                              _loadPayload();
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                if (_loading)
                  const Expanded(
                    child: Center(
                      child: CircularProgressIndicator(color: _accent),
                    ),
                  )
                else if (_error != null)
                  Expanded(
                    child: Center(
                      child: Text(
                        _error!,
                        style: GoogleFonts.poppins(color: Colors.redAccent),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: Column(
                      children: [
                        _StudentProfile3DCard(payload: _payloadData),
                        const SizedBox(height: 12),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                              child: Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.06),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                                  boxShadow: [
                                    BoxShadow(
                                      color: _accent.withValues(alpha: 0.18),
                                      blurRadius: 30,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: SingleChildScrollView(
                                  child: SelectableText(
                                    _payloadText,
                                    style: GoogleFonts.robotoMono(
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _GradientActionButton(
                        label: 'Refresh Payload',
                        onPressed: _loading ? null : _loadPayload,
                        gradient: const LinearGradient(
                          colors: [Color(0xFF0D2233), Color(0xFF173A52)],
                        ),
                        glowColor: _accent,
                        outlined: true,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _GradientActionButton(
                        label: 'Copy Payload',
                        onPressed: _loading ? null : _copyPayload,
                        gradient: const LinearGradient(
                          colors: [Color(0xFF00C6FF), Color(0xFF0072FF)],
                        ),
                        glowColor: const Color(0xFF0072FF),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _GradientActionButton(
                  label: _launching ? 'Launching...' : 'Launch Unity Game',
                  onPressed: (_loading || _launching) ? null : _launchUnity,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0EDFA3), Color(0xFF0AAE7A)],
                  ),
                  glowColor: const Color(0xFF10B981),
                  trailing: _launching
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : null,
                ),
                const SizedBox(height: 8),
                Text(
                  'Unity must register deep-link scheme rpgstudentlifeunity://launch to receive this payload.',
                  style: GoogleFonts.poppins(
                    color: AppTheme.textGray,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GlowBlob extends StatelessWidget {
  const _GlowBlob({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color, Colors.transparent],
          ),
        ),
      ),
    );
  }
}

class _StudentProfile3DCard extends StatelessWidget {
  const _StudentProfile3DCard({required this.payload});

  final Map<String, dynamic> payload;

  @override
  Widget build(BuildContext context) {
    final playerRaw = payload['player'];
    final profileRaw = payload['gameProfile'];
    final player = playerRaw is Map ? playerRaw.cast<String, dynamic>() : const <String, dynamic>{};
    final profile = profileRaw is Map ? profileRaw.cast<String, dynamic>() : const <String, dynamic>{};

    final name = _readString(player['name'], fallback: 'Student');
    final playstyle = _readString(player['playstyle'], fallback: 'scholar');
    final photoUrl = _readString(player['photoURL']);
    final level = _readInt(player['level']);
    final xp = _readInt(player['xp']);
    final coins = _readInt(player['coins']);

    final abilityRaw = player['ability'];
    final ability = abilityRaw is Map ? abilityRaw.cast<String, dynamic>() : const <String, dynamic>{};
    final abilityName = _readString(ability['name'], fallback: 'No ability');
    final abilityDescription = _readString(ability['description']);

    final arenaRank = _readString(profile['arena_rank'], fallback: 'bronze');
    final wins = _readInt(profile['wins']);
    final losses = _readInt(profile['losses']);

    return Transform(
      transform: Matrix4.identity()
        ..setEntry(3, 2, 0.001)
        ..rotateX(0.02)
        ..rotateY(-0.02),
      alignment: Alignment.center,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            colors: [Color(0xFF102C3B), Color(0xFF0F2432)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF00C6FF).withValues(alpha: 0.25),
              blurRadius: 24,
              spreadRadius: 1,
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 14,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 86,
                  height: 86,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFF00C6FF).withValues(alpha: 0.45),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 1.4),
                    image: photoUrl.isNotEmpty
                        ? DecorationImage(image: NetworkImage(photoUrl), fit: BoxFit.cover)
                        : null,
                    color: const Color(0xFF103041),
                  ),
                  child: photoUrl.isEmpty
                      ? const Icon(Icons.person_rounded, color: Colors.white70, size: 34)
                      : null,
                ),
                Positioned(
                  bottom: 2,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00C6FF),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      'LVL $level',
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF00131B),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Playstyle: $playstyle',
                    style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0A3A4A),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                    ),
                    child: Text(
                      abilityName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        color: const Color(0xFFB9F4FF),
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  if (abilityDescription.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      abilityDescription,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(color: Colors.white60, fontSize: 11),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      _StatPill(label: 'XP', value: '$xp'),
                      _StatPill(label: 'Coins', value: '$coins'),
                      _StatPill(label: 'Rank', value: arenaRank),
                      _StatPill(label: 'W/L', value: '$wins/$losses'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  int _readInt(dynamic value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  String _readString(dynamic value, {String fallback = ''}) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? fallback : text;
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Text(
        '$label: $value',
        style: GoogleFonts.poppins(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _GradientActionButton extends StatelessWidget {
  const _GradientActionButton({
    required this.label,
    required this.onPressed,
    required this.gradient,
    required this.glowColor,
    this.outlined = false,
    this.trailing,
  });

  final String label;
  final VoidCallback? onPressed;
  final LinearGradient gradient;
  final Color glowColor;
  final bool outlined;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final isDisabled = onPressed == null;

    return Opacity(
      opacity: isDisabled ? 0.6 : 1,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          gradient: gradient,
          border: outlined
              ? Border.all(color: Colors.white.withValues(alpha: 0.5), width: 1.3)
              : null,
          boxShadow: [
            BoxShadow(
              color: glowColor.withValues(alpha: 0.38),
              blurRadius: 20,
              spreadRadius: 1,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 17,
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 10),
                trailing!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
