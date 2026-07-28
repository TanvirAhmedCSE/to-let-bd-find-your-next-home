import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/chat/chat_list_screen_controller.dart';
import '../../models/chat_model.dart';
import '../../utils/constants.dart';
import 'chat_conversation_screen.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ChatListScreenController(),
      child: const _ChatListScreenView(),
    );
  }
}

class _ChatListScreenView extends StatelessWidget {
  const _ChatListScreenView();

  String _formatTime(dynamic timestamp) {
    if (timestamp == null) return '';
    final date = timestamp.toDate().toLocal();
    final now = DateTime.now();
    final isToday =
        date.year == now.year && date.month == now.month && date.day == now.day;
    final yesterday = now.subtract(const Duration(days: 1));
    final isYesterday =
        date.year == yesterday.year &&
        date.month == yesterday.month &&
        date.day == yesterday.day;

    if (isToday) return DateFormat('hh:mm a').format(date);
    if (isYesterday) return 'Yesterday';
    return DateFormat('MMM d').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ChatListScreenController>();
    final uid = controller.myUid;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Chats'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: StreamBuilder<List<ChatModel>>(
        stream: controller.chatListStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }
          final chats = controller.applyFilter(snapshot.data ?? []);
          if (chats.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 84,
                    height: 84,
                    decoration: const BoxDecoration(
                      color: AppColors.primaryLight,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.chat_bubble_outline_rounded,
                      size: 36,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No conversations yet',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Messages with owners and seekers\nwill show up here',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12.5,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 100),
            itemCount: chats.length,
            itemBuilder: (context, index) {
              final chat = chats[index];
              final otherName = chat.otherUserName(uid);
              final otherUid = chat.otherUserUid(uid);
              final unreadCount = chat.unread[uid] ?? 0;
              final hasUnread = unreadCount > 0;
              final isPhoto = chat.lastMessage == '📷 Photo';

              return InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ChatConversationScreen(
                        chatId: chat.id,
                        otherUid: otherUid,
                        otherName: otherName,
                        postId: chat.postId,
                        postTitle: chat.postTitle,
                        postImageUrl: chat.postImageUrl,
                      ),
                    ),
                  );
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: hasUnread
                          ? AppColors.primary.withValues(alpha: 0.25)
                          : AppColors.border,
                      width: hasUnread ? 1.2 : 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryDark.withValues(alpha: 0.05),
                        blurRadius: 12,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: hasUnread
                                ? AppColors.accent
                                : AppColors.divider,
                            width: hasUnread ? 2 : 1,
                          ),
                        ),
                        child: SizedBox(
                          width: 52,
                          height: 52,
                          child: chat.postDeleted
                              ? ClipOval(
                                  child: Image.asset(
                                    'assets/images/deleted_poster.png',
                                    width: 52,
                                    height: 52,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : chat.postImageUrl.isNotEmpty
                              ? ClipOval(
                                  child: Image.network(
                                    chat.postImageUrl,
                                    width: 52,
                                    height: 52,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : CircleAvatar(
                                  radius: 26,
                                  backgroundColor: AppColors.primaryLight,
                                  child: Text(
                                    otherName.isNotEmpty
                                        ? otherName[0].toUpperCase()
                                        : '?',
                                    style: const TextStyle(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 18,
                                    ),
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    otherName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontWeight: hasUnread
                                          ? FontWeight.w800
                                          : FontWeight.w700,
                                      color: AppColors.textPrimary,
                                      fontSize: 14.5,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _formatTime(chat.lastMessageTime),
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: hasUnread
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color: hasUnread
                                        ? AppColors.accent
                                        : AppColors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                            if (chat.postTitle.isNotEmpty) ...[
                              const SizedBox(height: 3),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.home_work_outlined,
                                    size: 12,
                                    color: AppColors.textMuted,
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      chat.postTitle,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 11.5,
                                        color: AppColors.textMuted,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                if (isPhoto && unreadCount <= 1)
                                  const Padding(
                                    padding: EdgeInsets.only(right: 4),
                                    child: Icon(
                                      Icons.camera_alt_rounded,
                                      size: 14,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                Expanded(
                                  child: Text(
                                    hasUnread
                                        ? (unreadCount == 1
                                              ? (isPhoto
                                                    ? 'Photo'
                                                    : chat.lastMessage)
                                              : '$unreadCount new messages')
                                        : (isPhoto
                                              ? 'Photo'
                                              : chat.lastMessage),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: hasUnread
                                          ? AppColors.primary
                                          : AppColors.textSecondary,
                                      fontSize: 13,
                                      fontWeight: hasUnread
                                          ? FontWeight.w800
                                          : FontWeight.w400,
                                    ),
                                  ),
                                ),
                                if (hasUnread) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 7,
                                      vertical: 3,
                                    ),
                                    constraints: const BoxConstraints(
                                      minWidth: 20,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.accent,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      unreadCount > 99 ? '99+' : '$unreadCount',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
