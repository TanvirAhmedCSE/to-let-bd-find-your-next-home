import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:provider/provider.dart';
import 'controllers/auth/auth_controller.dart';
import 'controllers/home/home_controller.dart';
import 'screens/splash_screen.dart';
import 'screens/post/post_detail_screen.dart';
import 'services/auth_service.dart';
import 'services/firestore_service.dart';
import 'services/notification_service.dart';
import 'utils/constants.dart';
import 'firebase_options.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

bool splashNavigationDone = false;
String? pendingNotificationPostId;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await NotificationService.init();

  OneSignal.Notifications.addClickListener((event) {
    final postId = event.notification.additionalData?['postId'] as String?;
    final notifId = event.notification.additionalData?['notifId'] as String?;
    if (postId == null) return;

    final uid = AuthService().currentUser?.uid;
    if (uid != null && notifId != null) {
      FirestoreService().markNotificationRead(uid, notifId);
    }

    if (!splashNavigationDone) {
      pendingNotificationPostId = postId;
      return;
    }

    navigatorKey.currentState?.push(
      MaterialPageRoute(
        builder: (_) =>
            PostDetailScreen(postId: postId, fromNotification: true),
      ),
    );
  });

  runApp(const ToLetBdApp());
}

class ToLetBdApp extends StatelessWidget {
  const ToLetBdApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthController()),
        ChangeNotifierProvider(create: (_) => HomeController()),
      ],
      child: MaterialApp(
        navigatorKey: navigatorKey,
        title: 'To-Let BD',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          primaryColor: AppColors.primary,
          scaffoldBackgroundColor: AppColors.background,
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppColors.primary,
            primary: AppColors.primary,
            secondary: AppColors.accent,
            error: AppColors.error,
            surface: AppColors.surface,
          ),
          fontFamily: 'Roboto',
          textTheme: const TextTheme(
            headlineSmall: AppTextStyles.heading,
            titleMedium: AppTextStyles.sectionTitle,
            bodyMedium: TextStyle(color: AppColors.textPrimary, fontSize: 14),
            bodySmall: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12.5,
            ),
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            centerTitle: false,
            titleTextStyle: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          outlinedButtonTheme: OutlinedButtonThemeData(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(foregroundColor: AppColors.accent),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: AppColors.surface,
            contentPadding: const EdgeInsets.symmetric(
              vertical: 16,
              horizontal: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppColors.primary,
                width: 1.6,
              ),
            ),
            labelStyle: const TextStyle(color: AppColors.textSecondary),
          ),
          chipTheme: ChipThemeData(
            backgroundColor: AppColors.primaryLight,
            selectedColor: AppColors.primary,
            labelStyle: const TextStyle(color: AppColors.primary),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          dividerColor: AppColors.divider,
          bottomNavigationBarTheme: const BottomNavigationBarThemeData(
            backgroundColor: AppColors.surface,
            selectedItemColor: AppColors.primary,
            unselectedItemColor: AppColors.textMuted,
            type: BottomNavigationBarType.fixed,
            elevation: 0,
          ),
        ),
        home: const SplashScreen(),
      ),
    );
  }
}
