import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/post/interested_posts_screen_controller.dart';
import '../../utils/constants.dart';
import '../../widgets/post_card.dart';
import 'post_detail_screen.dart';

class InterestedPostsScreen extends StatelessWidget {
  const InterestedPostsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => InterestedPostsScreenController(),
      child: const _InterestedPostsScreenView(),
    );
  }
}

class _InterestedPostsScreenView extends StatelessWidget {
  const _InterestedPostsScreenView();

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<InterestedPostsScreenController>();
    final posts = controller.posts;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Interested Posts'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: posts == null
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : posts.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: AppColors.accentLight,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.favorite_rounded,
                      size: 32,
                      color: AppColors.accent,
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'No interested posts yet',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              color: AppColors.primary,
              onRefresh: controller.load,
              child: GridView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: posts.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.75,
                ),
                itemBuilder: (context, index) {
                  final post = posts[index];
                  return PostCard(
                    post: post,
                    showCategoryBadge: true,
                    onTap: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => PostDetailScreen(postId: post.id),
                        ),
                      );
                      controller.load();
                    },
                  );
                },
              ),
            ),
    );
  }
}
