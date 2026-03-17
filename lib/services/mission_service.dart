import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_provider.dart';

final missionServiceProvider = Provider<MissionService>((ref) {
  return MissionService(ref);
});

final missionsProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  return ref.watch(missionServiceProvider).streamMissions();
});

class LocallyClaimedMissionsNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() => <String>{};

  void markClaimed(String missionId) {
    state = {...state, missionId};
  }

  void clearClaimed(String missionId) {
    final next = {...state};
    next.remove(missionId);
    state = next;
  }
}

final locallyClaimedMissionsProvider = NotifierProvider<LocallyClaimedMissionsNotifier, Set<String>>(
  LocallyClaimedMissionsNotifier.new,
);

class MissionService {
  final Ref _ref;
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  MissionService(this._ref);

  Stream<List<Map<String, dynamic>>> streamMissions() {
    final user = _ref.watch(authStateProvider).value;
    if (user == null) return Stream.value(const <Map<String, dynamic>>[]);

    final missionsRef = _firestore.collection('missions');
    final completedRef = _firestore.collection('users').doc(user.uid).collection('completedMissions');
    late final StreamController<List<Map<String, dynamic>>> controller;
    StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? missionsSub;
    StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? completedSub;
    QuerySnapshot<Map<String, dynamic>>? latestMissions;
    QuerySnapshot<Map<String, dynamic>>? latestCompleted;

    void emitMergedMissions() {
      if (latestMissions == null || latestCompleted == null) {
        return;
      }

      final completedIds = latestCompleted!.docs.map((doc) => doc.id).toSet();
      final missions = latestMissions!.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        data['done'] = completedIds.contains(doc.id);
        return data;
      }).toList();

      controller.add(missions);
    }

    controller = StreamController<List<Map<String, dynamic>>>(
      onListen: () {
        missionsSub = missionsRef.snapshots().listen(
          (snapshot) {
            latestMissions = snapshot;
            emitMergedMissions();
          },
          onError: controller.addError,
        );

        completedSub = completedRef.snapshots().listen(
          (snapshot) {
            latestCompleted = snapshot;
            emitMergedMissions();
          },
          onError: controller.addError,
        );
      },
      onCancel: () async {
        await missionsSub?.cancel();
        await completedSub?.cancel();
      },
    );

    return controller.stream.handleError((error, stackTrace) {
      debugPrint('Mission stream error: $error');
    });
  }

  Future<bool> completeMission(String missionId, int xpAward) async {
    final user = _ref.read(authStateProvider).value;
    if (user == null) return false;

    final userDoc = _firestore.collection('users').doc(user.uid);
    final missionDoc = userDoc.collection('completedMissions').doc(missionId);

    final didAward = await _firestore.runTransaction<bool>((transaction) async {
      final missionSnap = await transaction.get(missionDoc);
      final userSnap = await transaction.get(userDoc);

      if (missionSnap.exists) {
        debugPrint('Mission $missionId already exists in completedMissions.');
        return false;
      }

      transaction.set(missionDoc, {
        'completedAt': FieldValue.serverTimestamp(),
        'xpAwarded': xpAward,
      });

      if (userSnap.exists) {
        final currentXP = (userSnap.data()?['xp'] ?? 0) as int;
        transaction.update(userDoc, {
          'xp': currentXP + xpAward,
        });
      } else {
        transaction.set(userDoc, {
          'xp': xpAward,
        }, SetOptions(merge: true));
      }

      return true;
    });

    debugPrint('Mission $missionId claim result: awarded=$didAward');
    return didAward;
  }
}
