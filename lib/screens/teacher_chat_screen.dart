import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/admin_service.dart';
import '../theme/app_theme.dart';

class TeacherChatScreen extends ConsumerStatefulWidget {
  final String classId;

  const TeacherChatScreen({super.key, required this.classId});

  @override
  ConsumerState<TeacherChatScreen> createState() => _TeacherChatScreenState();
}

class _TeacherChatScreenState extends ConsumerState<TeacherChatScreen> {
  final _msgCtrl = TextEditingController();

  @override
  void dispose() {
    _msgCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgColor,
      appBar: AppBar(
        backgroundColor: AppTheme.cardColor,
        title: Text('Class Discussion', style: GoogleFonts.poppins()),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: ref.read(adminServiceProvider).streamClassMessages(widget.classId),
              builder: (context, snapshot) {
                final messages = snapshot.data ?? const <Map<String, dynamic>>[];
                if (messages.isEmpty) {
                  return Center(
                    child: Text('No messages yet.', style: GoogleFonts.poppins(color: AppTheme.textGray)),
                  );
                }

                return ListView.builder(
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final m = messages[index];
                    final isTeacher = (m['senderRole'] ?? '') == 'teacher';
                    return Align(
                      alignment: isTeacher ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: isTeacher ? AppTheme.studentAccent : AppTheme.cardColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          m['message']?.toString() ?? '',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _msgCtrl,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        hintStyle: const TextStyle(color: AppTheme.textGray),
                        filled: true,
                        fillColor: AppTheme.cardColor,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _send,
                    icon: const Icon(Icons.send, color: Colors.white),
                    style: IconButton.styleFrom(backgroundColor: AppTheme.studentAccent),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _send() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await ref.read(adminServiceProvider).sendClassMessage(
          classId: widget.classId,
          senderId: user.uid,
          senderRole: 'teacher',
          message: _msgCtrl.text,
        );

    _msgCtrl.clear();
  }
}
