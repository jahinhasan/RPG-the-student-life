import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';

final battleServiceProvider = Provider<BattleService>((ref) {
  return BattleService(ref);
});

class BattleQuestion {
  final String id;
  final String question;
  final List<String> options;
  final int correctIndex;
  final String category;

  BattleQuestion({
    required this.id,
    required this.question,
    required this.options,
    required this.correctIndex,
    required this.category,
  });

  factory BattleQuestion.fromFirestore(Map<String, dynamic> data, String id) {
    return BattleQuestion(
      id: id,
      question: data['question'] ?? '',
      options: List<String>.from(data['options'] ?? []),
      correctIndex: data['correctIndex'] ?? 0,
      category: data['category'] ?? 'General',
    );
  }
}

class BattleOpponent {
  final String uid;
  final String name;
  final int level;
  final String avatar;
  final int xp;

  BattleOpponent({
    required this.uid,
    required this.name,
    required this.level,
    required this.avatar,
    required this.xp,
  });

  factory BattleOpponent.fromFirestore(Map<String, dynamic> data, String uid) {
    return BattleOpponent(
      uid: uid,
      name: data['name'] ?? 'Student',
      level: data['level'] ?? 1,
      avatar: data['avatar'] ?? '👨‍🎓',
      xp: data['xp'] ?? 0,
    );
  }
}

class BattleService {
  final Ref _ref;
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  BattleService(this._ref);

  /// Fetch random opponent excluding current user
  Future<BattleOpponent?> getRandomOpponent() async {
    try {
      final currentUser = _ref.read(authStateProvider).value;
      if (currentUser == null) return null;

      final snapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'student')
          .get();

      final opponents = snapshot.docs
          .where((doc) => doc.id != currentUser.uid)
          .toList();

      if (opponents.isEmpty) return null;

      opponents.shuffle();
      return BattleOpponent.fromFirestore(
          opponents.first.data(), opponents.first.id);
    } catch (e) {
      debugPrint('Error fetching opponent: $e');
      return null;
    }
  }

  /// Fetch battle questions from Firestore
  Future<List<BattleQuestion>> getBattleQuestions({int limit = 5}) async {
    try {
      final snapshot = await _firestore
          .collection('battle_questions')
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => BattleQuestion.fromFirestore(doc.data(), doc.id))
          .toList();
    } catch (e) {
      debugPrint('Error fetching questions: $e');
      return [];
    }
  }

  /// Update user's battle stats after a battle
  Future<void> updateBattleStats({
    required bool won,
    required int xpEarned,
  }) async {
    try {
      final currentUser = _ref.read(authStateProvider).value;
      if (currentUser == null) return;

      final userRef = _firestore.collection('users').doc(currentUser.uid);

      await userRef.update({
        'wins': FieldValue.increment(won ? 1 : 0),
        'losses': FieldValue.increment(won ? 0 : 1),
        'xp': FieldValue.increment(xpEarned),
      });
    } catch (e) {
      debugPrint('Error updating battle stats: $e');
    }
  }

  /// Calculate XP reward based on difficulty
  int calculateXPReward({required bool won, required int difficulty}) {
    if (!won) return 0;
    return 100 * difficulty; // Base 100 XP per difficulty level
  }
}
