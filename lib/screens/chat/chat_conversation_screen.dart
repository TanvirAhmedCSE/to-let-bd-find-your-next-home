import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/chat/chat_conversation_screen_controller.dart';
import '../../models/chat_model.dart';
import '../../models/post_model.dart';
import '../../utils/constants.dart';
import '../post/full_screen_image_viewer.dart';
import '../post/post_detail_screen.dart';

class ChatConversationScreen extends StatelessWidget {
  final String chatId;
  final String otherUid;
  final String otherName;
  final String postId;
  final String postTitle;
  final String postImageUrl;

  const ChatConversationScreen({
    super.key,
    required this.chatId,
    required this.otherUid,
    required this.otherName,
    required this.postId,
    required this.postTitle,
    required this.postImageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ChatConversationScreenController(
        chatId: chatId,
        otherUid: otherUid,
        otherName: otherName,
      ),
      child: _ChatConversationScreenView(
        postId: postId,
        postTitle: postTitle,
        postImageUrl: postImageUrl,
      ),
    );
  }
}

class _ChatConversationScreenView extends StatefulWidget {
  final String postId;
  final String postTitle;
  final String postImageUrl;

  const _ChatConversationScreenView({
    required this.postId,
    required this.postTitle,
    required this.postImageUrl,
  });

  @override
  State<_ChatConversationScreenView> createState() =>
      _ChatConversationScreenViewState();
}

class _ChatConversationScreenViewState
    extends State<_ChatConversationScreenView> {
  static const double _headerHeight = 68;

  final ScrollController _scrollController = ScrollController();

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 200), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send(ChatConversationScreenController controller) async {
    final sent = await controller.send();
    if (sent) _scrollToBottom();
  }

  Future<void> _pickAndSendImages(
    ChatConversationScreenController controller,
  ) async {
    final sent = await controller.pickAndSendImages();
    if (!mounted) return;
    if (sent) {
      _scrollToBottom();
    } else if (controller.errorMessage != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(controller.errorMessage!)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ChatConversationScreenController>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(controller.otherName),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: StreamBuilder<ChatModel?>(
        stream: controller.firestoreService.chatStream(controller.chatId),
        builder: (context, chatSnapshot) {
          final chat = chatSnapshot.data;
          final messagingEnabled = chat?.messagingEnabled ?? true;
          final statusText = chat != null ? controller.statusText(chat) : '';
          final postDeleted = chat?.postDeleted ?? false;
          final showComposer = messagingEnabled && !postDeleted;

          return Stack(
            children: [
              Positioned.fill(
                child: StreamBuilder<List<MessageModel>>(
                  stream: controller.firestoreService.messagesStream(
                    controller.chatId,
                  ),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                      );
                    }
                    final messages = snapshot.data ?? [];
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (_scrollController.hasClients) {
                        _scrollController.jumpTo(
                          _scrollController.position.maxScrollExtent,
                        );
                      }
                    });

                    final items = <_TimelineItem>[
                      for (final m in messages)
                        _TimelineItem.message(
                          m,
                          m.createdAt?.toDate() ?? DateTime.now(),
                        ),
                      if (statusText.isNotEmpty)
                        _TimelineItem.status(
                          chat?.statusEventTime?.toDate() ?? DateTime.now(),
                        ),
                    ]..sort((a, b) => a.time.compareTo(b.time));

                    return ListView.builder(
                      controller: _scrollController,
                      padding: EdgeInsets.fromLTRB(
                        12,
                        _headerHeight + 12,
                        12,
                        showComposer ? 70 : 16,
                      ),
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final item = items[index];

                        if (item.isStatus) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryLight,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  statusText,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          );
                        }

                        final msg = item.message!;
                        final isMe = msg.senderId == controller.myUid;
                        final hasImage =
                            msg.imageUrl != null && msg.imageUrl!.isNotEmpty;

                        return Align(
                          alignment: isMe
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            padding: hasImage
                                ? const EdgeInsets.all(4)
                                : const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 10,
                                  ),
                            constraints: BoxConstraints(
                              maxWidth:
                                  MediaQuery.of(context).size.width * 0.65,
                            ),
                            decoration: BoxDecoration(
                              color: isMe
                                  ? AppColors.primary
                                  : AppColors.surface,
                              borderRadius: BorderRadius.only(
                                topLeft: const Radius.circular(14),
                                topRight: const Radius.circular(14),
                                bottomLeft: Radius.circular(isMe ? 14 : 4),
                                bottomRight: Radius.circular(isMe ? 4 : 14),
                              ),
                              border: isMe
                                  ? null
                                  : Border.all(color: AppColors.border),
                            ),
                            child: hasImage
                                ? GestureDetector(
                                    onTap: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => FullScreenImageViewer(
                                            images: [
                                              PostImage(
                                                url: msg.imageUrl!,
                                                publicId: '',
                                              ),
                                            ],
                                            initialIndex: 0,
                                          ),
                                        ),
                                      );
                                    },
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: Image.network(
                                        msg.imageUrl!,
                                        width: 200,
                                        fit: BoxFit.cover,
                                        loadingBuilder:
                                            (context, child, progress) {
                                              if (progress == null)
                                                return child;
                                              return const SizedBox(
                                                width: 200,
                                                height: 200,
                                                child: Center(
                                                  child:
                                                      CircularProgressIndicator(
                                                        color:
                                                            AppColors.primary,
                                                      ),
                                                ),
                                              );
                                            },
                                      ),
                                    ),
                                  )
                                : Text(
                                    msg.text,
                                    style: TextStyle(
                                      color: isMe
                                          ? Colors.white
                                          : AppColors.textPrimary,
                                      fontSize: 14.5,
                                    ),
                                  ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),

              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: _headerHeight,
                child: Material(
                  elevation: 2,
                  color: postDeleted ? AppColors.divider : AppColors.surface,
                  child: InkWell(
                    onTap: postDeleted
                        ? null
                        : () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    PostDetailScreen(postId: widget.postId),
                              ),
                            );
                          },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: postDeleted
                                ? Image.asset(
                                    'assets/images/deleted_poster.png',
                                    width: 48,
                                    height: 48,
                                    fit: BoxFit.cover,
                                  )
                                : widget.postImageUrl.isNotEmpty
                                ? Image.network(
                                    widget.postImageUrl,
                                    width: 48,
                                    height: 48,
                                    fit: BoxFit.cover,
                                  )
                                : Container(
                                    width: 48,
                                    height: 48,
                                    color: AppColors.primaryLight,
                                    child: const Icon(
                                      Icons.home_outlined,
                                      color: AppColors.primary,
                                    ),
                                  ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              widget.postTitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          if (!postDeleted)
                            const Icon(
                              Icons.chevron_right_rounded,
                              color: AppColors.textMuted,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              if (showComposer)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: SafeArea(
                    top: false,
                    child: Container(
                      color: AppColors.surface,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 8,
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            icon: controller.uploadingImage
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.primary,
                                    ),
                                  )
                                : const Icon(
                                    Icons.image_outlined,
                                    color: AppColors.primary,
                                  ),
                            onPressed: controller.uploadingImage
                                ? null
                                : () => _pickAndSendImages(controller),
                          ),
                          Expanded(
                            child: TextField(
                              controller: controller.textController,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Type a message...',
                                hintStyle: const TextStyle(
                                  color: AppColors.textMuted,
                                ),
                                filled: true,
                                fillColor: AppColors.background,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 10,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(24),
                                  borderSide: BorderSide.none,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(24),
                                  borderSide: BorderSide.none,
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(24),
                                  borderSide: const BorderSide(
                                    color: AppColors.primary,
                                    width: 1.4,
                                  ),
                                ),
                              ),
                              onSubmitted: (_) => _send(controller),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              icon: const Icon(
                                Icons.send_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                              onPressed: () => _send(controller),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _TimelineItem {
  final MessageModel? message;
  final bool isStatus;
  final DateTime time;

  _TimelineItem.message(this.message, this.time) : isStatus = false;
  _TimelineItem.status(this.time) : message = null, isStatus = true;
}
