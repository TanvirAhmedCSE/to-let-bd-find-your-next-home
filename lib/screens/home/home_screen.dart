import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/home/home_controller.dart';
import '../../utils/constants.dart';
import '../../widgets/post_card.dart';
import '../best_for_you/best_for_you_screen.dart';
import '../location/set_location_screen.dart';
import '../post/create_post_screen.dart';
import '../post/post_detail_screen.dart';
import '../search/search_screen.dart';
import 'package:flutter/rendering.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Refresh location + posts + Best For You as soon as the screen
    // mounts (e.g. right after login), instead of waiting for the user
    // to pull-to-refresh manually.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<HomeController>().refresh();
    });
  }

  Widget _buildChip({
    required String label,
    required bool selected,
    required ValueChanged<bool> onSelected,
  }) {
    return GestureDetector(
      onTap: () => onSelected(!selected),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : AppColors.textSecondary,
            fontWeight: FontWeight.w600,
            fontSize: 13.5,
          ),
        ),
      ),
    );
  }

  Future<void> _openSetLocation(
    BuildContext context,
    HomeController homeController,
  ) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SetLocationScreen(
          isUpdateMode: homeController.userLocation != null,
        ),
      ),
    );
    homeController.refreshLocation();
  }

  Widget _header(BuildContext context, HomeController homeController) {
    final location = homeController.userLocation;
    final locationText = location == null
        ? 'Not Set Yet'
        : '${location.thana}, ${location.district}';

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 10, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => _openSetLocation(context, homeController),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // App name
                  const Text(
                    'To-Let BD',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Text(
                        'Location',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w600,
                          fontSize: 11.5,
                        ),
                      ),
                      Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 16,
                        color: AppColors.textMuted,
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.location_on_rounded,
                        size: 16,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          locationText,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.asset(
              'assets/images/to_let_bd_app_logo.png',
              width: 110,
              height: 70,
              fit: BoxFit.cover,
            ),
          ),
        ],
      ),
    );
  }

  // Pill search bar
  Widget _searchBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: () {
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const SearchScreen()));
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: const [
              Icon(Icons.search_rounded, color: AppColors.textMuted),
              SizedBox(width: 10),
              Text(
                'Search flats, rooms, shops...',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final homeController = context.watch<HomeController>();
    final posts = homeController.filteredPosts;
    final bestForYou = homeController.bestForYouPreview;
    final showBestForYou =
        homeController.userLocation != null && bestForYou.isNotEmpty;

    final screenWidth = MediaQuery.of(context).size.width;
    final gridItemWidth = (screenWidth - 16 - 16 - 12) / 2;
    final gridItemHeight = gridItemWidth / 0.75;

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 115),
        child: FloatingActionButton(
          backgroundColor: AppColors.accent,
          foregroundColor: Colors.white,
          onPressed: () async {
            await Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const CreatePostScreen()));
            homeController.load();
          },
          child: const Icon(Icons.add),
        ),
      ),
      body: SafeArea(
        bottom: false,
        // Hides/shows MainScreen's floating bottom nav bar based on
        // scroll direction: scrolling down hides it, scrolling up
        // brings it back (only affects the Home tab).
        child: NotificationListener<UserScrollNotification>(
          onNotification: (notification) {
            final controller = context.read<HomeController>();
            if (notification.direction == ScrollDirection.reverse) {
              controller.setNavBarVisible(false);
            } else if (notification.direction == ScrollDirection.forward) {
              controller.setNavBarVisible(true);
            }
            return false;
          },
          child: RefreshIndicator(
            color: AppColors.primary,
            onRefresh: homeController.refresh,
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _header(context, homeController),
                _searchBar(context),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 24),

                      // Property type chips
                      const Padding(
                        padding: EdgeInsets.only(left: 4, bottom: 12),
                        child: Text(
                          'Categories',
                          style: AppTextStyles.sectionTitle,
                        ),
                      ),
                      SizedBox(
                        height: 42,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: _buildChip(
                                label: 'All',
                                selected: homeController.selectedType == null,
                                onSelected: (_) => homeController.clearType(),
                              ),
                            ),
                            ...kPropertyTypes.map((type) {
                              final selected =
                                  homeController.selectedType == type;
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: _buildChip(
                                  label: type,
                                  selected: selected,
                                  onSelected: (_) =>
                                      homeController.selectType(type),
                                ),
                              );
                            }),
                          ],
                        ),
                      ),

                      if (showBestForYou) ...[
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Best for You',
                              style: AppTextStyles.sectionTitle,
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const BestForYouScreen(),
                                  ),
                                );
                              },
                              style: TextButton.styleFrom(
                                foregroundColor: AppColors.primary,
                                padding: EdgeInsets.zero,
                                minimumSize: const Size(0, 0),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Text(
                                    'See all',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                  Icon(Icons.chevron_right_rounded, size: 18),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: gridItemHeight,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: bestForYou.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(width: 12),
                            itemBuilder: (context, index) {
                              final post = bestForYou[index];
                              return SizedBox(
                                width: gridItemWidth,
                                child: PostCard(
                                  post: post,
                                  showCategoryBadge: true,
                                  onTap: () async {
                                    await Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            PostDetailScreen(postId: post.id),
                                      ),
                                    );
                                    homeController.load();
                                  },
                                ),
                              );
                            },
                          ),
                        ),
                      ],

                      const SizedBox(height: 24),
                      const Text(
                        'Recent Posts',
                        style: AppTextStyles.sectionTitle,
                      ),
                      const SizedBox(height: 12),

                      if (homeController.loading)
                        const Padding(
                          padding: EdgeInsets.all(24),
                          child: Center(
                            child: CircularProgressIndicator(
                              color: AppColors.primary,
                            ),
                          ),
                        )
                      else if (posts.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(24),
                          child: Center(
                            child: Text(
                              'No posts yet',
                              style: TextStyle(color: AppColors.textSecondary),
                            ),
                          ),
                        )
                      else
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: posts.length,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                mainAxisSpacing: 12,
                                crossAxisSpacing: 12,
                                childAspectRatio: 0.75,
                              ),
                          itemBuilder: (context, index) {
                            final post = posts[index];
                            return PostCard(
                              post: post,
                              showCategoryBadge:
                                  homeController.selectedType == null,
                              onTap: () async {
                                await Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        PostDetailScreen(postId: post.id),
                                  ),
                                );
                                homeController.load();
                              },
                            );
                          },
                        ),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
