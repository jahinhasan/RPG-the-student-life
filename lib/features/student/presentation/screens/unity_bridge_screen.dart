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

  String _selectedMode = _gameModes.first;
  String _payloadText = '';
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
      backgroundColor: AppTheme.bgColor,
      appBar: AppBar(
        backgroundColor: AppTheme.cardColor,
        title: Text('Unity Launch Bridge', style: GoogleFonts.poppins()),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.cardColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF1F2937)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Unity Game Mode',
                    style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: _selectedMode,
                    dropdownColor: AppTheme.cardColor,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
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
                ],
              ),
            ),
            const SizedBox(height: 14),
            if (_loading)
              const Expanded(child: Center(child: CircularProgressIndicator()))
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
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.cardColor,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFF1F2937)),
                  ),
                  child: SingleChildScrollView(
                    child: SelectableText(
                      _payloadText,
                      style: GoogleFonts.robotoMono(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _loading ? null : _loadPayload,
                    child: const Text('Refresh Payload'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _loading ? null : _copyPayload,
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.studentAccent),
                    child: const Text('Copy Payload'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (_loading || _launching) ? null : _launchUnity,
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
                child: _launching
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Launch Unity Game'),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Unity must register deep-link scheme rpgstudentlifeunity://launch to receive this payload.',
              style: GoogleFonts.poppins(color: AppTheme.textGray, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}
