import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../controllers/post/post_detail_screen_controller.dart';
import '../../models/post_model.dart';
import '../../utils/constants.dart';
import '../chat/chat_conversation_screen.dart';
import '../home/main_screen.dart';
import 'edit_post_screen.dart';
import 'full_screen_image_viewer.dart';

class PostDetailScreen extends StatelessWidget {
  final String postId;

  final bool fromNotification;

  const PostDetailScreen({
    super.key,
    required this.postId,
    this.fromNotification = false,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => PostDetailScreenController(postId),
      child: _PostDetailScreenView(fromNotification: fromNotification),
    );
  }
}

class _PostDetailScreenView extends StatefulWidget {
  final bool fromNotification;
  const _PostDetailScreenView({required this.fromNotification});

  @override
  State<_PostDetailScreenView> createState() => _PostDetailScreenViewState();
}

class _PostDetailScreenViewState extends State<_PostDetailScreenView> {
  final PageController _pageController = PageController();
  int _currentImageIndex = 0;

  void _goHome() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const MainScreen()),
      (route) => false,
    );
  }

  Future<void> _openChat(PostDetailScreenController controller) async {
    final chatId = await controller.openChat();
    if (!mounted) return;
    final post = controller.post!;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChatConversationScreen(
          chatId: chatId,
          otherUid: post.uploaderUid,
          otherName: post.uploaderName,
          postId: post.id,
          postTitle: post.title,
          postImageUrl: post.images.isNotEmpty ? post.images.first.url : '',
        ),
      ),
    );
  }

  Future<void> _deletePost(PostDetailScreenController controller) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Delete Post',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: const Text(
          'This will permanently delete this post and its images.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
            ),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    final success = await controller.deletePost();
    if (!mounted) return;
    if (success) {
      widget.fromNotification ? _goHome() : Navigator.of(context).pop();
    }
  }

  void _showInterestedPeople(
    PostDetailScreenController controller,
    PostModel post,
  ) {
    final screenContext = context;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Interested People',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: controller.firestoreService.interestedUsersStream(post.id),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox(
                  height: 80,
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                );
              }
              final people = snapshot.data ?? [];
              if (people.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'No one has shown interest yet',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                );
              }
              return ListView.separated(
                shrinkWrap: true,
                itemCount: people.length,
                separatorBuilder: (_, __) =>
                    const Divider(height: 1, color: AppColors.divider),
                itemBuilder: (context, index) {
                  final personName =
                      people[index]['seekerName'] as String? ?? 'Seeker';
                  final seekerUid = people[index]['seekerUid'] as String? ?? '';
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: AppColors.primaryLight,
                      child: Text(
                        personName.isNotEmpty
                            ? personName[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    title: Text(
                      personName,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    trailing: const Icon(
                      Icons.chat_bubble_outline_rounded,
                      color: AppColors.accent,
                    ),
                    onTap: () async {
                      Navigator.pop(ctx);
                      final chatId = await controller.createChatWithSeeker(
                        seekerUid: seekerUid,
                        seekerName: personName,
                      );
                      if (!mounted) return;
                      Navigator.of(screenContext).push(
                        MaterialPageRoute(
                          builder: (_) => ChatConversationScreen(
                            chatId: chatId,
                            otherUid: seekerUid,
                            otherName: personName,
                            postId: post.id,
                            postTitle: post.title,
                            postImageUrl: post.images.isNotEmpty
                                ? post.images.first.url
                                : '',
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            style: TextButton.styleFrom(foregroundColor: AppColors.primary),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _statPill(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<PostDetailScreenController>();

    if (controller.loading || controller.post == null) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    final post = controller.post!;
    final isOwner = controller.isOwner;

    return PopScope(
      canPop: !widget.fromNotification,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && widget.fromNotification) {
          _goHome();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text(post.title, overflow: TextOverflow.ellipsis),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          leading: widget.fromNotification
              ? IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: _goHome,
                )
              : null,
          actions: isOwner
              ? [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => EditPostScreen(post: post),
                        ),
                      );
                      controller.load();
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded),
                    onPressed: controller.busy
                        ? null
                        : () => _deletePost(controller),
                  ),
                ]
              : null,
        ),
        body: controller.busy
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              )
            : ListView(
                padding: EdgeInsets.zero,
                children: [
                  SizedBox(
                    height: 280,
                    child: post.images.isEmpty
                        ? Container(color: AppColors.primaryLight)
                        : Stack(
                            children: [
                              PageView.builder(
                                controller: _pageController,
                                itemCount: post.images.length,
                                onPageChanged: (index) {
                                  setState(() => _currentImageIndex = index);
                                },
                                itemBuilder: (context, index) => GestureDetector(
                                  onTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => FullScreenImageViewer(
                                          images: post.images,
                                          initialIndex: index,
                                        ),
                                      ),
                                    );
                                  },
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      Image.network(
                                        post.images[index].url,
                                        fit: BoxFit.cover,
                                      ),
                                      if (post.status != kStatusActive)
                                        Positioned(
                                          top: 12,
                                          left: 12,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 5,
                                            ),
                                            decoration: BoxDecoration(
                                              color: AppColors.error,
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: const Text(
                                              'Rented',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                        ),
                                      if (post.images.length > 1)
                                        Positioned(
                                          top: 12,
                                          right: 12,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 5,
                                            ),
                                            decoration: BoxDecoration(
                                              color: AppColors.primaryDark,
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              '${_currentImageIndex + 1}/${post.images.length}',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                        ),
                                      Positioned(
                                        right: 10,
                                        bottom: 30,
                                        child: Container(
                                          padding: const EdgeInsets.all(7),
                                          decoration: const BoxDecoration(
                                            color: AppColors.primaryDark,
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.fullscreen_rounded,
                                            color: Colors.white,
                                            size: 20,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              if (post.images.length > 1)
                                Positioned(
                                  bottom: 34,
                                  left: 0,
                                  right: 0,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: List.generate(
                                      post.images.length,
                                      (index) {
                                        final isSelected =
                                            index == _currentImageIndex;
                                        return AnimatedContainer(
                                          duration: const Duration(
                                            milliseconds: 200,
                                          ),
                                          margin: const EdgeInsets.symmetric(
                                            horizontal: 3,
                                          ),
                                          width: isSelected ? 9 : 6,
                                          height: 6,
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                              3,
                                            ),
                                            color: isSelected
                                                ? Colors.white
                                                : const Color(0xFFCFCFCF),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                            ],
                          ),
                  ),

                  Transform.translate(
                    offset: const Offset(0, -18),
                    child: Container(
                      decoration: const BoxDecoration(
                        color: AppColors.background,
                      ),
                      padding: const EdgeInsets.fromLTRB(20, 22, 20, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(post.title, style: AppTextStyles.heading),
                          const SizedBox(height: 6),
                          Text(
                            '৳ ${post.rent.toStringAsFixed(0)} / month',
                            style: const TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w800,
                              color: AppColors.accent,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on_outlined,
                                size: 16,
                                color: AppColors.textMuted,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  '${post.area}, ${post.thana}, ${post.district}, ${post.division}',
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 13.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              if (post.bedrooms > 0)
                                _statPill(
                                  Icons.bed_outlined,
                                  '${post.bedrooms} Bed',
                                ),
                              if (post.bathrooms > 0)
                                _statPill(
                                  Icons.bathtub_outlined,
                                  '${post.bathrooms} Bath',
                                ),
                              _statPill(
                                Icons.home_work_outlined,
                                post.propertyType,
                              ),
                            ],
                          ),
                          const SizedBox(height: 22),

                          if (post.availableFrom != null) ...[
                            const Text(
                              'Available From',
                              style: AppTextStyles.sectionTitle,
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(
                                  Icons.calendar_today_rounded,
                                  size: 15,
                                  color: AppColors.accent,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  DateFormat('d MMMM, y').format(
                                    post.availableFrom!.toDate().toLocal(),
                                  ),
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13.5,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 22),
                          ],

                          const Text(
                            'Description',
                            style: AppTextStyles.sectionTitle,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            post.description,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 14,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 22),

                          if (post.facilities.isNotEmpty) ...[
                            const Text(
                              'Facilities',
                              style: AppTextStyles.sectionTitle,
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: post.facilities
                                  .map(
                                    (f) => Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 7,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.surface,
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: AppColors.border,
                                        ),
                                      ),
                                      child: Text(
                                        f,
                                        style: const TextStyle(
                                          color: AppColors.textPrimary,
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                            const SizedBox(height: 22),
                          ],

                          const Text(
                            'Owner',
                            style: AppTextStyles.sectionTitle,
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 16,
                                backgroundColor: AppColors.primaryLight,
                                child: Text(
                                  post.uploaderName.isNotEmpty
                                      ? post.uploaderName[0].toUpperCase()
                                      : '?',
                                  style: const TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                post.uploaderName,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),

                          if (isOwner) ...[
                            if (post.status == kStatusActive) ...[
                              InkWell(
                                onTap: () =>
                                    _showInterestedPeople(controller, post),
                                borderRadius: BorderRadius.circular(10),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.accentLight,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.people_alt_outlined,
                                        size: 17,
                                        color: AppColors.accent,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '${post.interestedCount} people interested',
                                        style: const TextStyle(
                                          color: AppColors.accentDark,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 14),
                            ],
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: OutlinedButton.icon(
                                onPressed: controller.toggleRented,
                                style: OutlinedButton.styleFrom(
                                  backgroundColor: post.status == kStatusActive
                                      ? Colors.red
                                      : Colors.green,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  side: post.status == kStatusActive
                                      ? const BorderSide(color: Colors.red)
                                      : const BorderSide(color: Colors.green),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                icon: Icon(
                                  post.status == kStatusActive
                                      ? Icons.check_circle_outline_rounded
                                      : Icons.undo_rounded,
                                ),
                                label: Text(
                                  post.status == kStatusActive
                                      ? 'Mark as Rented'
                                      : 'Mark as Available',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                          ] else ...[
                            if (post.status == kStatusActive)
                              Row(
                                children: [
                                  Expanded(
                                    flex: controller.interested ? 3 : 1,
                                    child: SizedBox(
                                      height: 50,
                                      child: OutlinedButton.icon(
                                        onPressed: controller.toggleInterest,
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: AppColors.accent,
                                          side: const BorderSide(
                                            color: AppColors.accent,
                                          ),
                                          padding: EdgeInsets.symmetric(
                                            horizontal: controller.interested
                                                ? 14
                                                : 8,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                        ),
                                        icon: Icon(
                                          controller.interested
                                              ? Icons.favorite_rounded
                                              : Icons.favorite_border_rounded,
                                        ),
                                        label: Text(
                                          controller.interested
                                              ? 'Remove Interested'
                                              : 'Interested',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    flex: controller.interested ? 2 : 1,
                                    child: SizedBox(
                                      height: 50,
                                      child: ElevatedButton.icon(
                                        onPressed: () => _openChat(controller),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.primary,
                                          foregroundColor: Colors.white,
                                          elevation: 0,
                                          padding: EdgeInsets.symmetric(
                                            horizontal: controller.interested
                                                ? 4
                                                : 8,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                        ),
                                        icon: const Icon(
                                          Icons.chat_bubble_outline_rounded,
                                        ),
                                        label: const Text(
                                          'Chat',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            else if (controller.interested)
                              SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: OutlinedButton.icon(
                                  onPressed: controller.toggleInterest,
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.accent,
                                    side: const BorderSide(
                                      color: AppColors.accent,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  icon: const Icon(Icons.favorite_rounded),
                                  label: const Text(
                                    'Remove Interested',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            const SizedBox(height: 10),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
