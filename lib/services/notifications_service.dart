import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AppNotification {
  final String id;
  final String title;
  final String message;
  final String timestamp;
  final String icon;
  final List<double> color;
  final bool isRead;

  const AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.timestamp,
    required this.icon,
    required this.color,
    this.isRead = false,
  });
}

final notificationsServiceProvider = Provider<NotificationsService>((ref) {
  return NotificationsService();
});

class NotificationsService {
  FirebaseAuth get _auth => FirebaseAuth.instance;
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  Stream<List<AppNotification>> streamNotifications() {
    if (!kIsWeb && Platform.isLinux) {
      return const Stream<List<AppNotification>>.empty();
    }

    final user = _auth.currentUser;
    if (user == null) {
      return Stream.value(const <AppNotification>[]);
    }

    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('notifications')
        .orderBy('createdAtMillis', descending: true)
        .limit(80)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map((doc) {
            final data = doc.data();
            return AppNotification(
              id: doc.id,
              title: data['title']?.toString() ?? 'Notification',
              message: data['message']?.toString() ?? '',
              timestamp: _toRelativeTime(data['createdAtMillis']),
              icon: data['icon']?.toString() ?? 'bell',
              color: _readColorList(data['color']),
              isRead: data['isRead'] == true,
            );
          }).toList(),
        );
  }

  Future<void> markAsRead(String notificationId) async {
    if (!kIsWeb && Platform.isLinux) return;
    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('notifications')
        .doc(notificationId)
        .set({'isRead': true}, SetOptions(merge: true));
  }

  Future<void> markAllAsRead() async {
    if (!kIsWeb && Platform.isLinux) return;
    final user = _auth.currentUser;
    if (user == null) return;

    final snapshot = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('notifications')
        .where('isRead', isEqualTo: false)
        .get();

    if (snapshot.docs.isEmpty) return;

    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      batch.set(doc.reference, {'isRead': true}, SetOptions(merge: true));
    }
    await batch.commit();
  }

  Future<void> deleteNotification(String notificationId) async {
    if (!kIsWeb && Platform.isLinux) return;
    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('notifications')
        .doc(notificationId)
        .delete();
  }

  static List<double> _readColorList(Object? value) {
    if (value is List) {
      return value
          .whereType<num>()
          .map((number) => number.toDouble())
          .toList();
    }
    return const [59, 130, 246];
  }

  static String _toRelativeTime(Object? millisValue) {
    if (millisValue is! num) return 'now';

    final now = DateTime.now();
    final then = DateTime.fromMillisecondsSinceEpoch(millisValue.toInt());
    final diff = now.difference(then);

    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

final notificationsStreamProvider = StreamProvider<List<AppNotification>>((ref) {
  return ref.watch(notificationsServiceProvider).streamNotifications();
});

final notificationsProvider = Provider<List<AppNotification>>((ref) {
  final asyncNotifications = ref.watch(notificationsStreamProvider);
  return asyncNotifications.maybeWhen(
    data: (items) => items,
    orElse: () => const <AppNotification>[],
  );
});

final unreadNotificationCountProvider = Provider<int>((ref) {
  final notifications = ref.watch(notificationsProvider);
  return notifications.where((item) => !item.isRead).length;
});
