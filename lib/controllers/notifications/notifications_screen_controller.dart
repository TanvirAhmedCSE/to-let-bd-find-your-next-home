import 'package:flutter/material.dart';
import '../../models/notification_model.dart';
import '../../models/post_model.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';

class NotificationsScreenController extends ChangeNotifier {
  final FirestoreService firestoreService = FirestoreService();
  final AuthService _authService = AuthService();

  String get myUid => _authService.currentUser!.uid;

  Stream<List<NotificationModel>> get notificationsStream =>
      firestoreService.notificationsStream(myUid);

  Future<({String chatId, PostModel post})> resolveInterestedChat(
    NotificationModel notif,
  ) async {
    final post = await firestoreService.getPost(notif.postId);
    final user = _authService.currentUser!;
    final chatId = await firestoreService.getOrCreateChat(
      postId: post.id,
      postTitle: post.title,
      postImageUrl: post.images.isNotEmpty ? post.images.first.url : '',
      uploaderUid: myUid,
      uploaderName: user.displayName ?? user.email ?? 'User',
      seekerUid: notif.fromUid,
      seekerName: notif.fromName,
    );
    return (chatId: chatId, post: post);
  }

  @override
  void dispose() {
    firestoreService.markAllNotificationsRead(myUid);
    super.dispose();
  }
}
