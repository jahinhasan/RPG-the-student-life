import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DemoSeedResult {
  final int users;
  final int missions;
  final int quizzes;
  final int battleQuestions;

  const DemoSeedResult({
    required this.users,
    required this.missions,
    required this.quizzes,
    required this.battleQuestions,
  });
}

class DevSeedService {
  final FirebaseFirestore _firestore;

  DevSeedService(this._firestore);

  Future<DemoSeedResult> seedDemoData() async {
    final now = DateTime.now();
    final classId = 'class_demo_2024_l1_t1_a';
    final teacherId = 'demo_teacher_1';

    final students = <Map<String, dynamic>>[
      {
        'id': 'demo_student_1',
        'name': 'Arian Hasan',
        'email': 'demo.student1@baust.edu.bd',
        'playstyle': 'fighter',
        'xp': 780,
        'wins': 8,
        'losses': 4,
      },
      {
        'id': 'demo_student_2',
        'name': 'Nafisa Karim',
        'email': 'demo.student2@baust.edu.bd',
        'playstyle': 'scholar',
        'xp': 640,
        'wins': 5,
        'losses': 3,
      },
      {
        'id': 'demo_student_3',
        'name': 'Sajid Rahman',
        'email': 'demo.student3@baust.edu.bd',
        'playstyle': 'explorer',
        'xp': 520,
        'wins': 4,
        'losses': 5,
      },
      {
        'id': 'demo_student_4',
        'name': 'Mitu Akter',
        'email': 'demo.student4@baust.edu.bd',
        'playstyle': 'tactical',
        'xp': 460,
        'wins': 3,
        'losses': 6,
      },
      {
        'id': 'demo_student_5',
        'name': 'Rafi Ahmed',
        'email': 'demo.student5@baust.edu.bd',
        'playstyle': 'scholar',
        'xp': 900,
        'wins': 10,
        'losses': 2,
      },
    ];

    final battleQuestions = <Map<String, dynamic>>[
      {
        'id': 'demo_bq_1',
        'question': 'What is the derivative of x^2?',
        'options': ['x', '2x', 'x^2', '2'],
        'correctIndex': 1,
        'category': 'Math',
      },
      {
        'id': 'demo_bq_2',
        'question': 'Which data structure uses FIFO?',
        'options': ['Stack', 'Queue', 'Tree', 'Graph'],
        'correctIndex': 1,
        'category': 'CS',
      },
      {
        'id': 'demo_bq_3',
        'question': 'Binary of decimal 10 is?',
        'options': ['1001', '1010', '1100', '1110'],
        'correctIndex': 1,
        'category': 'CS',
      },
      {
        'id': 'demo_bq_4',
        'question': 'Integral of 1/x is?',
        'options': ['ln x', 'x', '1/x^2', 'e^x'],
        'correctIndex': 0,
        'category': 'Math',
      },
      {
        'id': 'demo_bq_5',
        'question': 'OSI layer for routing?',
        'options': ['Transport', 'Network', 'Data Link', 'Session'],
        'correctIndex': 1,
        'category': 'Networking',
      },
      {
        'id': 'demo_bq_6',
        'question': 'Time complexity of binary search?',
        'options': ['O(n)', 'O(log n)', 'O(n log n)', 'O(1)'],
        'correctIndex': 1,
        'category': 'Algorithms',
      },
    ];

    final missions = <Map<String, dynamic>>[
      {
        'id': 'demo_mission_daily_1',
        'title': 'Daily: Solve 5 Differentiation Problems',
        'desc': 'Complete five calculus differentiation tasks.',
        'type': 'daily',
        'xp': 60,
      },
      {
        'id': 'demo_mission_weekly_1',
        'title': 'Weekly: Build Queue Simulator',
        'desc': 'Implement queue operations and show output screenshots.',
        'type': 'weekly',
        'xp': 140,
      },
      {
        'id': 'demo_mission_achievement_1',
        'title': 'Achievement: 3 Arena Wins',
        'desc': 'Win 3 battle arena matches this week.',
        'type': 'achievement',
        'xp': 220,
      },
    ];

    final quizzes = <Map<String, dynamic>>[
      {
        'id': 'demo_quiz_1',
        'title': 'Calculus CT Practice',
        'description': '15 MCQ on limit and derivative fundamentals.',
        'rewardXp': 80,
        'timeLimitMinutes': 20,
        'type': 'ct',
      },
      {
        'id': 'demo_quiz_2',
        'title': 'Data Structures Quick Test',
        'description': 'Queue, stack, linked list basics.',
        'rewardXp': 70,
        'timeLimitMinutes': 15,
        'type': 'class_performance',
      },
    ];

    final batch = _firestore.batch();

    batch.set(_firestore.collection('batches').doc('batch_2024'), {
      'year': 2024,
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    batch.set(_firestore.collection('levels').doc('level_1'), {
      'levelNumber': 1,
      'levelName': 'First Year',
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    batch.set(_firestore.collection('terms').doc('term_1'), {
      'termName': 'Term 1',
      'termNumber': 1,
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    batch.set(_firestore.collection('classes').doc(classId), {
      'batchId': 'batch_2024',
      'levelId': 'level_1',
      'termId': 'term_1',
      'sectionName': 'A',
      'assignedTeacherIds': [teacherId],
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    batch.set(_firestore.collection('users').doc(teacherId), {
      'name': 'Dr. Seed Teacher',
      'email': 'demo.teacher@baust.edu.bd',
      'role': 'teacher',
      'department': 'CSE',
      'universityId': 'T-DEMO-001',
      'assignedClassIds': [classId],
      'createdAt': FieldValue.serverTimestamp(),
      'lastActive': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    for (final student in students) {
      final studentId = student['id'] as String;
      batch.set(_firestore.collection('users').doc(studentId), {
        'name': student['name'],
        'email': student['email'],
        'role': 'student',
        'studentId': studentId.toUpperCase(),
        'department': 'CSE',
        'batch': '18',
        'section': 'A',
        'term': '1',
        'academicLevel': '1',
        'batchId': 'batch_2024',
        'levelId': 'level_1',
        'termId': 'term_1',
        'sectionName': 'A',
        'classIds': [classId],
        'playstyle': student['playstyle'],
        'xp': student['xp'],
        'coins': (student['xp'] as int) ~/ 10,
        'wins': student['wins'],
        'losses': student['losses'],
        'onboardingCompleted': true,
        'createdAt': FieldValue.serverTimestamp(),
        'lastActive': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      batch.set(_firestore.collection('game_profiles').doc(studentId), {
        'arena_rank': 'bronze',
        'quiz_score': 50 + (student['xp'] as int) % 50,
        'exploration_progress': 20 + (student['wins'] as int) * 5,
        'survival_kills': student['wins'],
        'wins': student['wins'],
        'losses': student['losses'],
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      batch.set(_firestore.collection('users').doc(studentId).collection('attendance').doc(classId), {
        'records': [
          {'date': Timestamp.fromDate(now.subtract(const Duration(days: 2))), 'isPresent': true},
          {'date': Timestamp.fromDate(now.subtract(const Duration(days: 1))), 'isPresent': true},
          {'date': Timestamp.fromDate(now), 'isPresent': (student['wins'] as int).isEven},
        ],
      }, SetOptions(merge: true));

      batch.set(_firestore.collection('users').doc(studentId).collection('marks').doc(classId), {
        'ct_1': {
          'obtained': 16,
          'total': 20,
          'percentage': '80.00',
          'recordedAt': FieldValue.serverTimestamp(),
        },
        'class_performance_1': {
          'obtained': 18,
          'total': 25,
          'percentage': '72.00',
          'recordedAt': FieldValue.serverTimestamp(),
        },
      }, SetOptions(merge: true));

      batch.set(_firestore.collection('users').doc(studentId).collection('notifications').doc('demo_notif_1'), {
        'title': 'Welcome to Demo Semester',
        'message': 'Seed data loaded. Start with Daily Mission and Battle Arena.',
        'classId': classId,
        'teacherId': teacherId,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
        'createdAtMillis': now.millisecondsSinceEpoch,
      }, SetOptions(merge: true));

      batch.set(_firestore.collection('users').doc(studentId).collection('notifications').doc('demo_notif_2'), {
        'title': 'Quiz Available',
        'message': 'Calculus CT Practice quiz is live now.',
        'classId': classId,
        'teacherId': teacherId,
        'kind': 'quiz',
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
        'createdAtMillis': now.subtract(const Duration(hours: 1)).millisecondsSinceEpoch,
      }, SetOptions(merge: true));
    }

    for (final question in battleQuestions) {
      batch.set(_firestore.collection('battle_questions').doc(question['id'] as String), {
        'question': question['question'],
        'options': question['options'],
        'correctIndex': question['correctIndex'],
        'category': question['category'],
      }, SetOptions(merge: true));
    }

    for (final mission in missions) {
      batch.set(_firestore.collection('missions').doc(mission['id'] as String), {
        'title': mission['title'],
        'desc': mission['desc'],
        'type': mission['type'],
        'xp': mission['xp'],
        'progress': 0,
        'teacherId': teacherId,
        'teacherName': 'Dr. Seed Teacher',
        'classId': classId,
        'courseName': 'CSE Fundamentals',
        'courseCode': 'CSE-101',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }

    for (final quiz in quizzes) {
      batch.set(_firestore.collection('class_quizzes').doc(quiz['id'] as String), {
        'teacherId': teacherId,
        'classId': classId,
        'title': quiz['title'],
        'description': quiz['description'],
        'rewardXp': quiz['rewardXp'],
        'timeLimitMinutes': quiz['timeLimitMinutes'],
        'type': quiz['type'],
        'createdAt': FieldValue.serverTimestamp(),
        'createdAtMillis': now.millisecondsSinceEpoch,
      }, SetOptions(merge: true));
    }

    batch.set(_firestore.collection('class_announcements').doc('demo_announcement_1'), {
      'teacherId': teacherId,
      'classId': classId,
      'title': 'Demo Week Started',
      'message': 'Complete mission, play quiz, and test Unity launch flow.',
      'createdAt': FieldValue.serverTimestamp(),
      'createdAtMillis': now.millisecondsSinceEpoch,
    }, SetOptions(merge: true));

    batch.set(_firestore.collection('app_settings').doc('xp_rules'), {
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
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    // mark one mission as completed for one student to test claimed state.
    batch.set(
      _firestore
          .collection('users')
          .doc('demo_student_1')
          .collection('completedMissions')
          .doc('demo_mission_daily_1'),
      {
        'completedAt': FieldValue.serverTimestamp(),
        'xpAwarded': 60,
      },
      SetOptions(merge: true),
    );

    await batch.commit();

    return DemoSeedResult(
      users: students.length + 1,
      missions: missions.length,
      quizzes: quizzes.length,
      battleQuestions: battleQuestions.length,
    );
  }
}

final devSeedServiceProvider = Provider<DevSeedService>((ref) {
  return DevSeedService(FirebaseFirestore.instance);
});
