import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationModel {
  final String id;
  final String type; // interested / removed_interest
  final String fromUid;
  final String fromName;
  final String postId;
  final String postTitle;
  final Timestamp? createdAt;
  final bool read;

  NotificationModel({
    required this.id,
    required this.type,
    required this.fromUid,
    required this.fromName,
    required this.postId,
    required this.postTitle,
    this.createdAt,
    this.read = false,
  });

  factory NotificationModel.fromDoc(DocumentSnapshot doc) {
    final map = doc.data() as Map<String, dynamic>;
    return NotificationModel(
      id: doc.id,
      type: map['type'] ?? '',
      fromUid: map['fromUid'] ?? '',
      fromName: map['fromName'] ?? '',
      postId: map['postId'] ?? '',
      postTitle: map['postTitle'] ?? '',
      createdAt: map['createdAt'],
      read: map['read'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'fromUid': fromUid,
      'fromName': fromName,
      'postId': postId,
      'postTitle': postTitle,
      'createdAt': FieldValue.serverTimestamp(),
      'read': read,
    };
  }

  String get message {
    if (type == kNotifInterestedType) {
      return '$fromName is interested in your post "$postTitle"';
    } else if (type == 'post_rented') {
      return 'Your interested post "$postTitle" has been marked as Rented';
    } else if (type == 'rent_available') {
      return 'Good news! "$postTitle" is available for rent again';
    }
    return 'You have a new notification';
  }

  static const kNotifInterestedType = 'interested';
}
