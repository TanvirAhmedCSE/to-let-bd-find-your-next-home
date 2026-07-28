import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:onesignal_flutter/onesignal_flutter.dart';

class NotificationService {
  static const String _appId = 'REPLACE_IT';
  static const String _restApiKey =
      'REPLACE_IT';

  static Future<void> init() async {
    OneSignal.initialize(_appId);
    await OneSignal.Notifications.requestPermission(true);
  }

  static Future<void> loginUser(String uid) async {
    await OneSignal.login(uid);
  }

  static Future<void> logoutUser() async {
    await OneSignal.logout();
  }

  // To the post owner, when a seeker marks the post "Interested".
  static Future<void> sendInterestedNotification({
    required String uploaderUid,
    required String seekerName,
    required String postTitle,
    required String postId,
    required String notifId,
  }) async {
    await _sendPush(
      targetUids: [uploaderUid],
      heading: 'New Interest',
      content: '$seekerName is interested in your post "$postTitle"',
      data: {'postId': postId, 'notifId': notifId},
    );
  }

  // To every interested seeker, when the owner marks the post Rented.
  static Future<void> sendPostRentedNotification({
    required List<String> seekerUids,
    required String postTitle,
    required String postId,
    required String notifId,
  }) async {
    if (seekerUids.isEmpty) return;
    await _sendPush(
      targetUids: seekerUids,
      heading: 'Post Rented',
      content: 'Your interested post "$postTitle" has been marked as Rented',
      data: {'postId': postId, 'notifId': notifId},
    );
  }

  // To every interested seeker, when the owner marks the post Available again.
  static Future<void> sendRentAvailableNotification({
    required List<String> seekerUids,
    required String postTitle,
    required String postId,
    required String notifId,
  }) async {
    if (seekerUids.isEmpty) return;
    await _sendPush(
      targetUids: seekerUids,
      heading: 'Rent Available Again',
      content: 'Good news! "$postTitle" is available for rent again',
      data: {'postId': postId, 'notifId': notifId},
    );
  }

  static Future<void> _sendPush({
    required List<String> targetUids,
    required String heading,
    required String content,
    required Map<String, dynamic> data,
  }) async {
    try {
      await http.post(
        Uri.parse('https://onesignal.com/api/v1/notifications'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Key $_restApiKey',
        },
        body: jsonEncode({
          'app_id': _appId,
          'include_aliases': {'external_id': targetUids},
          'target_channel': 'push',
          'headings': {'en': heading},
          'contents': {'en': content},
          'data': data,
        }),
      );
    } catch (e) {
      // silent fail
    }
  }
}
