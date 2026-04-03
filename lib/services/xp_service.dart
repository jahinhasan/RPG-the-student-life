import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_provider.dart';
import '../utils/level_calculator.dart';

final xpServiceProvider = Provider<XPService>((ref) {
  return XPService(ref);
});

final userStatsProvider = StreamProvider<Map<String, dynamic>?>((ref) {
  return ref.watch(xpServiceProvider).streamUserStats();
});

class XPService {
  final Ref _ref;
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  XPService(this._ref);

  Stream<Map<String, dynamic>?> streamUserStats() {
    final authState = _ref.watch(authStateProvider);
    final user = authState.value;

    if (user == null) return Stream.value(null);

    return _firestore
        .collection('users')
        .doc(user.uid)
        .snapshots()
        .transform(
          StreamTransformer<DocumentSnapshot<Map<String, dynamic>>, Map<String, dynamic>?>.fromHandlers(
            handleData: (doc, sink) {
              sink.add(_normalizeUserStats(doc.data(), user));
            },
            handleError: (error, stackTrace, sink) {
              debugPrint('User stats stream error: $error');
              sink.add(_normalizeUserStats(null, user));
            },
          ),
        );
  }

  Map<String, dynamic> _normalizeUserStats(Map<String, dynamic>? data, User? user) {
    final rawXp = data?['xp'];
    final xp = rawXp is num ? rawXp.toInt() : 0;
    final computedLevel = LevelCalculator.getLevel(xp);
    final avatar3d = _normalizeAvatar3d(data);

    return {
      'uid': user?.uid ?? '',
      'name': data?['name'] ?? user?.displayName ?? 'Student',
      'email': data?['email'] ?? user?.email ?? '',
      'photoURL': data?['photoURL'] ?? user?.photoURL ?? '',
      'phoneNumber': data?['phoneNumber'] ?? '',
      'studentId': data?['studentId'] ?? '',
      'department': data?['department'] ?? '',
      'batch': data?['batch'] ?? '',
      'section': data?['section'] ?? '',
      'academicLevel': data?['academicLevel'] ?? '',
      'term': data?['term'] ?? '',
      'playstyle': data?['playstyle'] ?? 'scholar',
      'coins': _readInt(data?['coins'], 0),
      'classIds': List<String>.from(data?['classIds'] ?? const <String>[]),
      'profileCompleted': data?['profileCompleted'] == true,
      'role': data?['role'] ?? 'student',
      'xp': xp,
      'level': computedLevel,
      'title': data?['title'] ?? _titleForLevel(computedLevel),
      'rank': _readInt(data?['rank'], 0),
      'gpa': _readDouble(data?['gpa'], 0),
      'attendance': _readInt(data?['attendance'], 0),
      'cpa': _readDouble(data?['cpa'], 0),
      'wins': _readInt(data?['wins'], 0),
      'losses': _readInt(data?['losses'], 0),
      'avatar': data?['avatar'] ?? '👨‍🎓',
      'selectedOutfit': data?['selectedOutfit'] ?? '',
      'selectedAccessory': data?['selectedAccessory'] ?? '',
      'selectedBadge': data?['selectedBadge'] ?? '',
      'avatar3d': avatar3d,
    };
  }

  Map<String, dynamic> _normalizeAvatar3d(Map<String, dynamic>? data) {
    final raw = data?['avatar3d'];
    final source = raw is Map<String, dynamic>
        ? raw
        : (raw is Map ? Map<String, dynamic>.from(raw) : <String, dynamic>{});

    final selectedOutfit = (data?['selectedOutfit'] ?? '').toString();
    final selectedAccessory = (data?['selectedAccessory'] ?? '').toString();
    final selectedBadge = (data?['selectedBadge'] ?? '').toString();

    final outfitId = _readString(source['outfitId'], _slugify(selectedOutfit));
    final accessoryId = _readString(source['accessoryId'], _slugify(selectedAccessory));
    final badgeId = _readString(source['badgeId'], _slugify(selectedBadge));
    final modelId = _readString(source['modelId'], _resolveModelId(outfitId));
    final palette = _paletteForModel(modelId);

    return {
      'modelId': modelId,
      'outfitId': outfitId,
      'accessoryId': accessoryId,
      'badgeId': badgeId,
      'skinColor': _readString(source['skinColor'], palette['skinColor']!),
      'primaryColor': _readString(source['primaryColor'], palette['primaryColor']!),
      'secondaryColor': _readString(source['secondaryColor'], palette['secondaryColor']!),
      'emissionColor': _readString(source['emissionColor'], palette['emissionColor']!),
    };
  }

  String _readString(Object? value, String fallback) {
    final text = value?.toString().trim() ?? '';
    if (text.isEmpty) return fallback;
    return text;
  }

  String _slugify(String value) {
    final trimmed = value.trim().toLowerCase();
    if (trimmed.isEmpty) return '';
    return trimmed.replaceAll(RegExp(r'[^a-z0-9]+'), '_').replaceAll(RegExp(r'_+'), '_').replaceAll(RegExp(r'^_|_$'), '');
  }

  String _resolveModelId(String outfitId) {
    if (outfitId.contains('wizard')) return 'arcane_master';
    if (outfitId.contains('lab')) return 'lab_scout';
    if (outfitId.contains('business')) return 'campus_executive';
    return 'scholar_core';
  }

  Map<String, String> _paletteForModel(String modelId) {
    switch (modelId) {
      case 'arcane_master':
        return {
          'skinColor': '#F1C27D',
          'primaryColor': '#6D28D9',
          'secondaryColor': '#A78BFA',
          'emissionColor': '#C4B5FD',
        };
      case 'lab_scout':
        return {
          'skinColor': '#E8BE98',
          'primaryColor': '#0F172A',
          'secondaryColor': '#38BDF8',
          'emissionColor': '#7DD3FC',
        };
      case 'campus_executive':
        return {
          'skinColor': '#D8A56D',
          'primaryColor': '#1F2937',
          'secondaryColor': '#60A5FA',
          'emissionColor': '#93C5FD',
        };
      default:
        return {
          'skinColor': '#E0AC69',
          'primaryColor': '#1E3A8A',
          'secondaryColor': '#38BDF8',
          'emissionColor': '#7DD3FC',
        };
    }
  }

  int _readInt(Object? value, int fallback) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return fallback;
  }

  double _readDouble(Object? value, double fallback) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return fallback;
  }

  String _titleForLevel(int level) {
    if (level >= 15) return 'Master Scholar';
    if (level >= 10) return 'Senior Strategist';
    if (level >= 5) return 'Campus Challenger';
    return 'Novice Scholar';
  }

  Future<void> addXP(int amount) async {
    final user = _ref.read(authStateProvider).value;
    if (user == null) return;

    final userDoc = _firestore.collection('users').doc(user.uid);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(userDoc);
      if (!snapshot.exists) return;

      final currentXP = _readInt(snapshot.data()?['xp'], 0);
      final newXP = currentXP + amount;
      final newLevel = LevelCalculator.getLevel(newXP);

      transaction.update(userDoc, {
        'xp': newXP,
        'level': newLevel,
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> addXPToStudent(String uid, int amount) async {
    final userDoc = _firestore.collection('users').doc(uid);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(userDoc);
      if (!snapshot.exists) return;

      final currentXP = _readInt(snapshot.data()?['xp'], 0);
      final newXP = currentXP + amount;
      final newLevel = LevelCalculator.getLevel(newXP);

      transaction.update(userDoc, {
        'xp': newXP,
        'level': newLevel,
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> setStudentLevelMinimum(String uid, int minLevel) async {
    final userDoc = _firestore.collection('users').doc(uid);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(userDoc);
      if (!snapshot.exists) return;

      final data = snapshot.data() ?? {};
      final currentLevel = _readInt(data['level'], 1);
      final currentXp = _readInt(data['xp'], 0);
      final targetLevel = minLevel > currentLevel ? minLevel : currentLevel;

      transaction.update(userDoc, {
        'level': targetLevel,
        'xp': currentXp,
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> assignBadgeToStudent(String uid, String badgeName) async {
    await _firestore.collection('users').doc(uid).set({
      'selectedBadge': badgeName,
      'lastUpdated': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> bulkAddXP(List<String> uids, int amount) async {
    for (var uid in uids) {
      await addXPToStudent(uid, amount);
    }
  }

  Future<void> saveUserProfile({
    required String fullName,
    required String email,
    required String phoneNumber,
    String? studentId,
    String? department,
    String? batch,
    String? section,
    String? academicLevel,
    String? term,
    String? playstyle,
  }) async {
    final user = _ref.read(authStateProvider).value;
    if (user == null) return;

    final payload = <String, dynamic>{
      'name': fullName,
      'email': email,
      'phoneNumber': phoneNumber,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (studentId != null) {
      payload['studentId'] = studentId;
    }
    if (department != null) {
      payload['department'] = department;
    }
    if (batch != null) {
      payload['batch'] = batch;
    }
    if (section != null) {
      payload['section'] = section;
    }
    if (academicLevel != null) {
      payload['academicLevel'] = academicLevel;
    }
    if (term != null) {
      payload['term'] = term;
    }
    if (playstyle != null) {
      payload['playstyle'] = playstyle;
    }

    await _firestore.collection('users').doc(user.uid).set(
      payload,
      SetOptions(merge: true),
    );
  }

  Future<void> awardGameXP({
    required String gameMode,
    required String eventType,
  }) async {
    final xpRules = <String, int>{
      'battle_arena_win': 30,
      'battle_arena_loss': 10,
      'quiz_correct': 10,
      'world_quest': 20,
      'survival_kill': 5,
    };

    final key = '${gameMode}_$eventType';
    final amount = xpRules[key] ?? 0;
    if (amount > 0) {
      await addXP(amount);
    }
  }

  Future<void> updateGameProfileStats({
    required String uid,
    int? quizScoreDelta,
    int? explorationDelta,
    int? survivalKillsDelta,
    int? winsDelta,
    int? lossesDelta,
    String? arenaRank,
  }) async {
    final updates = <String, dynamic>{
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (quizScoreDelta != null) {
      updates['quiz_score'] = FieldValue.increment(quizScoreDelta);
    }
    if (explorationDelta != null) {
      updates['exploration_progress'] = FieldValue.increment(explorationDelta);
    }
    if (survivalKillsDelta != null) {
      updates['survival_kills'] = FieldValue.increment(survivalKillsDelta);
    }
    if (winsDelta != null) {
      updates['wins'] = FieldValue.increment(winsDelta);
    }
    if (lossesDelta != null) {
      updates['losses'] = FieldValue.increment(lossesDelta);
    }
    if (arenaRank != null && arenaRank.isNotEmpty) {
      updates['arena_rank'] = arenaRank;
    }

    await _firestore.collection('game_profiles').doc(uid).set(updates, SetOptions(merge: true));
  }

  Future<void> saveAvatarSelection({
    required String category,
    required String emoji,
    required String name,
  }) async {
    final user = _ref.read(authStateProvider).value;
    if (user == null) return;

    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    final data = userDoc.data() ?? <String, dynamic>{};

    final existingAvatar3dRaw = data['avatar3d'];
    final existingAvatar3d = existingAvatar3dRaw is Map<String, dynamic>
        ? existingAvatar3dRaw
        : (existingAvatar3dRaw is Map ? Map<String, dynamic>.from(existingAvatar3dRaw) : <String, dynamic>{});

    var outfitId = _readString(existingAvatar3d['outfitId'], _slugify((data['selectedOutfit'] ?? '').toString()));
    var accessoryId = _readString(existingAvatar3d['accessoryId'], _slugify((data['selectedAccessory'] ?? '').toString()));
    var badgeId = _readString(existingAvatar3d['badgeId'], _slugify((data['selectedBadge'] ?? '').toString()));

    final update = <String, dynamic>{'updatedAt': FieldValue.serverTimestamp()};

    if (category == 'outfit') {
      update['avatar'] = emoji;
      update['selectedOutfit'] = name;
      outfitId = _slugify(name);
    }
    if (category == 'accessories') {
      update['selectedAccessory'] = name;
      accessoryId = _slugify(name);
    }
    if (category == 'badges') {
      update['selectedBadge'] = name;
      badgeId = _slugify(name);
    }

    final modelId = _resolveModelId(outfitId);
    final palette = _paletteForModel(modelId);
    final avatar3d = {
      'modelId': modelId,
      'outfitId': outfitId,
      'accessoryId': accessoryId,
      'badgeId': badgeId,
      'skinColor': _readString(existingAvatar3d['skinColor'], palette['skinColor']!),
      'primaryColor': _readString(existingAvatar3d['primaryColor'], palette['primaryColor']!),
      'secondaryColor': _readString(existingAvatar3d['secondaryColor'], palette['secondaryColor']!),
      'emissionColor': _readString(existingAvatar3d['emissionColor'], palette['emissionColor']!),
    };
    update['avatar3d'] = avatar3d;

    await _firestore.collection('users').doc(user.uid).set(
      update,
      SetOptions(merge: true),
    );
  }

  Stream<List<Map<String, dynamic>>> streamLeaderboard() {
    return _firestore
        .collection('users')
        .where('role', isEqualTo: 'student')
        .orderBy('xp', descending: true)
        .limit(10)
        .snapshots()
        .transform(
          StreamTransformer<QuerySnapshot<Map<String, dynamic>>, List<Map<String, dynamic>>>.fromHandlers(
            handleData: (snapshot, sink) {
              final users = snapshot.docs.asMap().entries.map((entry) {
                final data = entry.value.data();
                return {
                  'rank': entry.key + 1,
                  'name': data['name'] ?? 'Unknown',
                  'avatar': data['avatar'] ?? '👨‍🎓',
                  'xp': data['xp'] ?? 0,
                  'level': LevelCalculator.getLevel(data['xp'] ?? 0),
                  'uid': entry.value.id,
                };
              }).toList();
              sink.add(users);
            },
            handleError: (error, stackTrace, sink) {
              debugPrint('Leaderboard stream error: $error');
              sink.add(const <Map<String, dynamic>>[]);
            },
          ),
        );
  }

  Stream<List<Map<String, dynamic>>> streamWorldMapStudents() {
    return _firestore
        .collection('users')
        .where('role', isEqualTo: 'student')
        .orderBy('xp', descending: true)
        .limit(100)
        .snapshots()
        .transform(
          StreamTransformer<QuerySnapshot<Map<String, dynamic>>, List<Map<String, dynamic>>>.fromHandlers(
            handleData: (snapshot, sink) {
              final users = snapshot.docs.map((doc) {
                final data = doc.data();
                final rawXp = data['xp'];
                final xp = rawXp is num ? rawXp.toInt() : 0;
                return {
                  'uid': doc.id,
                  'name': data['name'] ?? 'Student',
                  'avatar': data['avatar'] ?? '👨‍🎓',
                  'xp': xp,
                  'level': LevelCalculator.getLevel(xp),
                };
              }).toList();
              sink.add(users);
            },
            handleError: (error, stackTrace, sink) {
              debugPrint('World map students stream error: $error');
              sink.add(const <Map<String, dynamic>>[]);
            },
          ),
        );
  }
}

final leaderboardProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  return ref.watch(xpServiceProvider).streamLeaderboard();
});

final worldMapStudentsProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  return ref.watch(xpServiceProvider).streamWorldMapStudents();
});
