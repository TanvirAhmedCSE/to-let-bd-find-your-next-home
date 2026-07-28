import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/chat_model.dart';
import '../../services/auth_service.dart';
import '../../services/cloudinary_service.dart';
import '../../services/firestore_service.dart';

class ChatConversationScreenController extends ChangeNotifier {
  final String chatId;
  final String otherUid;
  final String otherName;

  final FirestoreService firestoreService = FirestoreService();
  final CloudinaryService _cloudinaryService = CloudinaryService();
  final AuthService _authService = AuthService();

  final TextEditingController textController = TextEditingController();
  bool uploadingImage = false;

  String get myUid => _authService.currentUser!.uid;

  ChatConversationScreenController({
    required this.chatId,
    required this.otherUid,
    required this.otherName,
  }) {
    firestoreService.resetUnread(chatId, myUid);
  }

  Future<bool> send() async {
    final text = textController.text.trim();
    if (text.isEmpty) return false;
    textController.clear();
    await firestoreService.sendMessage(
      chatId: chatId,
      senderId: myUid,
      otherUid: otherUid,
      text: text,
    );
    return true;
  }

  String? errorMessage;

  Future<bool> pickAndSendImages() async {
    errorMessage = null;
    final picker = ImagePicker();
    final picked = await picker.pickMultiImage(imageQuality: 80);
    if (picked.isEmpty) return false;

    uploadingImage = true;
    notifyListeners();
    try {
      for (final xfile in picked) {
        final result = await _cloudinaryService.uploadImage(File(xfile.path));
        await firestoreService.sendMessage(
          chatId: chatId,
          senderId: myUid,
          otherUid: otherUid,
          text: '',
          imageUrl: result.url,
        );
      }
      return true;
    } catch (e) {
      errorMessage = 'Failed to send image(s): $e';
      return false;
    } finally {
      uploadingImage = false;
      notifyListeners();
    }
  }

  String statusText(ChatModel chat) {
    final isUploader = chat.uploaderUid == myUid;
    if (chat.statusEventType == 'rented') {
      return isUploader
          ? 'You marked this post as Rented'
          : '$otherName marked this post as Rented';
    } else if (chat.statusEventType == 'available') {
      return isUploader
          ? 'You marked this post as Available'
          : '$otherName marked this post as Available';
    }
    return '';
  }

  @override
  void dispose() {
    textController.dispose();
    super.dispose();
  }
}
