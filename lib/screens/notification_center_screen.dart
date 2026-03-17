import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import '../services/notifications_service.dart';

class NotificationCenterScreen extends ConsumerWidget {
  const NotificationCenterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsStreamProvider);
    final notifications = ref.watch(notificationsProvider);
    final unreadCount = ref.watch(unreadNotificationCountProvider);
    final notificationsService = ref.read(notificationsServiceProvider);

    return Scaffold(
      backgroundColor: AppTheme.bgColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Notifications', style: GoogleFonts.poppins(fontSize: 20)),
        actions: [
          if (unreadCount > 0)
            TextButton(
              onPressed: () async {
                await notificationsService.markAllAsRead();
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('All notifications marked as read.')),
                );
              },
              child: const Text('Mark all read', style: TextStyle(color: AppTheme.studentAccent)),
            )
        ],
        elevation: 0,
        backgroundColor: AppTheme.cardColor,
      ),
      body: notificationsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Text(
            'Failed to load notifications: $error',
            style: GoogleFonts.poppins(color: AppTheme.textGray),
          ),
        ),
        data: (_) => notifications.isEmpty
            ? Center(
                child: Text(
                  'No notifications',
                  style: GoogleFonts.poppins(color: AppTheme.textGray),
                ),
              )
            : ListView.separated(
              padding: const EdgeInsets.all(24.0),
              itemCount: notifications.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final notif = notifications[index];

                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.cardColor,
                    border: Border.all(color: notif.isRead ? const Color(0xFF1F2937) : AppTheme.studentAccent, width: notif.isRead ? 1 : 2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.studentAccent,
                        ),
                        child: const Icon(LucideIcons.bell, color: Colors.white),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    notif.title,
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      decoration: notif.isRead ? TextDecoration.none : null,
                                    ),
                                  ),
                                ),
                                if (!notif.isRead)
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: AppTheme.studentAccent,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              notif.message,
                              style: const TextStyle(color: AppTheme.textGray, fontSize: 13),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  notif.timestamp,
                                  style: const TextStyle(color: Colors.white54, fontSize: 11),
                                ),
                                Row(
                                  children: [
                                    if (!notif.isRead)
                                      GestureDetector(
                                        onTap: () async {
                                          await notificationsService.markAsRead(notif.id);
                                        },
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 8),
                                          child: Text(
                                            'Mark read',
                                            style: GoogleFonts.poppins(
                                              fontSize: 10,
                                              color: AppTheme.studentAccent,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ),
                                    GestureDetector(
                                      onTap: () async {
                                        await notificationsService.deleteNotification(notif.id);
                                        if (!context.mounted) return;
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Notification deleted')),
                                        );
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 8),
                                        child: Text(
                                          'Delete',
                                          style: GoogleFonts.poppins(
                                            fontSize: 10,
                                            color: Colors.red,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                );
              },
            ),
      ),
    );
  }
}
