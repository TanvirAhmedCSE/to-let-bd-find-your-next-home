import 'package:cloud_firestore/cloud_firestore.dart';

class ChatModel {
  final String id;
  final List<String> participants;
  final Map<String, String> participantNames;
  final String lastMessage;
  final Timestamp? lastMessageTime;
  final Map<String, int> unread;

  // per-post chat fields
  final String postId;
  final String postTitle;
  final String postImageUrl;
  final String uploaderUid;
  final String seekerUid;
  final Timestamp? statusEventTime;

  // rented/available system notification + message lock
  final bool messagingEnabled;
  final String? statusEventType; // 'rented' | 'available' | null

  final bool postDeleted;

  ChatModel({
    required this.id,
    required this.participants,
    required this.participantNames,
    required this.lastMessage,
    this.lastMessageTime,
    required this.unread,
    this.postId = '',
    this.postTitle = '',
    this.postImageUrl = '',
    this.uploaderUid = '',
    this.seekerUid = '',
    this.messagingEnabled = true,
    this.statusEventType,
    this.statusEventTime,
    this.postDeleted = false,
  });

  factory ChatModel.fromDoc(DocumentSnapshot doc) {
    final map = doc.data() as Map<String, dynamic>;
    return ChatModel(
      id: doc.id,
      participants: List<String>.from(map['participants'] ?? []),
      participantNames: Map<String, String>.from(map['participantNames'] ?? {}),
      lastMessage: map['lastMessage'] ?? '',
      lastMessageTime: map['lastMessageTime'],
      unread: Map<String, int>.from(map['unread'] ?? {}),
      postId: map['postId'] ?? '',
      postTitle: map['postTitle'] ?? '',
      postImageUrl: map['postImageUrl'] ?? '',
      uploaderUid: map['uploaderUid'] ?? '',
      seekerUid: map['seekerUid'] ?? '',
      messagingEnabled: map['messagingEnabled'] ?? true,
      statusEventType: map['statusEventType'],
      statusEventTime: map['statusEventTime'],
      postDeleted: map['postDeleted'] ?? false,
    );
  }

  String otherUserName(String myUid) {
    final otherUid = participants.firstWhere(
      (u) => u != myUid,
      orElse: () => '',
    );
    return participantNames[otherUid] ?? 'User';
  }

  String otherUserUid(String myUid) {
    return participants.firstWhere((u) => u != myUid, orElse: () => '');
  }
}

class MessageModel {
  final String id;
  final String senderId;
  final String text;
  final String? imageUrl;
  final Timestamp? createdAt;
  final bool seen;

  MessageModel({
    required this.id,
    required this.senderId,
    required this.text,
    this.imageUrl,
    this.createdAt,
    this.seen = false,
  });

  factory MessageModel.fromDoc(DocumentSnapshot doc) {
    final map = doc.data() as Map<String, dynamic>;
    return MessageModel(
      id: doc.id,
      senderId: map['senderId'] ?? '',
      text: map['text'] ?? '',
      imageUrl: map['imageUrl'],
      createdAt: map['createdAt'],
      seen: map['seen'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'text': text,
      'imageUrl': imageUrl,
      'createdAt': FieldValue.serverTimestamp(),
      'seen': false,
    };
  }
}
