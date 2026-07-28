import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/home/home_controller.dart';
import '../../utils/constants.dart';
import '../../widgets/post_card.dart';
import '../post/post_detail_screen.dart';

class BestForYouScreen extends StatelessWidget {
  const BestForYouScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final homeController = context.watch<HomeController>();
    final posts = homeController.bestForYou;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Best for You'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: posts.isEmpty
          ? const Center(
              child: Text(
                'No posts found near your location yet',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            )
          : GridView.builder(
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
                    homeController.load();
                  },
                );
              },
            ),
    );
  }
}
