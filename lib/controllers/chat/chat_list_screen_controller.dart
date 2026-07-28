import 'package:flutter/material.dart';
import '../../models/chat_model.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';

class ChatListScreenController extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();

  String get myUid => _authService.currentUser!.uid;

  Stream<List<ChatModel>> get chatListStream =>
      _firestoreService.chatListStream(myUid);

  // Only show chats that actually have a message yet
  List<ChatModel> applyFilter(List<ChatModel> chats) {
    return chats.where((c) => c.lastMessage.isNotEmpty).toList();
  }
}
