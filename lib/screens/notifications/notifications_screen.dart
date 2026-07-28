import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/notifications/notifications_screen_controller.dart';
import '../../models/notification_model.dart';
import '../../utils/constants.dart';
import '../chat/chat_conversation_screen.dart';
import '../post/post_detail_screen.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => NotificationsScreenController(),
      child: const _NotificationsScreenView(),
    );
  }
}

class _NotificationsScreenView extends StatelessWidget {
  const _NotificationsScreenView();

  Future<void> _handleInterestedTap(
    BuildContext context,
    NotificationsScreenController controller,
    NotificationModel notif,
  ) async {
    final resolved = await controller.resolveInterestedChat(notif);
    if (!context.mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChatConversationScreen(
          chatId: resolved.chatId,
          otherUid: notif.fromUid,
          otherName: notif.fromName,
          postId: resolved.post.id,
          postTitle: resolved.post.title,
          postImageUrl: resolved.post.images.isNotEmpty
              ? resolved.post.images.first.url
              : '',
        ),
      ),
    );
  }

  void _handlePostStatusTap(BuildContext context, NotificationModel notif) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => PostDetailScreen(postId: notif.postId)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<NotificationsScreenController>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: StreamBuilder<List<NotificationModel>>(
        stream: controller.notificationsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }
          final notifications = snapshot.data ?? [];
          if (notifications.isEmpty) {
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
                      Icons.notifications_none_rounded,
                      size: 36,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No notifications yet',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Updates about your posts and\nchats will show up here',
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
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notif = notifications[index];
              final isInterested = notif.type == kNotifInterested;
              final isRented = notif.type == kNotifPostRented;
              final isAvailable = notif.type == kNotifRentAvailable;

              final IconData icon = isInterested
                  ? Icons.favorite_rounded
                  : isRented
                  ? Icons.home_work_rounded
                  : isAvailable
                  ? Icons.check_circle_rounded
                  : Icons.favorite_border_rounded;

              final Color iconColor = isInterested
                  ? AppColors.accent
                  : isRented
                  ? AppColors.warning
                  : isAvailable
                  ? AppColors.success
                  : AppColors.textMuted;

              final String subtitleText = isInterested
                  ? 'Tap to chat'
                  : (isRented || isAvailable)
                  ? 'Tap to view post'
                  : '';

              final VoidCallback? onTap = isInterested
                  ? () => _handleInterestedTap(context, controller, notif)
                  : (isRented || isAvailable)
                  ? () => _handlePostStatusTap(context, notif)
                  : null;

              final Color cardColor = notif.read
                  ? AppColors.surface
                  : AppColors.divider;

              return InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: onTap,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
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
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: iconColor.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(icon, color: iconColor, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              notif.message,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w600,
                                fontSize: 13.5,
                                height: 1.3,
                              ),
                            ),
                            if (subtitleText.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                subtitleText,
                                style: const TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (onTap != null) ...[
                        const SizedBox(width: 6),
                        const Icon(
                          Icons.chevron_right_rounded,
                          color: AppColors.textMuted,
                          size: 20,
                        ),
                      ],
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
