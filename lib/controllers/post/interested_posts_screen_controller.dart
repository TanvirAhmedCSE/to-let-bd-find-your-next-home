import 'package:flutter/material.dart';
import '../../models/post_model.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';

class InterestedPostsScreenController extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();

  List<PostModel>? posts;

  InterestedPostsScreenController() {
    load();
  }

  Future<void> load() async {
    final uid = _authService.currentUser!.uid;
    final loaded = await _firestoreService.interestedPostsFor(uid);
    posts = loaded;
    notifyListeners();
  }
}
