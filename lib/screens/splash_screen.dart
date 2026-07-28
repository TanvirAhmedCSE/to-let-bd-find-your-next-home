import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/auth/auth_controller.dart';
import 'auth/login_screen.dart';
import 'auth/verify_email_screen.dart';
import 'home/main_screen.dart';
import 'post/post_detail_screen.dart';
import '../main.dart';
import '../utils/constants.dart';
import '../services/notification_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    final auth = context.read<AuthController>();
    final user = auth.currentUser;
    if (user == null) {
      splashNavigationDone = true;
      pendingNotificationPostId = null;
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
      return;
    }

    final verified = await auth.checkVerificationStatus();
    if (!mounted) return;

    if (!verified) {
      splashNavigationDone = true;
      pendingNotificationPostId = null;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const VerifyEmailScreen()),
      );
    } else {
      await NotificationService.loginUser(user.uid);
      splashNavigationDone = true;
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const MainScreen()));

      final pendingPostId = pendingNotificationPostId;
      if (pendingPostId != null) {
        pendingNotificationPostId = null;
        navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (_) =>
                PostDetailScreen(postId: pendingPostId, fromNotification: true),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.home_work_rounded,
                size: 50,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'To-Let BD',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Find your next home, easily',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.75),
                fontSize: 13.5,
              ),
            ),
            const SizedBox(height: 32),
            const SizedBox(
              width: 26,
              height: 26,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
