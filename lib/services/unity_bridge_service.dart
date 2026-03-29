import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_provider.dart';
import '../utils/level_calculator.dart';
import '../utils/role_ability.dart';

final unityBridgeServiceProvider = Provider<UnityBridgeService>((ref) {
  return UnityBridgeService(ref);
});

class UnityBridgeService {
  final Ref _ref;
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  UnityBridgeService(this._ref);

  Future<Map<String, dynamic>> buildLaunchPayload({required String gameMode}) async {
    final user = _ref.read(authStateProvider).value;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    final gameProfileDoc = await _firestore.collection('game_profiles').doc(user.uid).get();

    final userData = userDoc.data() ?? <String, dynamic>{};
    final gameData = gameProfileDoc.data() ?? <String, dynamic>{};

    final xpRaw = userData['xp'];
    final xp = xpRaw is num ? xpRaw.toInt() : 0;
    final level = LevelCalculator.getLevel(xp);
    final playstyle = (userData['playstyle'] ?? 'scholar').toString();
    final ability = RoleAbilitySystem.forPlaystyle(playstyle);
    final classIds = (userData['classIds'] as List<dynamic>? ?? const <dynamic>[])
      .map((value) => value.toString())
      .where((value) => value.isNotEmpty)
      .toList();
    final primaryClassId = classIds.isNotEmpty ? classIds.first : '';
    final roomKey = _buildRoomKey(gameMode: gameMode, classId: primaryClassId, uid: user.uid);

    return {
      'launchToken': '${user.uid}-${DateTime.now().millisecondsSinceEpoch}',
      'gameMode': gameMode,
      'player': {
        'uid': user.uid,
        'name': userData['name'] ?? user.displayName ?? 'Student',
        'email': userData['email'] ?? user.email ?? '',
        'photoURL': userData['photoURL'] ?? user.photoURL ?? '',
        'role': userData['role'] ?? 'student',
        'studentId': userData['studentId'] ?? '',
        'department': userData['department'] ?? '',
        'batch': userData['batch'] ?? '',
        'section': userData['section'] ?? '',
        'academicLevel': userData['academicLevel'] ?? '',
        'term': userData['term'] ?? '',
        'classIds': classIds,
        'primaryClassId': primaryClassId,
        'playstyle': playstyle,
        'ability': {
          'name': ability.ability,
          'description': ability.description,
        },
        'xp': xp,
        'coins': (userData['coins'] is num) ? (userData['coins'] as num).toInt() : 0,
        'level': level,
      },
      'gameProfile': {
        'arena_rank': gameData['arena_rank'] ?? 'bronze',
        'quiz_score': (gameData['quiz_score'] is num) ? (gameData['quiz_score'] as num).toInt() : 0,
        'exploration_progress': (gameData['exploration_progress'] is num)
            ? (gameData['exploration_progress'] as num).toInt()
            : 0,
        'survival_kills': (gameData['survival_kills'] is num) ? (gameData['survival_kills'] as num).toInt() : 0,
        'wins': (gameData['wins'] is num) ? (gameData['wins'] as num).toInt() : 0,
        'losses': (gameData['losses'] is num) ? (gameData['losses'] as num).toInt() : 0,
      },
      'matchmaking': {
        'roomKey': roomKey,
        'classId': primaryClassId,
        'mode': gameMode,
        'allowClassmatesOnly': true,
      },
      'meta': {
        'source': 'flutter_app',
        'timestamp': DateTime.now().toIso8601String(),
        'version': 1,
      },
    };
  }

  String toPrettyJson(Map<String, dynamic> payload) {
    return const JsonEncoder.withIndent('  ').convert(payload);
  }

  Future<Uri> buildUnityLaunchUri({required String gameMode}) async {
    final payload = await buildLaunchPayload(gameMode: gameMode);
    final rawJson = jsonEncode(payload);
    final encodedPayload = base64Url.encode(utf8.encode(rawJson));

    return Uri(
      scheme: 'rpgstudentlifeunity',
      host: 'launch',
      queryParameters: {
        'mode': gameMode,
        'payload': encodedPayload,
      },
    );
  }

  String _buildRoomKey({required String gameMode, required String classId, required String uid}) {
    final safeMode = gameMode.trim().toLowerCase();
    final safeClass = classId.trim();
    if (safeClass.isNotEmpty) {
      return 'class_${safeClass}_$safeMode';
    }

    return 'solo_${uid}_$safeMode';
  }
}
