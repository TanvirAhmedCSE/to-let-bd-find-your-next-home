import 'package:flutter/material.dart';
import '../../models/post_model.dart';
import '../../services/auth_service.dart';
import '../../services/cloudinary_service.dart';
import '../../services/firestore_service.dart';
import '../../utils/constants.dart';

class PostDetailScreenController extends ChangeNotifier {
  final String postId;

  final FirestoreService firestoreService = FirestoreService();
  final CloudinaryService _cloudinaryService = CloudinaryService();
  final AuthService _authService = AuthService();

  PostModel? post;
  bool loading = true;
  bool interested = false;
  bool busy = false;

  String get myUid => _authService.currentUser!.uid;
  bool get isOwner => post != null && post!.uploaderUid == myUid;

  PostDetailScreenController(this.postId) {
    load();
  }

  Future<void> load() async {
    loading = true;
    notifyListeners();

    final loadedPost = await firestoreService.getPost(postId);
    final isInterested = loadedPost.uploaderUid == myUid
        ? false
        : await firestoreService.isInterested(postId, myUid);

    post = loadedPost;
    interested = isInterested;
    loading = false;
    notifyListeners();
  }

  Future<void> toggleInterest() async {
    if (post == null) return;
    busy = true;
    notifyListeners();
    final user = _authService.currentUser!;
    try {
      if (interested) {
        await firestoreService.removeInterest(post: post!, seekerUid: myUid);
      } else {
        await firestoreService.addInterest(
          post: post!,
          seekerUid: myUid,
          seekerName: user.displayName ?? user.email ?? 'Seeker',
        );
      }
      await load();
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  // Opens/creates a chat between the current user (seeker) and the
  // post owner. Returns the chatId; View handles navigation.
  Future<String> openChat() async {
    final user = _authService.currentUser!;
    return firestoreService.getOrCreateChat(
      postId: post!.id,
      postTitle: post!.title,
      postImageUrl: post!.images.isNotEmpty ? post!.images.first.url : '',
      uploaderUid: post!.uploaderUid,
      uploaderName: post!.uploaderName,
      seekerUid: myUid,
      seekerName: user.displayName ?? user.email ?? 'Seeker',
    );
  }

  // Used from the "Interested People" dialog when the owner starts a
  // chat with one of the seekers.
  Future<String> createChatWithSeeker({
    required String seekerUid,
    required String seekerName,
  }) async {
    return firestoreService.getOrCreateChat(
      postId: post!.id,
      postTitle: post!.title,
      postImageUrl: post!.images.isNotEmpty ? post!.images.first.url : '',
      uploaderUid: myUid,
      uploaderName: post!.uploaderName,
      seekerUid: seekerUid,
      seekerName: seekerName,
    );
  }

  // Returns true on success.
  Future<bool> deletePost() async {
    if (post == null) return false;
    busy = true;
    notifyListeners();
    try {
      final publicIds = post!.images.map((e) => e.publicId).toList();
      await firestoreService.deletePost(post!);
      await _cloudinaryService.deleteImages(publicIds);
      return true;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<void> toggleRented() async {
    if (post == null) return;
    busy = true;
    notifyListeners();
    try {
      if (post!.status == kStatusActive) {
        await firestoreService.markPostRented(post!);
      } else {
        await firestoreService.markPostAvailable(post!);
      }
      await load();
    } finally {
      busy = false;
      notifyListeners();
    }
  }
}
