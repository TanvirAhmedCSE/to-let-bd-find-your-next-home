import 'package:flutter/material.dart';
import '../../models/post_model.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';

class MyPostsScreenController extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();

  String get myUid => _authService.currentUser!.uid;

  Stream<List<PostModel>> get myPostsStream =>
      _firestoreService.myPostsStream(myUid);
}
