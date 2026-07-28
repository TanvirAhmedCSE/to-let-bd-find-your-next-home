import 'package:flutter/material.dart';
import '../../models/post_model.dart';
import '../../models/user_location_model.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';

class HomeController extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();

  List<PostModel> _posts = [];
  List<PostModel> get posts => _posts;

  List<PostModel> _bestForYou = [];
  List<PostModel> get bestForYou => _bestForYou;
  List<PostModel> get bestForYouPreview => _bestForYou.take(10).toList();

  UserLocationModel? userLocation;

  bool loading = true;

  String? _selectedType;
  String? get selectedType => _selectedType;

  // Whether the floating bottom nav bar (in MainScreen) should be shown.
  bool navBarVisible = true;

  void setNavBarVisible(bool visible) {
    if (navBarVisible == visible) return;
    navBarVisible = visible;
    notifyListeners();
  }

  HomeController() {
    load();
  }

  String get _uid => _authService.currentUser!.uid;

  Future<void> load() async {
    loading = true;
    notifyListeners();
    try {
      _posts = await _firestoreService.fetchRecentPosts();
      await _loadBestForYou();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  // Re-fetches only the saved location + "Best for You" list. Used after
  // returning from SetLocationScreen, so we don't re-fetch the whole
  // Recent Posts feed just because the location changed.
  Future<void> refreshLocation() async {
    await _loadBestForYou();
    notifyListeners();
  }

  Future<void> _loadBestForYou() async {
    userLocation = await _firestoreService.getUserLocation(_uid);
    if (userLocation != null) {
      _bestForYou = await _firestoreService.fetchBestForYou(
        location: userLocation!,
        excludeUid: _uid, // NEW
      );
    } else {
      _bestForYou = [];
    }
  }

  // Pull-to-refresh entry point: re-fetches everything from Firestore
  Future<void> refresh() => load();

  void selectType(String? type) {
    _selectedType = (_selectedType == type) ? null : type;
    notifyListeners();
  }

  void clearType() {
    _selectedType = null;
    notifyListeners();
  }

  List<PostModel> get filteredPosts {
    if (_selectedType == null) return _posts;
    return _posts.where((p) => p.propertyType == _selectedType).toList();
  }

  Stream<int> totalUnreadCountStream(String uid) =>
      _firestoreService.totalUnreadCountStream(uid);

  Stream<int> unreadNotificationsCountStream(String uid) =>
      _firestoreService.unreadNotificationsCountStream(uid);
}
