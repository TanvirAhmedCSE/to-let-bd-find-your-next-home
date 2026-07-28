import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../controllers/auth/auth_controller.dart';
import '../../controllers/home/home_controller.dart';
import '../../utils/constants.dart';
import 'home_screen.dart';
import '../search/search_screen.dart';
import '../profile/profile_screen.dart';
import '../chat/chat_list_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _index = 0;

  final List<Widget> _tabs = const [
    HomeScreen(),
    SearchScreen(),
    ChatListScreen(),
    ProfileScreen(),
  ];

  Widget _navItem({
    required IconData icon,
    required IconData activeIcon,
    required bool selected,
    required VoidCallback onTap,
    Stream<int>? countStream,
  }) {
    final iconWidget = Icon(
      selected ? activeIcon : icon,
      color: selected ? AppColors.primary : Colors.white70,
      size: 22,
    );

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: countStream == null
            ? iconWidget
            : StreamBuilder<int>(
                stream: countStream,
                builder: (context, snapshot) {
                  final count = snapshot.data ?? 0;
                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      iconWidget,
                      if (count > 0)
                        Positioned(
                          right: -6,
                          top: -4,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 1,
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 16,
                              minHeight: 16,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.accent,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: AppColors.primaryDark,
                                width: 1.5,
                              ),
                            ),
                            child: Text(
                              count > 99 ? '99+' : '$count',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = context.watch<AuthController>().currentUser!.uid;
    final homeController = context.watch<HomeController>();

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarDividerColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.dark,

        systemNavigationBarContrastEnforced: false,
        statusBarColor: Colors.transparent,

        statusBarIconBrightness: Brightness.dark, // Android
        statusBarBrightness: Brightness.light, // iOS
      ),
      child: Scaffold(
        backgroundColor: AppColors.background,
        extendBody: true,
        body: IndexedStack(index: _index, children: _tabs),
        bottomNavigationBar: IgnorePointer(
          ignoring: _index == 0 && !homeController.navBarVisible,
          child: AnimatedSlide(
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
            offset: (_index == 0 && !homeController.navBarVisible)
                ? const Offset(0, 2)
                : Offset.zero,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 500),
              opacity: (_index == 0 && !homeController.navBarVisible) ? 0 : 1,
              child: SafeArea(
                minimum: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                child: Container(
                  height: 64,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: AppColors.primaryDark,
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryDark.withValues(alpha: 0.35),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _navItem(
                        icon: Icons.home_outlined,
                        activeIcon: Icons.home_rounded,
                        selected: _index == 0,
                        onTap: () => setState(() => _index = 0),
                      ),
                      _navItem(
                        icon: Icons.search_outlined,
                        activeIcon: Icons.search_rounded,
                        selected: _index == 1,
                        onTap: () => setState(() => _index = 1),
                      ),
                      _navItem(
                        icon: Icons.chat_bubble_outline_rounded,
                        activeIcon: Icons.chat_bubble_rounded,
                        selected: _index == 2,
                        onTap: () => setState(() => _index = 2),
                        countStream: homeController.totalUnreadCountStream(uid),
                      ),
                      _navItem(
                        icon: Icons.person_outline_rounded,
                        activeIcon: Icons.person_rounded,
                        selected: _index == 3,
                        onTap: () => setState(() => _index = 3),
                        countStream: homeController
                            .unreadNotificationsCountStream(uid),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
