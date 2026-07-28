import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';

class ProfileScreenController extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();

  bool loading = true;
  String name = '';
  String email = '';
  String phone = '';

  ProfileScreenController() {
    _load();
  }

  Future<void> _load() async {
    final user = _authService.currentUser!;
    email = user.email ?? '';

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    final data = doc.data();

    name = data?['name'] ?? user.displayName ?? 'User';
    phone = data?['phone'] ?? '';
    loading = false;
    notifyListeners();
  }

  Stream<int> get unreadNotificationsCountStream => _firestoreService
      .unreadNotificationsCountStream(_authService.currentUser!.uid);

  Future<void> logout() async {
    await _authService.signOut();
  }
}
