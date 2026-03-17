import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Admin Service for managing:
/// - Teacher-to-class assignments
/// - Batch/Level/Term/Class hierarchy
/// - Student grouping and performance tracking
/// - Teacher mission assignment scoping

class AdminService {
  final FirebaseFirestore _firestore;

  AdminService(this._firestore);

  static const Map<String, dynamic> defaultXpSettings = {
    'attendancePresentXp': 10,
    'attendanceAbsentPenalty': 4,
    'assessmentBaseXp': {
      'class_performance': 80,
      'ct': 100,
      'mid': 140,
      'final': 180,
    },
    'performanceDropPenaltyMultiplier': 1.0,
    'performanceDropPenaltyCapPercent': 70,
  };

  // ==================== Batch Management ====================

  /// Create or update a batch (university year grouping)
  /// Example: Batch 2023, Batch 2024
  Future<void> createBatch({
    required String batchId,
    required int year,
  }) async {
    await _firestore.collection('batches').doc(batchId).set({
      'year': year,
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Stream of all batches
  Stream<List<Map<String, dynamic>>> streamBatches() {
    return _firestore
        .collection('batches')
        .orderBy('year', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => {'id': doc.id, ...doc.data()})
            .toList());
  }

  /// Delete a batch
  Future<void> deleteBatch(String batchId) async {
    await _firestore.collection('batches').doc(batchId).delete();
  }

  // ==================== Level Management ====================

  /// Create or update an academic level (e.g., Level 1, Level 2, etc.)
  Future<void> createLevel({
    required String levelId,
    required int levelNumber,
  }) async {
    await _firestore.collection('levels').doc(levelId).set({
      'levelNumber': levelNumber,
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Stream of all levels
  Stream<List<Map<String, dynamic>>> streamLevels() {
    return _firestore
        .collection('levels')
        .orderBy('levelNumber')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => {'id': doc.id, ...doc.data()})
            .toList());
  }

  /// Delete a level
  Future<void> deleteLevel(String levelId) async {
    await _firestore.collection('levels').doc(levelId).delete();
  }

  // ==================== Term Management ====================

  /// Create or update a term (e.g., Spring, Fall, Summer)
  Future<void> createTerm({
    required String termId,
    required String termName,
    required int termNumber,
  }) async {
    await _firestore.collection('terms').doc(termId).set({
      'termName': termName,
      'termNumber': termNumber,
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Stream of all terms
  Stream<List<Map<String, dynamic>>> streamTerms() {
    return _firestore
        .collection('terms')
        .orderBy('termNumber')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => {'id': doc.id, ...doc.data()})
            .toList());
  }

  /// Delete a term
  Future<void> deleteTerm(String termId) async {
    await _firestore.collection('terms').doc(termId).delete();
  }

  // ==================== Class Management ====================

  /// Create a class (combination of batch, level, term, and section)
  /// Example: Batch 2023, Level 1, Term 1, Section A
  Future<void> createClass({
    required String classId,
    required String batchId,
    required String levelId,
    required String termId,
    required String sectionName,
    required List<String> assignedTeacherIds,
  }) async {
    await _firestore.collection('classes').doc(classId).set({
      'batchId': batchId,
      'levelId': levelId,
      'termId': termId,
      'sectionName': sectionName, // A, B, C, etc.
      'assignedTeacherIds': assignedTeacherIds,
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Get a specific class with teacher details
  Future<Map<String, dynamic>?> getClassWithTeachers(String classId) async {
    final classDoc = await _firestore.collection('classes').doc(classId).get();
    if (!classDoc.exists) return null;

    final classData = classDoc.data()!;
    final teacherIds = List<String>.from(classData['assignedTeacherIds'] ?? []);

    // Fetch teacher details
    List<Map<String, dynamic>> teachers = [];
    for (final teacherId in teacherIds) {
      final teacherDoc = await _firestore.collection('users').doc(teacherId).get();
      if (teacherDoc.exists) {
        teachers.add({'id': teacherId, ...teacherDoc.data()!});
      }
    }

    return {'id': classId, 'teachers': teachers, ...classData};
  }

  /// Stream of all classes for a batch+level+term
  Stream<List<Map<String, dynamic>>> streamClassesByLevelTerm({
    required String batchId,
    required String levelId,
    required String termId,
  }) {
    return _firestore
        .collection('classes')
        .where('batchId', isEqualTo: batchId)
        .where('levelId', isEqualTo: levelId)
        .where('termId', isEqualTo: termId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => {'id': doc.id, ...doc.data()})
            .toList());
  }

  /// Stream of all classes
  Stream<List<Map<String, dynamic>>> streamClasses() {
    return _firestore
        .collection('classes')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => {'id': doc.id, ...doc.data()})
            .toList());
  }

  /// Delete a class
  Future<void> deleteClass(String classId) async {
    await _firestore.collection('classes').doc(classId).delete();
  }

  // ==================== Teacher-Class Assignment ====================

  /// Assign teachers to a class
  Future<void> assignTeachersToClass({
    required String classId,
    required List<String> teacherIds,
  }) async {
    final classRef = _firestore.collection('classes').doc(classId);
    final classDoc = await classRef.get();
    if (!classDoc.exists) {
      throw Exception('Class not found');
    }

    final classData = classDoc.data() ?? {};
    final previousTeacherIds =
        List<String>.from(classData['assignedTeacherIds'] ?? <String>[]);

    await classRef.set({
      'assignedTeacherIds': teacherIds,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    // Remove stale teacher-class links for teachers that are no longer assigned.
    for (final staleTeacherId in previousTeacherIds.where((id) => !teacherIds.contains(id))) {
      final staleTeacherRef = _firestore.collection('users').doc(staleTeacherId);
      final staleTeacherDoc = await staleTeacherRef.get();
      if (!staleTeacherDoc.exists) continue;

      final staleTeacherData = staleTeacherDoc.data() ?? {};
      final assignedClasses =
          List<String>.from(staleTeacherData['assignedClassIds'] ?? <String>[]);
      assignedClasses.remove(classId);
      await staleTeacherRef.set({
        'assignedClassIds': assignedClasses,
      }, SetOptions(merge: true));
    }

    // Ensure assigned teachers contain this class id.
    for (final teacherId in teacherIds) {
      final teacherRef = _firestore.collection('users').doc(teacherId);
      final teacherDoc = await teacherRef.get();
      if (!teacherDoc.exists) continue;

      final teacherData = teacherDoc.data() ?? {};
      final assignedClasses =
          List<String>.from(teacherData['assignedClassIds'] ?? <String>[]);
      if (!assignedClasses.contains(classId)) {
        assignedClasses.add(classId);
      }

      await teacherRef.set({
        'assignedClassIds': assignedClasses,
      }, SetOptions(merge: true));
    }
  }

  /// Remove a teacher from a class
  Future<void> removeTeacherFromClass({
    required String classId,
    required String teacherId,
  }) async {
    final classDoc = await _firestore.collection('classes').doc(classId).get();
    if (classDoc.exists) {
      final classData = classDoc.data() ?? {};
      final teachers =
          List<String>.from(classData['assignedTeacherIds'] ?? <String>[]);
      teachers.remove(teacherId);
      await _firestore.collection('classes').doc(classId).set({
        'assignedTeacherIds': teachers,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }

    // Remove from teacher's assigned classes
    final teacherDoc = await _firestore.collection('users').doc(teacherId).get();
    if (teacherDoc.exists) {
      final teacherData = teacherDoc.data() ?? {};
      final assignedClasses =
          List<String>.from(teacherData['assignedClassIds'] ?? <String>[]);
      assignedClasses.remove(classId);
      await _firestore.collection('users').doc(teacherId).set({
        'assignedClassIds': assignedClasses,
      }, SetOptions(merge: true));
    }
  }

  // ==================== Student Assignment ====================

  /// Assign a student to a class
  Future<void> assignStudentToClass({
    required String studentId,
    required String classId,
  }) async {
    final classDoc = await _firestore.collection('classes').doc(classId).get();
    if (!classDoc.exists) throw Exception('Class not found');

    final classData = classDoc.data()!;
    final batchId = classData['batchId'] as String;
    final levelId = classData['levelId'] as String;
    final termId = classData['termId'] as String;
    final sectionName = classData['sectionName'] as String;

    // Update student record
    await _firestore.collection('users').doc(studentId).update({
      'batchId': batchId,
      'levelId': levelId,
      'termId': termId,
      'sectionName': sectionName,
      'classIds': FieldValue.arrayUnion([classId]),
    });
  }

  /// Stream of students in a class
  Stream<List<Map<String, dynamic>>> streamStudentsByClass(String classId) {
    return _firestore
        .collection('users')
        .where('classIds', arrayContains: classId)
        .where('role', isEqualTo: 'student')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => {'id': doc.id, ...doc.data()})
            .toList());
  }

  /// Stream of ALL students
  Stream<List<Map<String, dynamic>>> streamStudents() {
    return _firestore
        .collection('users')
        .where('role', isEqualTo: 'student')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => {'id': doc.id, ...doc.data()})
            .toList());
  }

  /// Remove a student from a class
  Future<void> removeStudentFromClass({
    required String studentId,
    required String classId,
  }) async {
    await _firestore.collection('users').doc(studentId).update({
      'classIds': FieldValue.arrayRemove([classId]),
    });
  }

  // ==================== Teacher Management ====================

  /// Stream of all teachers
  Stream<List<Map<String, dynamic>>> streamTeachers() {
    return _firestore
        .collection('users')
        .where('role', isEqualTo: 'teacher')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => {'id': doc.id, ...doc.data()})
            .toList());
  }

  /// Get teacher's assigned classes
  Future<List<Map<String, dynamic>>> getTeacherClasses(String teacherId) async {
    final teacherDoc = await _firestore.collection('users').doc(teacherId).get();
    if (!teacherDoc.exists) return [];

    final teacherData = teacherDoc.data() ?? {};
    final classIds = List<String>.from(teacherData['assignedClassIds'] ?? <String>[]);
    List<Map<String, dynamic>> classes = [];

    for (final classId in classIds) {
      final classDoc = await _firestore.collection('classes').doc(classId).get();
      if (classDoc.exists) {
        classes.add({'id': classId, ...classDoc.data()!});
      }
    }

    return classes;
  }

  // ==================== Mission Assignment (Teacher-Scoped) ====================

  /// Create a mission assigned by a teacher to a class
  /// This replaces the global mission system for teacher-assigned work
  Future<String> createTeacherMission({
    required String teacherId,
    required String classId,
    required String title,
    required String description,
    required int xp,
    required DateTime dueDate,
    required String instructions,
    String type = 'daily',
    String difficulty = 'medium',
  }) async {
    final missionRef = _firestore.collection('missions').doc();
    
    await missionRef.set({
      'teacherId': teacherId,
      'classId': classId,
      'title': title,
      'desc': description,
      'type': type,
      'difficulty': difficulty,
      'xp': xp,
      'dueDate': dueDate,
      'instructions': instructions,
      'createdAt': FieldValue.serverTimestamp(),
    });

    return missionRef.id;
  }

  /// Stream missions for a specific class
  Stream<List<Map<String, dynamic>>> streamClassMissions(String classId) {
    return _firestore
        .collection('missions')
        .where('classId', isEqualTo: classId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => {'id': doc.id, ...doc.data()})
            .toList());
  }

  /// Stream missions assigned by a teacher
  Stream<List<Map<String, dynamic>>> streamTeacherMissions(String teacherId) {
    return _firestore
        .collection('missions')
        .where('teacherId', isEqualTo: teacherId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => {'id': doc.id, ...doc.data()})
            .toList());
  }

  /// Stream total missions count (all missions ever created)
  Stream<int> streamMissionsCount() {
    return _firestore
        .collection('missions')
        .snapshots()
        .map((snap) => snap.size);
  }

  // ==================== Student Performance Tracking ====================

  /// Record student attendance for a class
  Future<void> recordAttendance({
    required String studentId,
    required String classId,
    required DateTime date,
    required bool isPresent,
  }) async {
    final attendanceRef = _firestore
        .collection('users')
        .doc(studentId)
        .collection('attendance')
        .doc(classId);

    final doc = await attendanceRef.get();
    final records = doc.exists
        ? List<Map<String, dynamic>>.from(doc.get('records') ?? [])
        : <Map<String, dynamic>>[];

    records.add({
      'date': date,
      'isPresent': isPresent,
    });

    await attendanceRef.set({'records': records});
  }

  /// Get student marks for a class
  Stream<Map<String, dynamic>> streamStudentMarks(
      String studentId, String classId) {
    return _firestore
        .collection('users')
        .doc(studentId)
        .collection('marks')
        .doc(classId)
        .snapshots()
        .map((snapshot) =>
            snapshot.exists ? snapshot.data() ?? {} : {});
  }

  /// Record student marks in a class (for a test/assignment)
  Future<void> recordMarks({
    required String studentId,
    required String classId,
    required String assessmentName,
    required double marksObtained,
    required double totalMarks,
  }) async {
    final marksRef = _firestore
        .collection('users')
        .doc(studentId)
        .collection('marks')
        .doc(classId);

    final doc = await marksRef.get();
    final assessments =
        Map<String, dynamic>.from(doc.exists ? doc.data() ?? {} : {});

    assessments[assessmentName] = {
      'obtained': marksObtained,
      'total': totalMarks,
      'percentage': (marksObtained / totalMarks * 100).toStringAsFixed(2),
      'recordedAt': FieldValue.serverTimestamp(),
    };

    await marksRef.set(assessments);
  }

  /// Read a student's marks document for a class once.
  Future<Map<String, dynamic>> getStudentMarks({
    required String studentId,
    required String classId,
  }) async {
    final snapshot = await _firestore
        .collection('users')
        .doc(studentId)
        .collection('marks')
        .doc(classId)
        .get();

    return snapshot.exists ? Map<String, dynamic>.from(snapshot.data() ?? {}) : {};
  }

  /// Create a class-scoped announcement and fan out notifications to students.
  Future<void> createClassAnnouncement({
    required String teacherId,
    required String classId,
    required String title,
    required String message,
  }) async {
    final now = DateTime.now();
    final announcementRef = _firestore.collection('class_announcements').doc();

    await announcementRef.set({
      'teacherId': teacherId,
      'classId': classId,
      'title': title,
      'message': message,
      'createdAt': FieldValue.serverTimestamp(),
      'createdAtMillis': now.millisecondsSinceEpoch,
    });

    final studentsSnapshot = await _firestore
        .collection('users')
        .where('classIds', arrayContains: classId)
        .where('role', isEqualTo: 'student')
        .get();

    if (studentsSnapshot.docs.isEmpty) {
      return;
    }

    final batch = _firestore.batch();
    for (final student in studentsSnapshot.docs) {
      final notifRef = _firestore
          .collection('users')
          .doc(student.id)
          .collection('notifications')
          .doc();

      batch.set(notifRef, {
        'title': title,
        'message': message,
        'classId': classId,
        'teacherId': teacherId,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
        'createdAtMillis': now.millisecondsSinceEpoch,
      });
    }

    await batch.commit();
  }

  Stream<List<Map<String, dynamic>>> streamClassAnnouncements(String classId) {
    return _firestore
        .collection('class_announcements')
        .where('classId', isEqualTo: classId)
        .snapshots()
        .map((snapshot) {
          final announcements = snapshot.docs
              .map((doc) => {'id': doc.id, ...doc.data()})
              .toList();

          announcements.sort((a, b) {
            final aMs = (a['createdAtMillis'] as num?)?.toInt() ?? 0;
            final bMs = (b['createdAtMillis'] as num?)?.toInt() ?? 0;
            return bMs.compareTo(aMs);
          });
          return announcements;
        });
  }

  Stream<List<Map<String, dynamic>>> streamStudentClassQuizzes(List<String> classIds) {
    if (classIds.isEmpty) {
      return Stream.value(const <Map<String, dynamic>>[]);
    }

    final safeClassIds = classIds.take(10).toList();

    return _firestore
        .collection('class_quizzes')
        .where('classId', whereIn: safeClassIds)
        .snapshots()
        .map((snapshot) {
          final quizzes = snapshot.docs
              .map((doc) => {'id': doc.id, ...doc.data()})
              .toList();

          quizzes.sort((a, b) {
            final aTs = a['createdAt'] as Timestamp?;
            final bTs = b['createdAt'] as Timestamp?;
            final aMs = aTs?.millisecondsSinceEpoch ?? 0;
            final bMs = bTs?.millisecondsSinceEpoch ?? 0;
            return bMs.compareTo(aMs);
          });

          return quizzes;
        });
  }

  // ==================== Teacher Quiz / Exam ====================

  Future<String> createClassQuiz({
    required String teacherId,
    required String classId,
    required String title,
    required String description,
    required int rewardXp,
    required int timeLimitMinutes,
    required String type,
  }) async {
    final now = DateTime.now();
    final quizRef = _firestore.collection('class_quizzes').doc();
    await quizRef.set({
      'teacherId': teacherId,
      'classId': classId,
      'title': title,
      'description': description,
      'rewardXp': rewardXp,
      'timeLimitMinutes': timeLimitMinutes,
      'type': type,
      'createdAt': FieldValue.serverTimestamp(),
      'createdAtMillis': now.millisecondsSinceEpoch,
    });

    final studentsSnapshot = await _firestore
        .collection('users')
        .where('classIds', arrayContains: classId)
        .where('role', isEqualTo: 'student')
        .get();

    if (studentsSnapshot.docs.isNotEmpty) {
      final batch = _firestore.batch();
      for (final student in studentsSnapshot.docs) {
        final notifRef = _firestore
            .collection('users')
            .doc(student.id)
            .collection('notifications')
            .doc();

        batch.set(notifRef, {
          'title': 'New Quiz: $title',
          'message': description,
          'classId': classId,
          'teacherId': teacherId,
          'kind': 'quiz',
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
          'createdAtMillis': now.millisecondsSinceEpoch,
        });
      }
      await batch.commit();
    }

    return quizRef.id;
  }

  Stream<List<Map<String, dynamic>>> streamClassQuizzes(String classId) {
    return _firestore
        .collection('class_quizzes')
        .where('classId', isEqualTo: classId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => {'id': doc.id, ...doc.data()})
            .toList());
  }

  // ==================== Teacher Chat / Discussion ====================

  Future<void> sendClassMessage({
    required String classId,
    required String senderId,
    required String senderRole,
    required String message,
  }) async {
    final text = message.trim();
    if (text.isEmpty) return;

    await _firestore.collection('class_messages').add({
      'classId': classId,
      'senderId': senderId,
      'senderRole': senderRole,
      'message': text,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<Map<String, dynamic>>> streamClassMessages(String classId) {
    return _firestore
        .collection('class_messages')
        .where('classId', isEqualTo: classId)
        .snapshots()
        .map((snapshot) {
          final messages = snapshot.docs
              .map((doc) => {'id': doc.id, ...doc.data()})
              .toList();

          messages.sort((a, b) {
            final aTs = a['createdAt'] as Timestamp?;
            final bTs = b['createdAt'] as Timestamp?;
            final aMs = aTs?.millisecondsSinceEpoch ?? 0;
            final bMs = bTs?.millisecondsSinceEpoch ?? 0;
            return bMs.compareTo(aMs);
          });

          return messages.take(100).toList();
        });
  }

  // ==================== Teacher Game Events ====================

  Future<String> createGameEvent({
    required String teacherId,
    required String classId,
    required String title,
    required String description,
    required int rewardXp,
    required String badge,
    required DateTime eventDate,
  }) async {
    final eventRef = _firestore.collection('game_events').doc();
    await eventRef.set({
      'teacherId': teacherId,
      'classId': classId,
      'title': title,
      'description': description,
      'rewardXp': rewardXp,
      'badge': badge,
      'eventDate': Timestamp.fromDate(eventDate),
      'winnerStudentId': null,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return eventRef.id;
  }

  Stream<List<Map<String, dynamic>>> streamClassGameEvents(String classId) {
    return _firestore
        .collection('game_events')
        .where('classId', isEqualTo: classId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => {'id': doc.id, ...doc.data()})
            .toList());
  }

  // ==================== Admin Promotion ====================

  /// Promote a teacher to admin role
  Future<void> promoteToAdmin(String userId) async {
    await _firestore.collection('users').doc(userId).update({
      'role': 'admin',
      'promotedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Demote an admin to teacher
  Future<void> demoteAdminToTeacher(String userId) async {
    await _firestore.collection('users').doc(userId).update({
      'role': 'teacher',
    });
  }

  // ==================== XP Rules Settings ====================

  Future<Map<String, dynamic>> getXpSettings() async {
    final doc = await _firestore.collection('app_settings').doc('xp_rules').get();
    if (!doc.exists) {
      return Map<String, dynamic>.from(defaultXpSettings);
    }

    final data = doc.data() ?? {};
    final merged = Map<String, dynamic>.from(defaultXpSettings);
    merged.addAll(data);

    final defaultAssessment =
        Map<String, dynamic>.from(defaultXpSettings['assessmentBaseXp'] as Map<String, dynamic>);
    final savedAssessment = Map<String, dynamic>.from(data['assessmentBaseXp'] ?? {});
    defaultAssessment.addAll(savedAssessment);
    merged['assessmentBaseXp'] = defaultAssessment;

    return merged;
  }

  Stream<Map<String, dynamic>> streamXpSettings() {
    return _firestore.collection('app_settings').doc('xp_rules').snapshots().map((snapshot) {
      if (!snapshot.exists) {
        return Map<String, dynamic>.from(defaultXpSettings);
      }

      final data = snapshot.data() ?? {};
      final merged = Map<String, dynamic>.from(defaultXpSettings);
      merged.addAll(data);

      final defaultAssessment =
          Map<String, dynamic>.from(defaultXpSettings['assessmentBaseXp'] as Map<String, dynamic>);
      final savedAssessment = Map<String, dynamic>.from(data['assessmentBaseXp'] ?? {});
      defaultAssessment.addAll(savedAssessment);
      merged['assessmentBaseXp'] = defaultAssessment;

      return merged;
    });
  }

  Future<void> updateXpSettings({
    required int attendancePresentXp,
    required int attendanceAbsentPenalty,
    required Map<String, int> assessmentBaseXp,
    required double performanceDropPenaltyMultiplier,
    required int performanceDropPenaltyCapPercent,
  }) async {
    await _firestore.collection('app_settings').doc('xp_rules').set({
      'attendancePresentXp': attendancePresentXp,
      'attendanceAbsentPenalty': attendanceAbsentPenalty,
      'assessmentBaseXp': assessmentBaseXp,
      'performanceDropPenaltyMultiplier': performanceDropPenaltyMultiplier,
      'performanceDropPenaltyCapPercent': performanceDropPenaltyCapPercent,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}

// ==================== Riverpod Providers ====================

final adminServiceProvider = Provider<AdminService>((ref) {
  return AdminService(FirebaseFirestore.instance);
});

final batchesProvider =
    StreamProvider<List<Map<String, dynamic>>>((ref) {
  final service = ref.watch(adminServiceProvider);
  return service.streamBatches();
});

final levelsProvider =
    StreamProvider<List<Map<String, dynamic>>>((ref) {
  final service = ref.watch(adminServiceProvider);
  return service.streamLevels();
});

final termsProvider =
    StreamProvider<List<Map<String, dynamic>>>((ref) {
  final service = ref.watch(adminServiceProvider);
  return service.streamTerms();
});

final teachersProvider =
    StreamProvider<List<Map<String, dynamic>>>((ref) {
  final service = ref.watch(adminServiceProvider);
  return service.streamTeachers();
});

final classesByLevelTermProvider = StreamProvider.family<
    List<Map<String, dynamic>>,
    ({String batchId, String levelId, String termId})>((ref, params) {
  final service = ref.watch(adminServiceProvider);
  return service.streamClassesByLevelTerm(
    batchId: params.batchId,
    levelId: params.levelId,
    termId: params.termId,
  );
});

final classesProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  final service = ref.watch(adminServiceProvider);
  return service.streamClasses();
});

final studentsProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  final service = ref.watch(adminServiceProvider);
  return service.streamStudents();
});

final missionsCountProvider = StreamProvider<int>((ref) {
  final service = ref.watch(adminServiceProvider);
  return service.streamMissionsCount();
});

final studentsByClassProvider =
    StreamProvider.family<List<Map<String, dynamic>>, String>((ref, classId) {
  final service = ref.watch(adminServiceProvider);
  return service.streamStudentsByClass(classId);
});

final xpSettingsProvider = StreamProvider<Map<String, dynamic>>((ref) {
  final service = ref.watch(adminServiceProvider);
  return service.streamXpSettings();
});
